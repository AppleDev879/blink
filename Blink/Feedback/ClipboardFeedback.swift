import AppKit
import Foundation

enum ClipboardFeedback {
    static func copy(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }

    /// Brief menu-bar title flash — no haptic, optional system sound.
    @MainActor
    static func flashSuccess(statusItem: NSStatusItem?, playSound: Bool = true) {
        guard let button = statusItem?.button else { return }
        let original = button.image
        let originalTitle = button.title

        button.title = "✓"
        button.image = nil
        if playSound {
            NSSound(named: "Tink")?.play()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            button.title = originalTitle
            button.image = original
        }
    }

    @MainActor
    static func flashFailure(statusItem: NSStatusItem?, message: String = "!") {
        guard let button = statusItem?.button else { return }
        let original = button.image
        let originalTitle = button.title
        button.title = message
        button.image = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            button.title = originalTitle
            button.image = original
        }
    }
}
