import Foundation

/// UserDefaults-backed settings for prompt-on-modifier copy.
@MainActor
final class PromptTransformSettings: ObservableObject {
    static let shared = PromptTransformSettings()

    private let defaults: UserDefaults

    private enum Keys {
        static let enabled = "blink.promptTransform.enabled"
        static let provider = "blink.promptTransform.provider"
        static let template = "blink.promptTransform.template"
        static let endpoint = "blink.promptTransform.endpoint"
        static let model = "blink.promptTransform.model"
        static let timeout = "blink.promptTransform.timeout"
        static let modifier = "blink.promptTransform.modifier"
        static let byokEndpoint = "blink.promptTransform.byokEndpoint"
        static let byokModel = "blink.promptTransform.byokModel"
        static let localEndpoint = "blink.promptTransform.localEndpoint"
        static let localModel = "blink.promptTransform.localModel"
    }

    @Published var provider: LLMProvider {
        didSet {
            defaults.set(provider.rawValue, forKey: Keys.provider)
            // Keep legacy flag in sync for any external readers.
            defaults.set(provider.transformsEnabled, forKey: Keys.enabled)
            applyEndpointDefaultsForProviderChange()
        }
    }

    /// Legacy toggle mirror — prefer `provider`.
    var isEnabled: Bool {
        get { provider.transformsEnabled }
        set { provider = newValue ? (provider == .off ? .byok : provider) : .off }
    }

    @Published var template: String {
        didSet { defaults.set(template, forKey: Keys.template) }
    }

    @Published var endpoint: String {
        didSet {
            defaults.set(endpoint, forKey: Keys.endpoint)
            persistActiveEndpointSlot()
        }
    }

    @Published var model: String {
        didSet {
            defaults.set(model, forKey: Keys.model)
            persistActiveModelSlot()
        }
    }

    @Published var timeoutSeconds: Double {
        didSet { defaults.set(timeoutSeconds, forKey: Keys.timeout) }
    }

    /// Stored as a parseable name ("control", "option", …). Default: control.
    @Published var modifierName: String {
        didSet { defaults.set(modifierName, forKey: Keys.modifier) }
    }

    /// Last Ollama probe from Settings (nil = not probed yet).
    @Published var localReachable: Bool?

    /// Model names from the last successful Ollama probe.
    @Published var localModels: [String] = []

    var requiredModifier: ModifierFlagParser.NamedModifier {
        ModifierFlagParser.parse(modifierName) ?? .control
    }

    /// Quiet menu hint when transform is armed but not ready.
    var needsSetupHint: Bool {
        switch provider {
        case .off:
            return false
        case .byok:
            return !KeychainStore.hasAPIKey
        case .local:
            return localReachable == false
        }
    }

    /// Backward-compatible name used by AppModel.
    var needsAPIKeyHint: Bool { needsSetupHint }

    var setupHintTitle: String {
        switch provider {
        case .off:
            return ""
        case .byok:
            return "Add a key to transform on \(requiredModifier.displaySymbol)"
        case .local:
            return "Start Ollama to transform on \(requiredModifier.displaySymbol)"
        }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        let migratedProvider: LLMProvider
        if let parsed = LLMProvider.parse(defaults.string(forKey: Keys.provider)) {
            migratedProvider = parsed
        } else if defaults.object(forKey: Keys.enabled) != nil {
            migratedProvider = defaults.bool(forKey: Keys.enabled) ? .byok : .off
        } else {
            migratedProvider = .off
        }
        self.provider = migratedProvider

        self.template = defaults.string(forKey: Keys.template) ?? PromptTemplate.defaultTemplate

        let byokEndpoint = defaults.string(forKey: Keys.byokEndpoint)
            ?? defaults.string(forKey: Keys.endpoint)
            ?? "https://api.openai.com/v1"
        let byokModel = defaults.string(forKey: Keys.byokModel)
            ?? defaults.string(forKey: Keys.model)
            ?? "gpt-4o-mini"
        let localEndpoint = defaults.string(forKey: Keys.localEndpoint)
            ?? OllamaClient.defaultOpenAIEndpoint
        let localModel = defaults.string(forKey: Keys.localModel)
            ?? OllamaClient.defaultModel

        // Seed slot keys if missing so round-trips work.
        if defaults.string(forKey: Keys.byokEndpoint) == nil {
            defaults.set(byokEndpoint, forKey: Keys.byokEndpoint)
        }
        if defaults.string(forKey: Keys.byokModel) == nil {
            defaults.set(byokModel, forKey: Keys.byokModel)
        }
        if defaults.string(forKey: Keys.localEndpoint) == nil {
            defaults.set(localEndpoint, forKey: Keys.localEndpoint)
        }
        if defaults.string(forKey: Keys.localModel) == nil {
            defaults.set(localModel, forKey: Keys.localModel)
        }

        switch migratedProvider {
        case .local:
            self.endpoint = defaults.string(forKey: Keys.endpoint)
                ?? localEndpoint
            self.model = defaults.string(forKey: Keys.model) ?? localModel
        case .byok, .off:
            self.endpoint = defaults.string(forKey: Keys.endpoint) ?? byokEndpoint
            self.model = defaults.string(forKey: Keys.model) ?? byokModel
        }

        let storedTimeout = defaults.double(forKey: Keys.timeout)
        self.timeoutSeconds = storedTimeout > 0 ? storedTimeout : 15
        self.modifierName = defaults.string(forKey: Keys.modifier) ?? "control"

        defaults.set(migratedProvider.rawValue, forKey: Keys.provider)
        defaults.set(migratedProvider.transformsEnabled, forKey: Keys.enabled)
    }

    /// One-click local setup when Ollama is reachable.
    func useLocalModel(preferredModel: String? = nil) {
        provider = .local
        endpoint = OllamaClient.defaultOpenAIEndpoint
        if let preferredModel, !preferredModel.isEmpty {
            model = preferredModel
        } else if let first = localModels.first {
            model = first
        } else if model.isEmpty || !OllamaClient.looksLikeLocalEndpoint(endpoint) {
            model = OllamaClient.defaultModel
        }
        localReachable = true
    }

    private func applyEndpointDefaultsForProviderChange() {
        switch provider {
        case .off:
            break
        case .byok:
            if OllamaClient.looksLikeLocalEndpoint(endpoint) {
                endpoint = defaults.string(forKey: Keys.byokEndpoint) ?? "https://api.openai.com/v1"
                model = defaults.string(forKey: Keys.byokModel) ?? "gpt-4o-mini"
            }
        case .local:
            if !OllamaClient.looksLikeLocalEndpoint(endpoint) {
                defaults.set(endpoint, forKey: Keys.byokEndpoint)
                defaults.set(model, forKey: Keys.byokModel)
                endpoint = defaults.string(forKey: Keys.localEndpoint) ?? OllamaClient.defaultOpenAIEndpoint
                model = defaults.string(forKey: Keys.localModel) ?? OllamaClient.defaultModel
            }
        }
    }

    private func persistActiveEndpointSlot() {
        switch provider {
        case .byok, .off:
            defaults.set(endpoint, forKey: Keys.byokEndpoint)
        case .local:
            defaults.set(endpoint, forKey: Keys.localEndpoint)
        }
    }

    private func persistActiveModelSlot() {
        switch provider {
        case .byok, .off:
            defaults.set(model, forKey: Keys.byokModel)
        case .local:
            defaults.set(model, forKey: Keys.localModel)
        }
    }
}
