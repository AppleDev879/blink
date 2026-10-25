import AppKit
import Foundation

/// Reads modifier state at the copy moment (capture release / experimental click).
enum ModifierHoldDetector {
    /// Device-independent modifier flags currently held (ignores caps lock).
    static func currentFlags() -> NSEvent.ModifierFlags {
        NSEvent.modifierFlags.intersection([.control, .option, .shift, .command])
    }

    static func isHeld(_ modifier: ModifierFlagParser.NamedModifier) -> Bool {
        currentFlags().contains(modifier.eventFlags)
    }

    static func isHeld(named raw: String) -> Bool {
        guard let named = ModifierFlagParser.parse(raw) else { return false }
        return isHeld(named)
    }
}
