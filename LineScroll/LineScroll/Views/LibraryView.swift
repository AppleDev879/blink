import SwiftUI

struct LibraryView: View {
    @EnvironmentObject private var library: LibraryStore
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if library.books.isEmpty {
                    ContentUnavailableView(
                        "No books yet",
                        systemImage: "books.vertical",
                        description: Text("Browse the catalog and download a plain-text book to read offline, one layout line at a time.")
                    )
                } else {
                    List {
                        Section {
                            ForEach(library.books) { book in
                                NavigationLink(value: book.id) {
                                    LibraryRow(book: book)
                                }
                            }
                            .onDelete { indexSet in
                                for index in indexSet {
                                    library.remove(bookID: library.books[index].id)
                                }
                            }
                        } footer: {
                            Text("Texts sourced from Project Gutenberg via Gutendex. Public domain in the U.S.; check local law elsewhere.")
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("LineScroll")
            .navigationDestination(for: Int.self) { bookID in
                if let book = library.book(id: bookID) {
                    ReaderView(book: book)
                } else {
                    Text("Book missing")
                }
            }
        }
    }
}

private struct LibraryRow: View {
    let book: LibraryBook

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(book.title)
                .font(.headline)
                .lineLimit(2)
            Text(book.authorDisplay)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            if book.characterOffset > 0 {
                Text("Resume saved")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }
}
