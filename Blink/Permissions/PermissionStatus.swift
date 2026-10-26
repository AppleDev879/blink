import AppKit
import Foundation

enum PermissionKind: String, CaseIterable {
    case screenRecording

    var title: String {
        switch self {
        case .screenRecording: return "Screen Recording"
        }
    }

    var actionCopy: String {
        switch self {
        case .screenRecording:
            return "Blink needs Screen Recording to capture what you frame."
        }
    }
}

enum PermissionStatus {
    case granted
    /// Preflight failed — includes first-run not-determined (macOS does not expose that separately here).
    case denied

    var isUsable: Bool { self == .granted }
}

enum PermissionGate {
    /// `CGPreflightScreenCaptureAccess` — false covers both denied and not-yet-prompted.
    static func screenRecording() -> PermissionStatus {
        CGPreflightScreenCaptureAccess() ? .granted : .denied
    }

    static func requestScreenRecording() {
        _ = CGRequestScreenCaptureAccess()
    }

    static func openSystemSettings(for kind: PermissionKind) {
        let urlString: String
        switch kind {
        case .screenRecording:
            urlString = "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture"
        }
        if let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        }
    }
}
