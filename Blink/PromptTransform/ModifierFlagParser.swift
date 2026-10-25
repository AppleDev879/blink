import AppKit
import Foundation

/// Parses a human modifier name into `NSEvent.ModifierFlags` (pure where possible).
enum ModifierFlagParser {
    enum NamedModifier: String, CaseIterable, Sendable {
        case control
        case option
        case shift
        case command

        var displaySymbol: String {
            switch self {
            case .control: return "⌃"
            case .option: return "⌥"
            case .shift: return "⇧"
            case .command: return "⌘"
            }
        }

        var eventFlags: NSEvent.ModifierFlags {
            switch self {
            case .control: return .control
            case .option: return .option
            case .shift: return .shift
            case .command: return .command
            }
        }
    }

    /// Accepts "control", "ctrl", "⌃", "option", "alt", "⇧", "cmd", "command", etc.
    static func parse(_ raw: String) -> NamedModifier? {
        let token = raw
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: " ", with: "")

        switch token {
        case "control", "ctrl", "⌃", "ctl":
            return .control
        case "option", "alt", "⌥", "opt":
            return .option
        case "shift", "⇧":
            return .shift
        case "command", "cmd", "⌘", "meta":
            return .command
        default:
            return nil
        }
    }

    static func displayLabel(for raw: String) -> String {
        parse(raw)?.displaySymbol ?? "⌃"
    }
}
