import Foundation

/// Shared path for OCR → optional prompt transform → clipboard.
enum CopyPipeline {
    enum Source: String {
        case capture
    }

    /// - Parameter transformModifierHeld: Latched at selection release. When `nil`, reads live flags
    ///   (useful for tests / non-capture callers).
    @MainActor
    static func copyText(
        _ text: String,
        source: Source,
        transformModifierHeld: Bool? = nil
    ) async -> String {
        let settings = PromptTransformSettings.shared
        var output = text
        let held = transformModifierHeld
            ?? ModifierHoldDetector.isHeld(settings.requiredModifier)
        let wantsTransform = settings.provider.transformsEnabled && held

        if wantsTransform {
            switch settings.provider {
            case .off:
                break

            case .byok:
                if let apiKey = KeychainStore.apiKey(), !apiKey.isEmpty {
                    output = await runTransform(
                        text: text,
                        settings: settings,
                        apiKey: apiKey,
                        source: source,
                        provider: .byok
                    )
                }
                // No key → raw OCR; menu shows a quiet setup hint.

            case .local:
                output = await runTransform(
                    text: text,
                    settings: settings,
                    apiKey: nil,
                    source: source,
                    provider: .local
                )
            }
        }

        ClipboardFeedback.copy(output)

        switch source {
        case .capture:
            AnalyticsClient.shared.track(.captureCompleted)
        }

        return output
    }

    @MainActor
    private static func runTransform(
        text: String,
        settings: PromptTransformSettings,
        apiKey: String?,
        source: Source,
        provider: LLMProvider
    ) async -> String {
        do {
            let service = PromptTransformService()
            let result = try await service.transform(
                text: text,
                template: settings.template,
                endpoint: settings.endpoint,
                model: settings.model,
                apiKey: apiKey,
                timeout: settings.timeoutSeconds
            )
            if provider == .local {
                settings.localReachable = true
            }
            AnalyticsClient.shared.track(
                .promptTransformUsed,
                parameters: [
                    "source": source.rawValue,
                    "provider": provider.rawValue
                ]
            )
            return result
        } catch {
            // Quiet fallback — keep moving with raw OCR.
            if provider == .local {
                settings.localReachable = false
            }
            return text
        }
    }
}
