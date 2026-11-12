import SwiftUI

struct ReaderView: View {
    let book: LibraryBook

    @EnvironmentObject private var library: LibraryStore
    @EnvironmentObject private var settings: ReaderSettings
    @Environment(\.dismiss) private var dismiss

    @State private var lines: [ReadingLine] = []
    @State private var currentLineIndex: Int = 0
    @State private var loadError: String?
    @State private var showChrome = true
    @State private var layoutWidth: CGFloat = 0
    @State private var loadedText: String = ""

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color(.systemBackground).ignoresSafeArea()

                if let loadError {
                    ContentUnavailableView(
                        "Couldn’t open book",
                        systemImage: "exclamationmark.triangle",
                        description: Text(loadError)
                    )
                } else if lines.isEmpty {
                    ProgressView("Laying out lines…")
                } else {
                    LineSnapReaderView(
                        lines: lines,
                        font: settings.uiFont,
                        currentLineIndex: $currentLineIndex,
                        onLineChange: { line in
                            library.updateProgress(bookID: book.id, characterOffset: line.characterRange.location)
                        }
                    )
                    .ignoresSafeArea(edges: .bottom)
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showChrome.toggle()
                        }
                    }
                }

                if showChrome {
                    VStack {
                        readerChrome
                        Spacer()
                        progressBar
                    }
                    .transition(.opacity)
                }
            }
            .onAppear {
                layoutWidth = geo.size.width - 56
                loadIfNeeded()
            }
            .onChange(of: geo.size.width) { _, newWidth in
                let usable = newWidth - 56
                if abs(usable - layoutWidth) > 1 {
                    layoutWidth = usable
                    relayout(preservingOffset: true)
                }
            }
            .onChange(of: settings.fontSize) { _, _ in
                relayout(preservingOffset: true)
            }
        }
        .navigationBarHidden(true)
        .statusBarHidden(!showChrome)
    }

    private var readerChrome: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.body.weight(.semibold))
                    .padding(10)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .accessibilityLabel("Back")

            VStack(alignment: .leading, spacing: 2) {
                Text(book.title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                Text(book.authorDisplay)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            if !lines.isEmpty {
                Text("\(currentLineIndex + 1) / \(lines.count)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 10)
        .background(.ultraThinMaterial.opacity(0.92))
    }

    private var progressBar: some View {
        let progress = lines.isEmpty ? 0.0 : Double(currentLineIndex) / Double(max(lines.count - 1, 1))
        return VStack(spacing: 6) {
            ProgressView(value: progress)
                .tint(.primary)
            Text("\(Int((progress * 100).rounded()))%")
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial.opacity(0.92))
    }

    private func loadIfNeeded() {
        guard loadedText.isEmpty else { return }
        do {
            loadedText = try library.loadText(for: book)
            relayout(preservingOffset: true)
        } catch {
            loadError = error.localizedDescription
        }
    }

    private func relayout(preservingOffset: Bool) {
        guard layoutWidth > 0, !loadedText.isEmpty else { return }
        let offset: Int
        if preservingOffset {
            if lines.indices.contains(currentLineIndex) {
                offset = lines[currentLineIndex].characterRange.location
            } else {
                offset = library.book(id: book.id)?.characterOffset ?? book.characterOffset
            }
        } else {
            offset = 0
        }
        let newLines = LineLayoutEngine.lines(
            for: loadedText,
            width: layoutWidth,
            font: settings.uiFont
        )
        lines = newLines
        currentLineIndex = LineLayoutEngine.lineIndex(nearestTo: offset, in: newLines)
    }
}
