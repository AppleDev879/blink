import SwiftUI

struct SettingsView: View {
    @ObservedObject private var analytics = AnalyticsClient.shared
    @ObservedObject private var prompt = PromptTransformSettings.shared
    @ObservedObject private var capture = CapturePreferences.shared
    @ObservedObject private var loginItem = AppModel.shared.loginItem
    @State private var apiKeyDraft = ""
    @State private var apiKeySaved = KeychainStore.hasAPIKey
    @State private var validateStatus: String?
    @State private var isValidating = false
    @State private var isProbingOllama = false

    private let modifierOptions: [(String, String)] = [
        ("control", "⌃ Control"),
        ("option", "⌥ Option"),
        ("shift", "⇧ Shift"),
        ("command", "⌘ Command")
    ]

    var body: some View {
        Form {
            Section {
                LabeledContent("Capture shortcut") {
                    HotkeyRecorderView(
                        chord: $capture.captureChord,
                        registrationFailed: capture.registrationFailed
                    )
                }

                Toggle(
                    "Open at Login",
                    isOn: Binding(
                        get: { loginItem.isEnabled },
                        set: { newValue in
                            loginItem.setEnabled(newValue)
                            AnalyticsClient.shared.track(
                                .openAtLoginToggled,
                                parameters: ["enabled": newValue ? "true" : "false"]
                            )
                            AppModel.shared.rebuildMenu()
                        }
                    )
                )

                Toggle("Show copy toast", isOn: $capture.toastEnabled)
                Text("Brief confirmation at the bottom of the display after a successful copy.")
                    .font(.system(size: 12))
                    .foregroundStyle(Brand.fog)
                    .fixedSize(horizontal: false, vertical: true)
            } header: {
                Text("Capture")
            }

            Section {
                Toggle(
                    "Share anonymous analytics",
                    isOn: Binding(
                        get: { analytics.isEnabled },
                        set: { analytics.setEnabled($0) }
                    )
                )
                Text(
                    "Opt-in. Anonymous event names only (launch, capture, OCR fail, login toggle, prompt transform). No screen content, no OCR text."
                )
                .font(.system(size: 12))
                .foregroundStyle(Brand.fog)
                .fixedSize(horizontal: false, vertical: true)

                if analytics.isEnabled && !analytics.isConfigured {
                    Text("Add your TelemetryDeck App ID in Config/Secrets.xcconfig to send signals.")
                        .font(.system(size: 12))
                        .foregroundStyle(Brand.fog)
                }
            } header: {
                Text("Analytics")
            }

            promptTransformSection
        }
        .formStyle(.grouped)
        .frame(minWidth: 440, idealWidth: 460, minHeight: 460, idealHeight: 560)
        .padding(.bottom, 8)
        .onAppear {
            apiKeySaved = KeychainStore.hasAPIKey
            loginItem.refresh()
            if prompt.provider == .local {
                Task { await probeOllama() }
            }
        }
        .onChange(of: prompt.provider) { _, newValue in
            validateStatus = nil
            AppModel.shared.rebuildMenu()
            if newValue == .local {
                Task { await probeOllama() }
            }
        }
    }

    @ViewBuilder
    private var promptTransformSection: some View {
        Section {
            Text("Uses your API key or a local model. Blink doesn’t bill for tokens.")
                .font(.system(size: 12))
                .foregroundStyle(Brand.fog)
                .fixedSize(horizontal: false, vertical: true)

            Picker("Provider", selection: $prompt.provider) {
                ForEach(LLMProvider.allCases) { option in
                    Text(option.displayName).tag(option)
                }
            }
            .pickerStyle(.segmented)

            switch prompt.provider {
            case .off:
                Text("⌃-held transform is off. Capture still copies raw OCR.")
                    .font(.system(size: 12))
                    .foregroundStyle(Brand.fog)

            case .byok:
                byokFields

            case .local:
                localFields
            }
        } header: {
            Text("Prompt transform")
        } footer: {
            Text(footerCopy)
                .font(.system(size: 11))
        }
    }

    @ViewBuilder
    private var byokFields: some View {
        Text("Hold \(prompt.requiredModifier.displaySymbol) at copy time to run OCR through your prompt.")
            .font(.system(size: 12))
            .foregroundStyle(Brand.fog)

        Picker("Modifier", selection: $prompt.modifierName) {
            ForEach(modifierOptions, id: \.0) { option in
                Text(option.1).tag(option.0)
            }
        }

        TextField("Prompt template", text: $prompt.template, axis: .vertical)
            .lineLimit(3...8)

        if !apiKeySaved {
            Text("Add a key to transform on \(prompt.requiredModifier.displaySymbol)")
                .font(.system(size: 12))
                .foregroundStyle(Brand.fog)
        }

        SecureField(
            apiKeySaved ? "API key (saved in Keychain)" : "API key",
            text: $apiKeyDraft
        )
        .onSubmit { saveAPIKey() }

        HStack {
            Button("Save API Key") { saveAPIKey() }
            if apiKeySaved {
                Button("Clear") {
                    KeychainStore.setAPIKey(nil)
                    apiKeyDraft = ""
                    apiKeySaved = false
                    AppModel.shared.rebuildMenu()
                }
            }
        }

        TextField("Endpoint", text: $prompt.endpoint)
        TextField("Model", text: $prompt.model)

        timeoutSlider

        HStack {
            Button(isValidating ? "Checking…" : "Validate") {
                Task { await validateBYOK() }
            }
            .disabled(isValidating || !apiKeySaved)

            if let validateStatus {
                Text(validateStatus)
                    .font(.system(size: 12))
                    .foregroundStyle(Brand.fog)
                    .lineLimit(2)
            }
        }
    }

    @ViewBuilder
    private var localFields: some View {
        Text("Hold \(prompt.requiredModifier.displaySymbol) at copy time. Blink talks to Ollama on your Mac — no API key.")
            .font(.system(size: 12))
            .foregroundStyle(Brand.fog)

        Picker("Modifier", selection: $prompt.modifierName) {
            ForEach(modifierOptions, id: \.0) { option in
                Text(option.1).tag(option.0)
            }
        }

        TextField("Prompt template", text: $prompt.template, axis: .vertical)
            .lineLimit(3...8)

        TextField("Base URL", text: $prompt.endpoint)
            .onSubmit {
                Task { await probeOllama() }
            }

        ollamaStatusRow

        if !prompt.localModels.isEmpty {
            Picker("Model", selection: $prompt.model) {
                ForEach(prompt.localModels, id: \.self) { name in
                    Text(name).tag(name)
                }
                if !prompt.localModels.contains(prompt.model) && !prompt.model.isEmpty {
                    Text(prompt.model).tag(prompt.model)
                }
            }
        } else {
            TextField("Model", text: $prompt.model)
        }

        timeoutSlider

        HStack {
            Button("Refresh models") {
                Task { await probeOllama() }
            }
            .disabled(isProbingOllama)

            if prompt.localReachable == true {
                Button("Use local model") {
                    prompt.useLocalModel(preferredModel: prompt.localModels.first)
                    AppModel.shared.rebuildMenu()
                }
            }
        }
    }

    private var ollamaStatusRow: some View {
        Group {
            if isProbingOllama {
                Text("Checking Ollama…")
                    .font(.system(size: 12))
                    .foregroundStyle(Brand.fog)
            } else if prompt.localReachable == true {
                Text(
                    prompt.localModels.isEmpty
                        ? "Ollama reachable — pull a model, then pick it below."
                        : "Ollama reachable · \(prompt.localModels.count) model\(prompt.localModels.count == 1 ? "" : "s")"
                )
                .font(.system(size: 12))
                .foregroundStyle(Brand.mintDim)
            } else if prompt.localReachable == false {
                Text("Ollama not reachable — raw OCR until it’s running. Default \(OllamaClient.defaultBaseURL).")
                    .font(.system(size: 12))
                    .foregroundStyle(Brand.fog)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var timeoutSlider: some View {
        HStack {
            Text("Timeout")
            Slider(value: $prompt.timeoutSeconds, in: 5...60, step: 1)
            Text("\(Int(prompt.timeoutSeconds))s")
                .monospacedDigit()
                .frame(width: 36, alignment: .trailing)
        }
    }

    private var footerCopy: String {
        switch prompt.provider {
        case .off:
            return "Core capture stays free. Turn on BYOK or Local when you want ⌃ transforms."
        case .byok:
            return "No key? Blink copies raw text and stays quiet. Never nags."
        case .local:
            return "Ollama down? Blink copies raw OCR and stays quiet — no error modal."
        }
    }

    private func saveAPIKey() {
        let trimmed = apiKeyDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            KeychainStore.setAPIKey(trimmed)
            apiKeyDraft = ""
            apiKeySaved = true
            AppModel.shared.rebuildMenu()
        }
    }

    @MainActor
    private func validateBYOK() async {
        guard apiKeySaved, let key = KeychainStore.apiKey(), !key.isEmpty else {
            validateStatus = "Add a key first."
            return
        }
        isValidating = true
        validateStatus = nil
        defer { isValidating = false }
        do {
            try await PromptTransformService().validate(
                endpoint: prompt.endpoint,
                model: prompt.model,
                apiKey: key,
                timeout: min(prompt.timeoutSeconds, 20)
            )
            validateStatus = "Looks good."
        } catch {
            validateStatus = error.localizedDescription
        }
    }

    @MainActor
    private func probeOllama() async {
        isProbingOllama = true
        defer { isProbingOllama = false }
        let result = await OllamaClient().probe(endpointOrBase: prompt.endpoint)
        switch result {
        case .unreachable:
            prompt.localReachable = false
            prompt.localModels = []
        case .reachable(let models):
            prompt.localReachable = true
            prompt.localModels = models
            if prompt.model.isEmpty, let first = models.first {
                prompt.model = first
            } else if !models.isEmpty, !models.contains(prompt.model) {
                // Keep the typed model so a pull-in-progress name still works.
            }
        }
        // Normalize stored endpoint to OpenAI-compat base when user entered native URL.
        let native = OllamaClient.nativeBaseURL(from: prompt.endpoint)
        let openAI = OllamaClient.openAIEndpoint(fromNativeBase: native)
        if prompt.endpoint.trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "/")) != openAI
            && OllamaClient.looksLikeLocalEndpoint(prompt.endpoint)
            && !prompt.endpoint.contains("/chat/completions")
        {
            // If they typed http://localhost:11434, upgrade to /v1 for chat.
            if !prompt.endpoint.lowercased().contains("/v1") {
                prompt.endpoint = openAI
            }
        }
        AppModel.shared.rebuildMenu()
    }
}
