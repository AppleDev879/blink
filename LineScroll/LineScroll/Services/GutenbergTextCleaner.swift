import Foundation

enum GutenbergTextCleaner {
    /// Strip the standard Project Gutenberg header/footer boilerplate when present.
    /// Keeps license text available separately via the in-app credit screen.
    static func cleanedReadingText(from raw: String) -> String {
        var text = raw.replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")

        if let start = findStartMarker(in: text) {
            text = String(text[start...])
        }
        if let end = findEndMarker(in: text) {
            text = String(text[..<end])
        }

        // Collapse runs of 3+ blank lines to two.
        while text.contains("\n\n\n\n") {
            text = text.replacingOccurrences(of: "\n\n\n\n", with: "\n\n\n")
        }
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func findStartMarker(in text: String) -> String.Index? {
        let patterns = [
            "*** START OF THE PROJECT GUTENBERG",
            "*** START OF THIS PROJECT GUTENBERG",
            "***START OF THE PROJECT GUTENBERG"
        ]
        for pattern in patterns {
            if let range = text.range(of: pattern, options: .caseInsensitive) {
                if let newline = text[range.upperBound...].firstIndex(of: "\n") {
                    return text.index(after: newline)
                }
                return range.upperBound
            }
        }
        return nil
    }

    private static func findEndMarker(in text: String) -> String.Index? {
        let patterns = [
            "*** END OF THE PROJECT GUTENBERG",
            "*** END OF THIS PROJECT GUTENBERG",
            "***END OF THE PROJECT GUTENBERG",
            "End of the Project Gutenberg",
            "End of Project Gutenberg"
        ]
        for pattern in patterns {
            if let range = text.range(of: pattern, options: .caseInsensitive) {
                return range.lowerBound
            }
        }
        return nil
    }
}
