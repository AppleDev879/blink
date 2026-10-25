import SwiftUI

@main
struct BlinkApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        // Menu bar UI is owned by AppModel's NSStatusItem so we can flash the glyph.
        Settings {
            SettingsView()
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Ensure we stay accessory even if Info.plist is overridden in debug.
        NSApp.setActivationPolicy(.accessory)
        AppModel.shared.start()
        AnalyticsClient.shared.track(.appLaunch)
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        false
    }
}
