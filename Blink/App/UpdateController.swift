import Foundation
import Sparkle

/// Owns Sparkle’s standard updater for the menu-bar app.
/// Background checks are enabled via Info.plist (`SUEnableAutomaticChecks`).
@MainActor
final class UpdateController: NSObject {
    static let shared = UpdateController()

    /// Starting the updater immediately schedules quiet background checks when enabled.
    let controller = SPUStandardUpdaterController(
        startingUpdater: true,
        updaterDelegate: nil,
        userDriverDelegate: nil
    )

    private override init() {
        super.init()
    }

    @objc func checkForUpdates(_ sender: Any?) {
        controller.checkForUpdates(sender)
    }
}
