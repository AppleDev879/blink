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
    case denied
    case notDetermined

    var isUsable: Bool { self == .granted }
}

enum PermissionGate {
    /// CGPreflightScreenCaptureAccess is the modern preflight; also try a tiny CGWindowList probe.
    static func screenRecording() -> PermissionStatus {
        if CGPreflightScreenCaptureAccess() {
            return .granted
        }
        // Preflight false can mean not-determined on first launch.
        return .denied
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
