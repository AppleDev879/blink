import Foundation

/// Shared path for OCR → optional prompt transform → clipboard.
enum CopyPipeline {
    enum Source: String {
        case capture
    }

    @MainActor
    static func copyText(_ text: String, source: Source) async -> String {
        let settings = PromptTransformSettings.shared
        var output = text
        let wantsTransform = settings.isEnabled && ModifierHoldDetector.isHeld(settings.requiredModifier)

        if wantsTransform, let apiKey = KeychainStore.apiKey(), !apiKey.isEmpty {
            do {
                let service = PromptTransformService()
                output = try await service.transform(
                    text: text,
                    template: settings.template,
                    endpoint: settings.endpoint,
                    model: settings.model,
                    apiKey: apiKey,
                    timeout: settings.timeoutSeconds
                )
                AnalyticsClient.shared.track(.promptTransformUsed, parameters: ["source": source.rawValue])
            } catch {
                // Quiet fallback — keep moving with raw OCR.
                output = text
            }
        }

        ClipboardFeedback.copy(output)

        switch source {
        case .capture:
            AnalyticsClient.shared.track(.captureCompleted)
        }

        return output
    }
}
