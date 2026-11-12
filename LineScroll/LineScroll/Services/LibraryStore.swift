import Foundation

@MainActor
final class LibraryStore: ObservableObject {
    @Published private(set) var books: [LibraryBook] = []

    private let fileManager = FileManager.default
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private var libraryDirectory: URL {
        let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docs.appendingPathComponent("LineScroll", isDirectory: true)
    }

    private var booksDirectory: URL {
        libraryDirectory.appendingPathComponent("Books", isDirectory: true)
    }

    private var indexURL: URL {
        libraryDirectory.appendingPathComponent("library.json")
    }

    init() {
        try? fileManager.createDirectory(at: booksDirectory, withIntermediateDirectories: true)
        load()
        seedSampleIfNeeded()
    }

    func book(id: Int) -> LibraryBook? {
        books.first { $0.id == id }
    }

    func isDownloaded(_ id: Int) -> Bool {
        book(id: id) != nil
    }

    func fileURL(for book: LibraryBook) -> URL {
        booksDirectory.appendingPathComponent(book.fileName)
    }

    func loadText(for book: LibraryBook) throws -> String {
        let data = try Data(contentsOf: fileURL(for: book))
        // PG texts are usually UTF-8; fall back to Latin-1-ish for older files.
        if let utf8 = String(data: data, encoding: .utf8) {
            return GutenbergTextCleaner.cleanedReadingText(from: utf8)
        }
        if let latin1 = String(data: data, encoding: .isoLatin1) {
            return GutenbergTextCleaner.cleanedReadingText(from: latin1)
        }
        throw CocoaError(.fileReadCorruptFile)
    }

    func upsertDownloaded(
        summary: BookSummary,
        fileName: String
    ) {
        if let idx = books.firstIndex(where: { $0.id == summary.id }) {
            books[idx].title = summary.title
            books[idx].authors = summary.authors
            books[idx].fileName = fileName
            books[idx].downloadedAt = Date()
        } else {
            books.insert(
                LibraryBook(
                    id: summary.id,
                    title: summary.title,
                    authors: summary.authors,
                    fileName: fileName,
                    downloadedAt: Date(),
                    characterOffset: 0,
                    lastOpenedAt: nil
                ),
                at: 0
            )
        }
        persist()
    }

    func updateProgress(bookID: Int, characterOffset: Int) {
        guard let idx = books.firstIndex(where: { $0.id == bookID }) else { return }
        books[idx].characterOffset = max(0, characterOffset)
        books[idx].lastOpenedAt = Date()
        // Keep recently opened near top without reshuffling mid-read excessively.
        let item = books.remove(at: idx)
        books.insert(item, at: 0)
        persist()
    }

    func remove(bookID: Int) {
        guard let idx = books.firstIndex(where: { $0.id == bookID }) else { return }
        let book = books.remove(at: idx)
        try? fileManager.removeItem(at: fileURL(for: book))
        persist()
    }

    func destinationURL(forBookID id: Int) -> URL {
        booksDirectory.appendingPathComponent("\(id).txt")
    }

    private func load() {
        guard fileManager.fileExists(atPath: indexURL.path) else {
            books = []
            return
        }
        do {
            let data = try Data(contentsOf: indexURL)
            books = try decoder.decode([LibraryBook].self, from: data)
        } catch {
            books = []
        }
    }

    private func persist() {
        do {
            try fileManager.createDirectory(at: libraryDirectory, withIntermediateDirectories: true)
            let data = try encoder.encode(books)
            try data.write(to: indexURL, options: [.atomic])
        } catch {
            // Best-effort persistence for MVP.
        }
    }

    /// Bundled excerpt so the reader works before any network download.
    private func seedSampleIfNeeded() {
        let sampleID = -1
        guard book(id: sampleID) == nil else { return }
        guard let bundled = Bundle.main.url(forResource: "sample-excerpt", withExtension: "txt"),
              let data = try? Data(contentsOf: bundled) else { return }
        let dest = destinationURL(forBookID: sampleID)
        do {
            try data.write(to: dest, options: [.atomic])
            books.insert(
                LibraryBook(
                    id: sampleID,
                    title: "Sample: Pride and Prejudice (excerpt)",
                    authors: ["Jane Austen"],
                    fileName: dest.lastPathComponent,
                    downloadedAt: Date(),
                    characterOffset: 0,
                    lastOpenedAt: nil
                ),
                at: 0
            )
            persist()
        } catch {
            // Ignore seed failures.
        }
    }
}
