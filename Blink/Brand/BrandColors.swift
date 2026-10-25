import SwiftUI

/// Blink brand tokens — keep in sync with docs/brand-identity.md
enum Brand {
    static let ink = Color(hex: 0x1A1D21)
    static let paper = Color(hex: 0xF3F5F4)
    static let mint = Color(hex: 0x3DFFB5)
    static let mintDim = Color(hex: 0x1F8F6A)
    static let fog = Color(hex: 0x8B9398)
    static let alert = Color(hex: 0xFF5C5C)

    static let inkNS = NSColor(srgbRed: 0x1A / 255, green: 0x1D / 255, blue: 0x21 / 255, alpha: 1)
    static let mintNS = NSColor(srgbRed: 0x3D / 255, green: 0xFF / 255, blue: 0xB5 / 255, alpha: 1)
    static let paperNS = NSColor(srgbRed: 0xF3 / 255, green: 0xF5 / 255, blue: 0xF4 / 255, alpha: 1)
    static let fogNS = NSColor(srgbRed: 0x8B / 255, green: 0x93 / 255, blue: 0x98 / 255, alpha: 1)
    static let alertNS = NSColor(srgbRed: 0xFF / 255, green: 0x5C / 255, blue: 0x5C / 255, alpha: 1)
}

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8) & 0xFF) / 255
        let b = Double(hex & 0xFF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: opacity)
    }
}
