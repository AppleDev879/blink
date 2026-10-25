import Foundation

/// Privacy-respecting, opt-in analytics (TelemetryDeck-compatible HTTP signals).
///
/// - Default **off**. Nothing leaves the device until the user enables Share Analytics in Settings.
/// - Anonymous client id (random UUID in UserDefaults). No OCR text, no prompts, no API keys.
/// - App ID comes from Info.plist `BlinkTelemetryDeckAppID` (xcconfig placeholder).
@MainActor
final class AnalyticsClient: ObservableObject {
    static let shared = AnalyticsClient()

    @Published private(set) var isEnabled: Bool

    private let defaults: UserDefaults
    private let session: URLSession
    private let enabledKey = "blink.analytics.enabled"
    private let clientUserKey = "blink.analytics.clientUser"
    private let ingestURL = URL(string: "https://nom.telemetrydeck.com/v2/signals/")!

    private init(
        defaults: UserDefaults = .standard,
        session: URLSession = .shared
    ) {
        self.defaults = defaults
        self.session = session
        self.isEnabled = defaults.bool(forKey: enabledKey)
    }

    var appID: String {
        let raw = Bundle.main.object(forInfoDictionaryKey: "BlinkTelemetryDeckAppID") as? String ?? ""
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty || trimmed.hasPrefix("YOUR_") || trimmed == "$(BLINK_TELEMETRYDECK_APP_ID)" {
            return ""
        }
        return trimmed
    }

    var isConfigured: Bool { !appID.isEmpty }

    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        defaults.set(enabled, forKey: enabledKey)
    }

    func track(_ event: AnalyticsEvent, parameters: [String: String] = [:]) {
        guard isEnabled, isConfigured else { return }

        let signal: [String: Any] = [
            "appID": appID,
            "clientUser": clientUser(),
            "type": event.rawValue,
            "payload": parameters,
            "isTestMode": Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt"
        ]

        var request = URLRequest(url: ingestURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 8
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: [signal], options: [])
        } catch {
            return
        }

        session.dataTask(with: request) { _, _, _ in
            // Fire-and-forget; failures must never affect capture.
        }.resume()
    }

    private func clientUser() -> String {
        if let existing = defaults.string(forKey: clientUserKey), !existing.isEmpty {
            return existing
        }
        let fresh = UUID().uuidString.lowercased()
        defaults.set(fresh, forKey: clientUserKey)
        return fresh
    }
}
