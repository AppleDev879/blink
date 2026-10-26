import AppKit
import Foundation

enum ClipboardFeedback {
    static func copy(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }

    private static var flashGeneration = 0
    private static var restingImage: NSImage?
    private static var restingTitle: String?
    private static var isFlashing = false

    /// Brief menu-bar title flash — no haptic, optional system sound.
    @MainActor
    static func flashSuccess(statusItem: NSStatusItem?, playSound: Bool = true) {
        flash(statusItem: statusItem, message: "✓", duration: 0.7) {
            if playSound {
                NSSound(named: "Tink")?.play()
            }
        }
    }

    @MainActor
    static func flashFailure(statusItem: NSStatusItem?, message: String = "!") {
        flash(statusItem: statusItem, message: message, duration: 0.9)
    }

    @MainActor
    private static func flash(
        statusItem: NSStatusItem?,
        message: String,
        duration: TimeInterval,
        beforeSchedule: (() -> Void)? = nil
    ) {
        guard let button = statusItem?.button else { return }

        // Latch the pre-flash glyph once so overlapping flashes restore correctly.
        if !isFlashing {
            restingImage = button.image
            restingTitle = button.title
            isFlashing = true
        }

        flashGeneration += 1
        let generation = flashGeneration

        button.title = message
        button.image = nil
        beforeSchedule?()

        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            guard generation == flashGeneration else { return }
            button.title = restingTitle ?? ""
            button.image = restingImage
            restingImage = nil
            restingTitle = nil
            isFlashing = false
        }
    }
}
