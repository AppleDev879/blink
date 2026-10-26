import Foundation

/// UserDefaults-backed capture preferences (hotkey + toast).
@MainActor
final class CapturePreferences: ObservableObject {
    static let shared = CapturePreferences()

    private let defaults: UserDefaults

    private enum Keys {
        static let captureHotkey = "blink.capture.hotkey"
        static let toastEnabled = "blink.toast.enabled"
    }

    @Published var captureChord: HotkeyChord {
        didSet {
            defaults.set(captureChord.storageString, forKey: Keys.captureHotkey)
        }
    }

    /// When `false`, skip the bottom-of-screen copy toast (menu flash still runs).
    @Published var toastEnabled: Bool {
        didSet { defaults.set(toastEnabled, forKey: Keys.toastEnabled) }
    }

    /// Set after a hotkey re-register attempt fails (conflict / OS refusal). Quiet — Settings shows a hint.
    @Published var registrationFailed = false

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let raw = defaults.string(forKey: Keys.captureHotkey),
           let chord = HotkeyChord.parse(raw) {
            self.captureChord = chord
        } else {
            self.captureChord = .captureDefault
        }
        if defaults.object(forKey: Keys.toastEnabled) == nil {
            self.toastEnabled = true
        } else {
            self.toastEnabled = defaults.bool(forKey: Keys.toastEnabled)
        }
    }

    func resetHotkeyToDefault() {
        captureChord = .captureDefault
    }
}
