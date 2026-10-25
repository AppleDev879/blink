import Foundation

/// Pure helpers for cleaning Vision OCR output before clipboard copy.
enum OCRTextNormalizer {
    /// Collapse runs of whitespace within lines, trim edges, drop empty lines,
    /// and join with a single newline. Preserves intentional line breaks.
    static func normalize(_ raw: String) -> String {
        let lines = raw
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map { line -> String in
                let collapsed = line
                    .split(whereSeparator: { $0.isWhitespace })
                    .joined(separator: " ")
                return collapsed
            }
            .map { $0.trimmingCharacters(in: .whitespaces) }

        // Drop leading/trailing empty lines; keep a single blank between paragraphs max.
        var cleaned: [String] = []
        var pendingBlank = false
        for line in lines {
            if line.isEmpty {
                pendingBlank = !cleaned.isEmpty
                continue
            }
            if pendingBlank {
                cleaned.append("")
                pendingBlank = false
            }
            cleaned.append(line)
        }
        return cleaned.joined(separator: "\n")
    }

    /// Prefer higher-confidence observations; join top-to-bottom, left-to-right.
    static func joinObservations(
        _ items: [(text: String, confidence: Float, minY: CGFloat, minX: CGFloat)],
        minimumConfidence: Float = 0.3
    ) -> String {
        let filtered = items
            .filter { $0.confidence >= minimumConfidence && !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .sorted { lhs, rhs in
                // Vision uses bottom-left origin; higher minY is visually higher → sort descending Y then ascending X.
                if abs(lhs.minY - rhs.minY) > 0.02 {
                    return lhs.minY > rhs.minY
                }
                return lhs.minX < rhs.minX
            }
            .map(\.text)

        return normalize(filtered.joined(separator: "\n"))
    }
}
