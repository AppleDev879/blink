import Foundation

/// Pure template interpolation for prompt-on-modifier copy.
enum PromptTemplate {
    static let textPlaceholder = "{{text}}"
    static let defaultTemplate = "Clean and fix OCR errors:\n\n{{text}}"

    /// Replaces every `{{text}}` occurrence with `text`. Other content is left untouched.
    static func interpolate(_ template: String, text: String) -> String {
        guard template.contains(textPlaceholder) else {
            // If the user omitted the placeholder, append OCR text so the model still sees it.
            if template.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return text
            }
            return template + "\n\n" + text
        }
        return template.replacingOccurrences(of: textPlaceholder, with: text)
    }
}
