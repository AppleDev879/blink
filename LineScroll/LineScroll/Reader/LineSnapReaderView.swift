import SwiftUI
import UIKit

/// UIKit bridge: vertical paging collection of layout lines (one line centered per page).
struct LineSnapReaderView: UIViewControllerRepresentable {
    let lines: [ReadingLine]
    let font: UIFont
    @Binding var currentLineIndex: Int
    var onLineChange: (ReadingLine) -> Void

    func makeUIViewController(context: Context) -> LineSnapReaderViewController {
        let vc = LineSnapReaderViewController()
        vc.onLineChange = { line in
            onLineChange(line)
        }
        return vc
    }

    func updateUIViewController(_ uiViewController: LineSnapReaderViewController, context: Context) {
        uiViewController.apply(
            lines: lines,
            font: font,
            currentLineIndex: currentLineIndex
        )
        uiViewController.onLineChange = { line in
            DispatchQueue.main.async {
                if currentLineIndex != line.index {
                    currentLineIndex = line.index
                }
                onLineChange(line)
            }
        }
    }
}

final class LineSnapReaderViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    var onLineChange: ((ReadingLine) -> Void)?

    private var lines: [ReadingLine] = []
    private var font: UIFont = .systemFont(ofSize: 22)
    private var pendingIndex: Int?
    private var isProgrammaticScroll = false

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.isPagingEnabled = true
        cv.showsVerticalScrollIndicator = false
        cv.backgroundColor = .systemBackground
        cv.dataSource = self
        cv.delegate = self
        cv.register(LinePageCell.self, forCellWithReuseIdentifier: LinePageCell.reuseID)
        cv.translatesAutoresizingMaskIntoConstraints = false
        return cv
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    func apply(lines: [ReadingLine], font: UIFont, currentLineIndex: Int) {
        let linesChanged = self.lines != lines
        let fontChanged = self.font != font
        self.font = font

        if linesChanged || fontChanged {
            self.lines = lines
            collectionView.reloadData()
            collectionView.layoutIfNeeded()
            pendingIndex = currentLineIndex
            scrollToPendingIfNeeded(animated: false)
        } else if currentLineIndex != visibleIndex(), abs(currentLineIndex - (visibleIndex() ?? -1)) > 0 {
            pendingIndex = currentLineIndex
            scrollToPendingIfNeeded(animated: false)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollToPendingIfNeeded(animated: false)
    }

    private func scrollToPendingIfNeeded(animated: Bool) {
        guard let pendingIndex, !lines.isEmpty else { return }
        let clamped = min(max(pendingIndex, 0), lines.count - 1)
        let indexPath = IndexPath(item: clamped, section: 0)
        guard collectionView.numberOfItems(inSection: 0) > clamped else { return }
        isProgrammaticScroll = true
        collectionView.scrollToItem(at: indexPath, at: .centeredVertically, animated: animated)
        self.pendingIndex = nil
        DispatchQueue.main.async { [weak self] in
            self?.isProgrammaticScroll = false
        }
    }

    private func visibleIndex() -> Int? {
        let mid = CGPoint(x: collectionView.bounds.midX, y: collectionView.contentOffset.y + collectionView.bounds.height / 2)
        return collectionView.indexPathForItem(at: mid)?.item
    }

    // MARK: UICollectionView

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        lines.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: LinePageCell.reuseID, for: indexPath) as! LinePageCell
        cell.configure(text: lines[indexPath.item].text, font: font)
        return cell
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        collectionView.bounds.size
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        reportVisibleLine()
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        reportVisibleLine()
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate { reportVisibleLine() }
    }

    private func reportVisibleLine() {
        guard !isProgrammaticScroll, let idx = visibleIndex(), lines.indices.contains(idx) else { return }
        onLineChange?(lines[idx])
    }
}

private final class LinePageCell: UICollectionViewCell {
    static let reuseID = "LinePageCell"

    private let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .systemBackground
        label.numberOfLines = 0
        label.textAlignment = .left
        label.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            label.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            label.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
        contentView.layoutMargins = UIEdgeInsets(top: 24, left: 28, bottom: 24, right: 28)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(text: String, font: UIFont) {
        label.font = font
        label.textColor = .label
        label.text = text.trimmingCharacters(in: .newlines)
    }
}
