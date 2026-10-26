import Foundation

/// Local Ollama discovery helpers. Tags API is native; chat uses the OpenAI-compatible `/v1` path.
struct OllamaClient: Sendable {
    static let defaultBaseURL = "http://localhost:11434"
    static let defaultOpenAIEndpoint = "http://localhost:11434/v1"
    static let defaultModel = "llama3.2"

    var session: URLSession = .shared

    enum Reachability: Equatable, Sendable {
        case unreachable
        case reachable(models: [String])
    }

    /// Strips a trailing `/v1` (OpenAI-compat base) so `/api/tags` resolves correctly.
    static func nativeBaseURL(from endpointOrBase: String) -> String {
        var trimmed = endpointOrBase
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        if trimmed.lowercased().hasSuffix("/v1") {
            trimmed = String(trimmed.dropLast(3))
                .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        }
        return trimmed.isEmpty ? defaultBaseURL : trimmed
    }

    static func openAIEndpoint(fromNativeBase base: String) -> String {
        let native = nativeBaseURL(from: base)
        return native + "/v1"
    }

    static func looksLikeLocalEndpoint(_ endpoint: String) -> Bool {
        let lower = endpoint.lowercased()
        return lower.contains("localhost") || lower.contains("127.0.0.1") || lower.contains("::1")
    }

    static func tagsURL(from endpointOrBase: String) -> URL? {
        let base = nativeBaseURL(from: endpointOrBase)
        return URL(string: base + "/api/tags")
    }

    /// GET `/api/tags` — success means Ollama is up; model names when present.
    func probe(endpointOrBase: String, timeout: TimeInterval = 2) async -> Reachability {
        guard let url = Self.tagsURL(from: endpointOrBase) else { return .unreachable }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = max(1, timeout)

        do {
            let (data, response) = try await session.data(for: request)
            let code = (response as? HTTPURLResponse)?.statusCode ?? -1
            guard (200..<300).contains(code) else { return .unreachable }
            let names = Self.parseModelNames(from: data)
            return .reachable(models: names)
        } catch {
            return .unreachable
        }
    }

    static func parseModelNames(from data: Data) -> [String] {
        guard
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let models = json["models"] as? [[String: Any]]
        else {
            return []
        }
        return models.compactMap { entry in
            (entry["name"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        .filter { !$0.isEmpty }
    }
}
