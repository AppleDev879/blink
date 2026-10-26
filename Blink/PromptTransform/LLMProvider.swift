import Foundation

/// How Blink runs optional ⌃-held prompt transforms.
enum LLMProvider: String, CaseIterable, Identifiable, Sendable {
    case off
    case byok
    case local

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .off: return "Off"
        case .byok: return "BYOK"
        case .local: return "Local (Ollama)"
        }
    }

    /// Transform path is armed (modifier may still be required at copy time).
    var transformsEnabled: Bool { self != .off }

    static func parse(_ raw: String?) -> LLMProvider? {
        guard let raw else { return nil }
        return LLMProvider(rawValue: raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased())
    }
}
