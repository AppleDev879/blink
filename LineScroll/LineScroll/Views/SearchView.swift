import SwiftUI

struct SearchView: View {
    @EnvironmentObject private var library: LibraryStore

    @State private var query = ""
    @State private var results: [BookSummary] = []
    @State private var nextPage: URL?
    @State private var isLoading = false
    @State private var isLoadingMore = false
    @State private var errorMessage: String?
    @State private var downloadingID: Int?
    @State private var selectedBook: BookSummary?

    var body: some View {
        NavigationStack {
            List {
                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }

                Section {
                    ForEach(results) { book in
                        Button {
                            selectedBook = book
                        } label: {
                            SearchRow(
                                book: book,
                                isDownloaded: library.isDownloaded(book.id),
                                isDownloading: downloadingID == book.id
                            )
                        }
                        .disabled(downloadingID != nil)
                    }

                    if nextPage != nil {
                        Button {
                            Task { await loadMore() }
                        } label: {
                            if isLoadingMore {
                                HStack {
                                    Spacer()
                                    ProgressView()
                                    Spacer()
                                }
                            } else {
                                Text("Load more")
                            }
                        }
                    }
                } footer: {
                    Text("Catalog via Gutendex (unofficial Project Gutenberg JSON API). Downloads use listed plain-text URLs with an identifying User-Agent.")
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Browse")
            .searchable(text: $query, prompt: "Title or author")
            .onSubmit(of: .search) {
                Task { await runSearch() }
            }
            .refreshable {
                await runSearch()
            }
            .overlay {
                if isLoading && results.isEmpty {
                    ProgressView("Searching…")
                }
            }
            .task {
                if results.isEmpty {
                    await runSearch()
                }
            }
            .sheet(item: $selectedBook) { book in
                BookDetailView(book: book) {
                    Task { await download(book) }
                }
                .environmentObject(library)
            }
        }
    }

    @MainActor
    private func runSearch() async {
        isLoading = true
        errorMessage = nil
        nextPage = nil
        defer { isLoading = false }
        do {
            let page = try await GutendexClient.shared.search(query: query)
            results = page.books
            nextPage = page.next
            if results.isEmpty {
                results = StarterCatalog.search(query: query)
                if results.isEmpty {
                    errorMessage = GutendexError.empty.errorDescription
                } else {
                    errorMessage = "Live catalog returned no hits — showing starter titles."
                }
            }
        } catch {
            results = StarterCatalog.search(query: query)
            if results.isEmpty {
                errorMessage = error.localizedDescription
            } else {
                errorMessage = "Live catalog unavailable (\(error.localizedDescription)). Showing starter titles."
            }
        }
    }

    @MainActor
    private func loadMore() async {
        guard let nextPage, !isLoadingMore else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }
        do {
            let page = try await GutendexClient.shared.search(query: query, pageURL: nextPage)
            results.append(contentsOf: page.books)
            self.nextPage = page.next
        } catch {
            self.nextPage = nil
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func download(_ book: BookSummary) async {
        downloadingID = book.id
        errorMessage = nil
        defer { downloadingID = nil }
        do {
            let dest = library.destinationURL(forBookID: book.id)
            try await BookDownloadService.shared.download(summary: book, to: dest)
            library.upsertDownloaded(summary: book, fileName: dest.lastPathComponent)
            selectedBook = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct SearchRow: View {
    let book: BookSummary
    let isDownloaded: Bool
    let isDownloading: Bool

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(book.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                Text(book.authorDisplay)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if let count = book.downloadCount {
                    Text("\(count) downloads")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            Spacer()
            if isDownloading {
                ProgressView()
            } else if isDownloaded {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.secondary)
            } else {
                Image(systemName: "arrow.down.circle")
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
