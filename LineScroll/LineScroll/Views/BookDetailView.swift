import SwiftUI

struct BookDetailView: View {
    let book: BookSummary
    var onDownload: () -> Void

    @EnvironmentObject private var library: LibraryStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text(book.title)
                        .font(.title2.weight(.semibold))
                    Text(book.authorDisplay)
                        .foregroundStyle(.secondary)
                }

                if !book.subjects.isEmpty {
                    Section("Subjects") {
                        Text(book.subjects.prefix(8).joined(separator: " · "))
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                Section {
                    if library.isDownloaded(book.id) {
                        Label("Already in your library", systemImage: "checkmark.circle")
                    } else if book.resolvedPlainTextURL == nil {
                        Text("No plain-text file listed for this title.")
                            .foregroundStyle(.secondary)
                    } else {
                        Button {
                            onDownload()
                        } label: {
                            Label("Download plain text", systemImage: "arrow.down.circle")
                        }
                    }
                } footer: {
                    Text("LineScroll stores the file on-device for offline reading. Source: Project Gutenberg (via Gutendex catalog metadata).")
                }
            }
            .navigationTitle("Book")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}
