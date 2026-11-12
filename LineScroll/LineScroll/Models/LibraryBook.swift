import Foundation

/// A book downloaded for offline reading.
struct LibraryBook: Identifiable, Hashable, Codable {
    let id: Int
    var title: String
    var authors: [String]
    var fileName: String
    var downloadedAt: Date
    /// UTF-16 / NSString character offset into the cleaned reading text.
    var characterOffset: Int
    var lastOpenedAt: Date?

    var authorDisplay: String {
        authors.isEmpty ? "Unknown author" : authors.joined(separator: ", ")
    }
}

struct ReadingLine: Identifiable, Hashable {
    let index: Int
    let characterRange: NSRange
    let text: String

    var id: Int { index }
}
