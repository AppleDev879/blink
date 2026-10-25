import Foundation

/// UserDefaults-backed settings for prompt-on-modifier copy.
@MainActor
final class PromptTransformSettings: ObservableObject {
    static let shared = PromptTransformSettings()

    private let defaults: UserDefaults

    private enum Keys {
        static let enabled = "blink.promptTransform.enabled"
        static let template = "blink.promptTransform.template"
        static let endpoint = "blink.promptTransform.endpoint"
        static let model = "blink.promptTransform.model"
        static let timeout = "blink.promptTransform.timeout"
        static let modifier = "blink.promptTransform.modifier"
    }

    @Published var isEnabled: Bool {
        didSet { defaults.set(isEnabled, forKey: Keys.enabled) }
    }

    @Published var template: String {
        didSet { defaults.set(template, forKey: Keys.template) }
    }

    @Published var endpoint: String {
        didSet { defaults.set(endpoint, forKey: Keys.endpoint) }
    }

    @Published var model: String {
        didSet { defaults.set(model, forKey: Keys.model) }
    }

    @Published var timeoutSeconds: Double {
        didSet { defaults.set(timeoutSeconds, forKey: Keys.timeout) }
    }

    /// Stored as a parseable name ("control", "option", …). Default: control.
    @Published var modifierName: String {
        didSet { defaults.set(modifierName, forKey: Keys.modifier) }
    }

    var requiredModifier: ModifierFlagParser.NamedModifier {
        ModifierFlagParser.parse(modifierName) ?? .control
    }

    var needsAPIKeyHint: Bool {
        isEnabled && !KeychainStore.hasAPIKey
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.isEnabled = defaults.bool(forKey: Keys.enabled)
        self.template = defaults.string(forKey: Keys.template) ?? PromptTemplate.defaultTemplate
        self.endpoint = defaults.string(forKey: Keys.endpoint) ?? "https://api.openai.com/v1"
        self.model = defaults.string(forKey: Keys.model) ?? "gpt-4o-mini"
        let storedTimeout = defaults.double(forKey: Keys.timeout)
        self.timeoutSeconds = storedTimeout > 0 ? storedTimeout : 15
        self.modifierName = defaults.string(forKey: Keys.modifier) ?? "control"
    }
}
