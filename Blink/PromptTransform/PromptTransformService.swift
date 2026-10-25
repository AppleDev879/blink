import Foundation

enum PromptTransformError: Error, LocalizedError {
    case missingAPIKey
    case invalidEndpoint
    case badResponse(Int)
    case emptyCompletion
    case transport(String)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey: return "API key missing."
        case .invalidEndpoint: return "Endpoint looks wrong."
        case .badResponse(let code): return "Model returned \(code)."
        case .emptyCompletion: return "Empty model reply."
        case .transport(let message): return message
        }
    }
}

/// Calls an OpenAI-compatible chat completions endpoint with the user prompt template.
struct PromptTransformService: Sendable {
    var session: URLSession = .shared

    func transform(
        text: String,
        template: String,
        endpoint: String,
        model: String,
        apiKey: String,
        timeout: TimeInterval
    ) async throws -> String {
        let prompt = PromptTemplate.interpolate(template, text: text)
        guard let url = Self.chatCompletionsURL(from: endpoint) else {
            throw PromptTransformError.invalidEndpoint
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = max(3, timeout)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let body: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.2
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw PromptTransformError.transport(error.localizedDescription)
        }

        let code = (response as? HTTPURLResponse)?.statusCode ?? -1
        guard (200..<300).contains(code) else {
            throw PromptTransformError.badResponse(code)
        }

        guard
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let choices = json["choices"] as? [[String: Any]],
            let first = choices.first,
            let message = first["message"] as? [String: Any],
            let content = message["content"] as? String
        else {
            throw PromptTransformError.emptyCompletion
        }

        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw PromptTransformError.emptyCompletion }
        return trimmed
    }

    /// Accepts base (`https://api.openai.com/v1`) or full chat completions URL.
    static func chatCompletionsURL(from endpoint: String) -> URL? {
        let trimmed = endpoint.trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard !trimmed.isEmpty else { return nil }
        if trimmed.hasSuffix("/chat/completions") {
            return URL(string: trimmed)
        }
        return URL(string: trimmed + "/chat/completions")
    }
}
