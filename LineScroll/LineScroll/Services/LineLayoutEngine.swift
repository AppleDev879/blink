import UIKit

/// Breaks reading text into **layout lines** (wrapping at the reader width), not file newlines.
/// Uses TextKit 1 `NSLayoutManager` for stable document `NSRange`s; fine for MVP snap paging.
/// TextKit 2 (`NSTextLayoutManager`) is a natural upgrade path later.
enum LineLayoutEngine {
    static func lines(
        for text: String,
        width: CGFloat,
        font: UIFont,
        textColor: UIColor = .label
    ) -> [ReadingLine] {
        let usableWidth = max(width, 32)
        let storage = NSTextStorage(
            attributedString: NSAttributedString(
                string: text,
                attributes: [
                    .font: font,
                    .foregroundColor: textColor
                ]
            )
        )
        let layoutManager = NSLayoutManager()
        let container = NSTextContainer(size: CGSize(width: usableWidth, height: CGFloat.greatestFiniteMagnitude))
        container.lineFragmentPadding = 0
        container.maximumNumberOfLines = 0
        layoutManager.addTextContainer(container)
        storage.addLayoutManager(layoutManager)

        // Force full layout.
        _ = layoutManager.glyphRange(for: container)

        var result: [ReadingLine] = []
        var index = 0
        var glyphIndex = 0
        let glyphCount = layoutManager.numberOfGlyphs

        while glyphIndex < glyphCount {
            var lineGlyphRange = NSRange(location: 0, length: 0)
            layoutManager.lineFragmentRect(forGlyphAt: glyphIndex, effectiveRange: &lineGlyphRange)
            let charRange = layoutManager.characterRange(forGlyphRange: lineGlyphRange, actualGlyphRange: nil)
            if charRange.length > 0 {
                let substring = (text as NSString).substring(with: charRange)
                result.append(ReadingLine(index: index, characterRange: charRange, text: substring))
                index += 1
            }
            let next = NSMaxRange(lineGlyphRange)
            if next <= glyphIndex { break }
            glyphIndex = next
        }

        if result.isEmpty, !text.isEmpty {
            result = [
                ReadingLine(
                    index: 0,
                    characterRange: NSRange(location: 0, length: (text as NSString).length),
                    text: text
                )
            ]
        }
        return result
    }

    static func lineIndex(nearestTo characterOffset: Int, in lines: [ReadingLine]) -> Int {
        guard !lines.isEmpty else { return 0 }
        if characterOffset <= 0 { return 0 }
        if let exact = lines.firstIndex(where: { NSLocationInRange(characterOffset, $0.characterRange) }) {
            return exact
        }
        if let next = lines.firstIndex(where: { $0.characterRange.location >= characterOffset }) {
            return next
        }
        return lines.count - 1
    }
}
