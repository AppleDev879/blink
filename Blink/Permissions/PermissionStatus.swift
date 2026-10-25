import AppKit
import ApplicationServices
import Foundation

enum PermissionKind: String, CaseIterable {
    case screenRecording
    case accessibility

    var title: String {
        switch self {
        case .screenRecording: return "Screen Recording"
        case .accessibility: return "Accessibility"
        }
    }

    var actionCopy: String {
        switch self {
        case .screenRecording:
            return "Blink needs Screen Recording to capture what you frame."
        case .accessibility:
            return "Blink needs Accessibility for the experimental hover OCR click."
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

    static func accessibility() -> PermissionStatus {
        let trusted = AXIsProcessTrusted()
        return trusted ? .granted : .denied
    }

    static func requestAccessibility() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }

    static func openSystemSettings(for kind: PermissionKind) {
        let urlString: String
        switch kind {
        case .screenRecording:
            urlString = "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture"
        case .accessibility:
            urlString = "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
        }
        if let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        }
    }
}
