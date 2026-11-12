import Foundation

enum StarterCatalog {
    static func load() -> [BookSummary] {
        guard let url = Bundle.main.url(forResource: "starter-catalog", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([BookSummary].self, from: data) else {
            return []
        }
        return decoded
    }

    static func search(query: String) -> [BookSummary] {
        let all = load()
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return all }
        let needle = trimmed.lowercased()
        return all.filter { book in
            book.title.lowercased().contains(needle)
                || book.authors.contains { $0.lowercased().contains(needle) }
                || book.subjects.contains { $0.lowercased().contains(needle) }
        }
    }

    /// Last-resort plain-text URL using the common PG cache path.
    static func fallbackPlainTextURL(bookID: Int) -> URL? {
        URL(string: "https://www.gutenberg.org/cache/epub/\(bookID)/pg\(bookID).txt")
    }
}
