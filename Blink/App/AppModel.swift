import AppKit
import Combine
import Foundation
import SwiftUI

@MainActor
final class AppModel: ObservableObject {
    static let shared = AppModel()

    @Published var showOnboarding: Bool
    @Published var showPermissionsFollowUp = false
    @Published var permissionBanner: String?

    let loginItem = LoginItemController()
    let captureSession = CaptureSession()
    let hotkey = GlobalHotkeyMonitor()
    let capturePreferences = CapturePreferences.shared

    private var statusItem: NSStatusItem?
    private var cancellables = Set<AnyCancellable>()

    private let onboardingKey = "blink.didCompleteOnboarding"

    private init() {
        showOnboarding = !UserDefaults.standard.bool(forKey: onboardingKey)
    }

    func start() {
        setupStatusItem()
        captureSession.statusItem = statusItem

        registerCaptureHotkey()

        capturePreferences.$captureChord
            .dropFirst()
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.registerCaptureHotkey()
            }
            .store(in: &cancellables)

        PromptTransformSettings.shared.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.rebuildMenu()
            }
            .store(in: &cancellables)

        refreshPermissionBanner()

        if showOnboarding {
            OnboardingWindowController.shared.present(model: self)
        }
    }

    func registerCaptureHotkey() {
        let chord = capturePreferences.captureChord
        let ok = hotkey.register(chord) { [weak self] in
            self?.captureSession.beginCapture()
        }
        capturePreferences.registrationFailed = !ok
        if let button = statusItem?.button {
            button.toolTip = "Blink — \(chord.displayLabel)"
        }
        rebuildMenu()
    }

    func completeOnboarding() {
        showOnboarding = false
        UserDefaults.standard.set(true, forKey: onboardingKey)
        OnboardingWindowController.shared.presentPermissions(model: self)
    }

    func completePermissions() {
        OnboardingWindowController.shared.close()
        refreshPermissionBanner()
    }

    func refreshPermissionBanner() {
        if !PermissionGate.screenRecording().isUsable {
            permissionBanner = "Screen Recording is off — capture won’t work."
        } else {
            permissionBanner = nil
        }
        rebuildMenu()
    }

    func openSettings() {
        NSApp.activate(ignoringOtherApps: true)
        if #available(macOS 14.0, *) {
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        } else {
            NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
        }
    }

    private func setupStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = item.button {
            if let image = NSImage(named: "MenuBarIcon") {
                image.isTemplate = true
                button.image = image
            } else {
                button.title = "⌥"
            }
            button.toolTip = "Blink — \(capturePreferences.captureChord.displayLabel)"
        }
        statusItem = item
        rebuildMenu()
    }

    func rebuildMenu() {
        let menu = NSMenu()
        let chord = capturePreferences.captureChord

        if let banner = permissionBanner {
            let bannerItem = NSMenuItem(title: banner, action: #selector(openScreenRecordingSettings), keyEquivalent: "")
            bannerItem.target = self
            menu.addItem(bannerItem)
            menu.addItem(.separator())
        }

        if capturePreferences.registrationFailed {
            let hint = NSMenuItem(
                title: "Capture shortcut unavailable — change in Settings",
                action: #selector(openSettingsAction),
                keyEquivalent: ""
            )
            hint.target = self
            menu.addItem(hint)
            menu.addItem(.separator())
        }

        let capture = NSMenuItem(
            title: "Capture  \(chord.displayLabel)",
            action: #selector(triggerCapture),
            keyEquivalent: chord.menuKeyEquivalent ?? ""
        )
        if chord.menuKeyEquivalent != nil {
            capture.keyEquivalentModifierMask = chord.menuModifierMask
        }
        capture.target = self
        menu.addItem(capture)

        menu.addItem(.separator())

        let login = NSMenuItem(
            title: "Open at Login",
            action: #selector(toggleLogin),
            keyEquivalent: ""
        )
        login.target = self
        login.state = loginItem.isEnabled ? .on : .off
        menu.addItem(login)

        let settings = NSMenuItem(
            title: "Settings…",
            action: #selector(openSettingsAction),
            keyEquivalent: ","
        )
        settings.target = self
        menu.addItem(settings)

        let promptSettings = PromptTransformSettings.shared
        if promptSettings.needsSetupHint {
            let hint = NSMenuItem(
                title: promptSettings.setupHintTitle,
                action: #selector(openSettingsAction),
                keyEquivalent: ""
            )
            hint.target = self
            menu.addItem(hint)
        }

        menu.addItem(.separator())

        let updates = NSMenuItem(
            title: "Check for Updates…",
            action: #selector(UpdateController.checkForUpdates(_:)),
            keyEquivalent: ""
        )
        updates.target = UpdateController.shared
        menu.addItem(updates)

        menu.addItem(.separator())

        let quit = NSMenuItem(title: "Quit Blink", action: #selector(quit), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)

        statusItem?.menu = menu
    }

    @objc private func triggerCapture() {
        captureSession.beginCapture()
    }

    @objc private func toggleLogin() {
        loginItem.toggle()
        AnalyticsClient.shared.track(
            .openAtLoginToggled,
            parameters: ["enabled": loginItem.isEnabled ? "true" : "false"]
        )
        rebuildMenu()
    }

    @objc private func openSettingsAction() {
        openSettings()
    }

    @objc private func openScreenRecordingSettings() {
        PermissionGate.openSystemSettings(for: .screenRecording)
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}

@MainActor
final class OnboardingWindowController {
    static let shared = OnboardingWindowController()
    private var window: NSWindow?

    func present(model: AppModel) {
        let view = OnboardingView {
            model.completeOnboarding()
        }
        show(root: view)
    }

    func presentPermissions(model: AppModel) {
        let view = PermissionsFollowUpView {
            model.completePermissions()
        }
        show(root: view)
    }

    func close() {
        window?.close()
        window = nil
    }

    private func show<Content: View>(root: Content) {
        let hosting = NSHostingController(rootView: root)
        let window = NSWindow(contentViewController: hosting)
        window.title = "Blink"
        window.styleMask = [.titled, .closable, .fullSizeContentView]
        window.titlebarAppearsTransparent = true
        window.backgroundColor = Brand.inkNS
        window.isReleasedWhenClosed = false
        window.center()
        window.level = .floating
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        self.window = window
    }
}
