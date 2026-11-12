import SwiftUI

enum ColorSchemePreference: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

@MainActor
final class ReaderSettings: ObservableObject {
    @Published var fontSize: Double {
        didSet { UserDefaults.standard.set(fontSize, forKey: Keys.fontSize) }
    }

    @Published var colorSchemePreference: ColorSchemePreference {
        didSet { UserDefaults.standard.set(colorSchemePreference.rawValue, forKey: Keys.colorScheme) }
    }

    private enum Keys {
        static let fontSize = "reader.fontSize"
        static let colorScheme = "reader.colorScheme"
    }

    init() {
        let storedSize = UserDefaults.standard.object(forKey: Keys.fontSize) as? Double
        fontSize = storedSize ?? 22
        let raw = UserDefaults.standard.string(forKey: Keys.colorScheme) ?? ColorSchemePreference.system.rawValue
        colorSchemePreference = ColorSchemePreference(rawValue: raw) ?? .system
    }

    var bodyFont: Font {
        .system(size: fontSize, weight: .regular, design: .serif)
    }

    var uiFont: UIFont {
        UIFont.systemFont(ofSize: fontSize, weight: .regular).withDesign(.serif)
            ?? UIFont.systemFont(ofSize: fontSize)
    }
}

private extension UIFont {
    func withDesign(_ design: UIFontDescriptor.SystemDesign) -> UIFont? {
        guard let descriptor = fontDescriptor.withDesign(design) else { return nil }
        return UIFont(descriptor: descriptor, size: pointSize)
    }
}
