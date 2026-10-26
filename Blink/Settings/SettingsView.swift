import SwiftUI

struct SettingsView: View {
    @ObservedObject private var analytics = AnalyticsClient.shared
    @ObservedObject private var prompt = PromptTransformSettings.shared
    @ObservedObject private var capture = CapturePreferences.shared
    @ObservedObject private var loginItem = AppModel.shared.loginItem
    @State private var apiKeyDraft = ""
    @State private var apiKeySaved = KeychainStore.hasAPIKey

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

            Section {
                Toggle(
                    "Transform with prompt when \(prompt.requiredModifier.displaySymbol) held",
                    isOn: $prompt.isEnabled
                )
                Text("At copy time, hold \(prompt.requiredModifier.displaySymbol) to run OCR text through your prompt.")
                    .font(.system(size: 12))
                    .foregroundStyle(Brand.fog)

                Picker("Modifier", selection: $prompt.modifierName) {
                    ForEach(modifierOptions, id: \.0) { option in
                        Text(option.1).tag(option.0)
                    }
                }

                TextField("Prompt template", text: $prompt.template, axis: .vertical)
                    .lineLimit(3...8)

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
                        }
                    }
                }

                TextField("Endpoint", text: $prompt.endpoint)
                TextField("Model", text: $prompt.model)

                HStack {
                    Text("Timeout")
                    Slider(value: $prompt.timeoutSeconds, in: 5...60, step: 1)
                    Text("\(Int(prompt.timeoutSeconds))s")
                        .monospacedDigit()
                        .frame(width: 36, alignment: .trailing)
                }
            } header: {
                Text("Prompt transform")
            } footer: {
                Text("No API key? Blink copies raw text and stays quiet. Set a key when you want the transform.")
                    .font(.system(size: 11))
            }
        }
        .formStyle(.grouped)
        .frame(minWidth: 440, idealWidth: 460, minHeight: 420, idealHeight: 520)
        .padding(.bottom, 8)
        .onAppear {
            apiKeySaved = KeychainStore.hasAPIKey
            loginItem.refresh()
        }
    }

    private func saveAPIKey() {
        let trimmed = apiKeyDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            KeychainStore.setAPIKey(trimmed)
            apiKeyDraft = ""
            apiKeySaved = true
        }
    }
}
