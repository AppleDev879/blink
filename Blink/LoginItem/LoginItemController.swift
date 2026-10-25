import Foundation
import ServiceManagement

/// Open at Login via `SMAppService.mainApp` (macOS 13+).
@MainActor
final class LoginItemController: ObservableObject {
    @Published private(set) var isEnabled: Bool = false

    init() {
        refresh()
    }

    func refresh() {
        isEnabled = SMAppService.mainApp.status == .enabled
    }

    func setEnabled(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            refresh()
        } catch {
            refresh()
        }
    }

    func toggle() {
        setEnabled(!isEnabled)
    }
}
