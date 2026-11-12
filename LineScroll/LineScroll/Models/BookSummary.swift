import Foundation

/// Catalog hit from Gutendex or the bundled starter list.
struct BookSummary: Identifiable, Hashable, Codable {
    let id: Int
    let title: String
    let authors: [String]
    let languages: [String]
    let downloadCount: Int?
    let plainTextURL: URL?
    let subjects: [String]

    var authorDisplay: String {
        authors.isEmpty ? "Unknown author" : authors.joined(separator: ", ")
    }

    /// Prefer catalog URL; otherwise the common PG `cache/epub` plain-text path.
    var resolvedPlainTextURL: URL? {
        plainTextURL ?? StarterCatalog.fallbackPlainTextURL(bookID: id)
    }
}

struct GutendexPage: Decodable {
    let count: Int
    let next: URL?
    let previous: URL?
    let results: [GutendexBook]
}

struct GutendexBook: Decodable {
    let id: Int
    let title: String
    let authors: [GutendexPerson]
    let languages: [String]?
    let download_count: Int?
    let subjects: [String]?
    let formats: [String: String]

    func asSummary() -> BookSummary {
        BookSummary(
            id: id,
            title: title,
            authors: authors.map(\.name),
            languages: languages ?? [],
            downloadCount: download_count,
            plainTextURL: Self.preferredPlainTextURL(from: formats),
            subjects: subjects ?? []
        )
    }

    /// Prefer UTF-8 plain text; fall back to generic text/plain.
    private static func preferredPlainTextURL(from formats: [String: String]) -> URL? {
        let preferredKeys = [
            "text/plain; charset=utf-8",
            "text/plain; charset=us-ascii",
            "text/plain"
        ]
        for key in preferredKeys {
            if let value = formats[key], let url = URL(string: value), !value.contains(".zip") {
                return url
            }
        }
        // Some entries use keys with different spacing / order.
        for (key, value) in formats where key.lowercased().hasPrefix("text/plain") && !value.contains(".zip") {
            return URL(string: value)
        }
        return nil
    }
}

struct GutendexPerson: Decodable {
    let name: String
}
