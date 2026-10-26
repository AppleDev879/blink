import AppKit
import Foundation

/// Describes a global hotkey chord in a testable, Carbon-agnostic form.
struct HotkeyChord: Equatable, Sendable {
    var keyCode: UInt32
    var modifiers: Modifiers

    struct Modifiers: OptionSet, Equatable, Sendable {
        let rawValue: UInt32
        init(rawValue: UInt32) { self.rawValue = rawValue }

        static let command = Modifiers(rawValue: 1 << 0)
        static let shift = Modifiers(rawValue: 1 << 1)
        static let option = Modifiers(rawValue: 1 << 2)
        static let control = Modifiers(rawValue: 1 << 3)
    }

    /// Default capture chord: ⌘⇧2
    static let captureDefault = HotkeyChord(keyCode: 19, modifiers: [.command, .shift]) // kVK_ANSI_2 = 19

    /// Stable UserDefaults token, e.g. `command+shift+2`.
    var storageString: String {
        var parts: [String] = []
        if modifiers.contains(.control) { parts.append("control") }
        if modifiers.contains(.option) { parts.append("option") }
        if modifiers.contains(.shift) { parts.append("shift") }
        if modifiers.contains(.command) { parts.append("command") }
        parts.append(Self.keyLabel(for: keyCode).lowercased())
        return parts.joined(separator: "+")
    }

    /// Human-readable label for menus / docs.
    var displayLabel: String {
        var parts: [String] = []
        if modifiers.contains(.control) { parts.append("⌃") }
        if modifiers.contains(.option) { parts.append("⌥") }
        if modifiers.contains(.shift) { parts.append("⇧") }
        if modifiers.contains(.command) { parts.append("⌘") }
        parts.append(Self.keyLabel(for: keyCode))
        return parts.joined()
    }

    /// Character for `NSMenuItem.keyEquivalent`, if mappable.
    var menuKeyEquivalent: String? {
        let label = Self.keyLabel(for: keyCode)
        guard label != "?" else { return nil }
        return label.lowercased()
    }

    var menuModifierMask: NSEvent.ModifierFlags {
        var flags: NSEvent.ModifierFlags = []
        if modifiers.contains(.command) { flags.insert(.command) }
        if modifiers.contains(.shift) { flags.insert(.shift) }
        if modifiers.contains(.option) { flags.insert(.option) }
        if modifiers.contains(.control) { flags.insert(.control) }
        return flags
    }

    /// Parse strings like "cmd+shift+2", "⌘⇧2", "command-shift-2".
    static func parse(_ raw: String) -> HotkeyChord? {
        let lowered = raw
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "+")

        var mods = Modifiers()
        var keyToken: String?

        // Unicode symbols without separators
        if lowered.contains("⌘") || lowered.contains("cmd") || lowered.contains("command") {
            mods.insert(.command)
        }
        if lowered.contains("⇧") || lowered.contains("shift") {
            mods.insert(.shift)
        }
        if lowered.contains("⌥") || lowered.contains("option") || lowered.contains("alt") {
            mods.insert(.option)
        }
        if lowered.contains("⌃") || lowered.contains("ctrl") || lowered.contains("control") {
            mods.insert(.control)
        }

        let tokens = lowered
            .replacingOccurrences(of: "⌘", with: "+")
            .replacingOccurrences(of: "⇧", with: "+")
            .replacingOccurrences(of: "⌥", with: "+")
            .replacingOccurrences(of: "⌃", with: "+")
            .split(separator: "+", omittingEmptySubsequences: true)
            .map(String.init)

        let ignored: Set<String> = [
            "cmd", "command", "shift", "option", "alt", "ctrl", "control"
        ]
        for token in tokens where !ignored.contains(token) {
            keyToken = token
        }

        // Fallback: last character if it's a digit/letter
        if keyToken == nil {
            if let last = lowered.last, last.isLetter || last.isNumber {
                keyToken = String(last)
            }
        }

        guard let keyToken, let code = keyCode(for: keyToken) else { return nil }
        guard !mods.isEmpty else { return nil }
        return HotkeyChord(keyCode: code, modifiers: mods)
    }

    static func keyCode(for token: String) -> UInt32? {
        switch token {
        case "0": return 29
        case "1": return 18
        case "2": return 19
        case "3": return 20
        case "4": return 21
        case "5": return 23
        case "6": return 22
        case "7": return 26
        case "8": return 28
        case "9": return 25
        case "a": return 0
        case "b": return 11
        case "c": return 8
        case "d": return 2
        case "e": return 14
        case "f": return 3
        case "g": return 5
        case "h": return 4
        case "i": return 34
        case "j": return 38
        case "k": return 40
        case "l": return 37
        case "m": return 46
        case "n": return 45
        case "o": return 31
        case "p": return 35
        case "q": return 12
        case "r": return 15
        case "s": return 1
        case "t": return 17
        case "u": return 32
        case "v": return 9
        case "w": return 13
        case "x": return 7
        case "y": return 16
        case "z": return 6
        default: return nil
        }
    }

    static func keyLabel(for keyCode: UInt32) -> String {
        switch keyCode {
        case 0: return "A"
        case 1: return "S"
        case 2: return "D"
        case 3: return "F"
        case 4: return "H"
        case 5: return "G"
        case 6: return "Z"
        case 7: return "X"
        case 8: return "C"
        case 9: return "V"
        case 11: return "B"
        case 12: return "Q"
        case 13: return "W"
        case 14: return "E"
        case 15: return "R"
        case 16: return "Y"
        case 17: return "T"
        case 18: return "1"
        case 19: return "2"
        case 20: return "3"
        case 21: return "4"
        case 22: return "6"
        case 23: return "5"
        case 25: return "9"
        case 26: return "7"
        case 28: return "8"
        case 29: return "0"
        case 31: return "O"
        case 32: return "U"
        case 34: return "I"
        case 35: return "P"
        case 37: return "L"
        case 38: return "J"
        case 40: return "K"
        case 45: return "N"
        case 46: return "M"
        default: return "?"
        }
    }
}

extension HotkeyChord {
    /// Build from a local key-down event while recording in Settings.
    init?(nsEvent event: NSEvent) {
        guard event.type == .keyDown else { return nil }
        // Ignore pure modifier taps and Esc (handled by recorder).
        if event.keyCode == 53 { return nil }

        var mods = Modifiers()
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        if flags.contains(.command) { mods.insert(.command) }
        if flags.contains(.shift) { mods.insert(.shift) }
        if flags.contains(.option) { mods.insert(.option) }
        if flags.contains(.control) { mods.insert(.control) }
        guard !mods.isEmpty else { return nil }

        let code = UInt32(event.keyCode)
        guard Self.keyLabel(for: code) != "?" else { return nil }
        self.keyCode = code
        self.modifiers = mods
    }
}
