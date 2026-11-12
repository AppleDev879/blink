import Foundation

enum GutendexError: LocalizedError {
    case invalidURL
    case badStatus(Int)
    case decoding(Error)
    case empty

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Could not build catalog request."
        case .badStatus(let code):
            return "Catalog request failed (\(code))."
        case .decoding:
            return "Could not parse catalog response."
        case .empty:
            return "No books matched."
        }
    }
}

/// Thin client for https://gutendex.com — unofficial JSON over the PG catalog.
/// Always sends an identifying User-Agent (PG / mirror etiquette).
actor GutendexClient {
    static let shared = GutendexClient()

    private let session: URLSession
    private let baseURL = URL(string: "https://gutendex.com/books/")!

    /// Contactable UA per Project Gutenberg / OPDS guidance.
    static let userAgent =
        "LineScroll/1.0 (iOS; https://github.com/AppleDev879/blink; contact: abarrett879@gmail.com)"

    init(session: URLSession? = nil) {
        if let session {
            self.session = session
        } else {
            let config = URLSessionConfiguration.default
            config.httpAdditionalHeaders = [
                "User-Agent": Self.userAgent,
                "Accept": "application/json"
            ]
            config.timeoutIntervalForRequest = 30
            self.session = URLSession(configuration: config)
        }
    }

    func search(query: String, pageURL: URL? = nil) async throws -> (books: [BookSummary], next: URL?) {
        let url: URL
        if let pageURL {
            url = pageURL
        } else {
            var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)!
            var items: [URLQueryItem] = [
                URLQueryItem(name: "languages", value: "en"),
                URLQueryItem(name: "mime_type", value: "text/plain")
            ]
            let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                items.append(URLQueryItem(name: "search", value: trimmed))
            }
            components.queryItems = items
            guard let built = components.url else { throw GutendexError.invalidURL }
            url = built
        }

        let (data, response) = try await session.data(from: url)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw GutendexError.badStatus(http.statusCode)
        }

        do {
            let page = try JSONDecoder().decode(GutendexPage.self, from: data)
            // Keep entries even without an explicit text/plain format — downloads
            // can fall back to the standard PG cache/epub plain-text URL.
            let books = page.results.map { $0.asSummary() }.filter { $0.resolvedPlainTextURL != nil }
            return (books, page.next)
        } catch {
            throw GutendexError.decoding(error)
        }
    }

    func popular(limitHintIgnored: Bool = true) async throws -> [BookSummary] {
        let (books, _) = try await search(query: "")
        return books
    }
}
