import SwiftUI

// The palette is deliberately warm and desaturated. Nothing in Rerate should
// read as a trading screen: no saturated reds and greens, no glow, no alarm.
// Judgement is carried by typography and language first, colour only second.

extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }

    init(light: UInt32, dark: UInt32) {
        self.init(UIColor { trait in
            UIColor(Color(hex: trait.userInterfaceStyle == .dark ? dark : light))
        })
    }
}

enum Palette {
    // Surfaces — warm paper in light, warm charcoal in dark.
    static let canvas = Color(light: 0xFAF9F6, dark: 0x0F0F0E)
    static let surface = Color(light: 0xFFFFFF, dark: 0x1A1917)
    static let surfaceSunken = Color(light: 0xF2F0EA, dark: 0x161514)

    // Ink
    static let ink = Color(light: 0x1B1A17, dark: 0xF4F1EA)
    static let inkSecondary = Color(light: 0x6E6A62, dark: 0xA29D93)
    static let inkTertiary = Color(light: 0x9C978D, dark: 0x716D65)
    static let inkQuaternary = Color(light: 0xC3BEB4, dark: 0x4A4741)

    static let hairline = Color(light: 0xE7E3DA, dark: 0x2B2A26)
    static let hairlineStrong = Color(light: 0xD6D1C6, dark: 0x3A3833)

    // Accent — a deep ink blue. Used sparingly, mostly for interaction.
    static let accent = Color(light: 0x2E4A6D, dark: 0x7A93B8)
    static let accentSoft = Color(light: 0xE8EDF4, dark: 0x1E2A38)

    // Judgement tones. Muted on purpose.
    static let affirm = Color(light: 0x4A6F52, dark: 0x82A88A)     // holding up
    static let affirmSoft = Color(light: 0xEAF0EA, dark: 0x1B2620)
    static let caution = Color(light: 0x8F6B1E, dark: 0xC9A050)    // worth watching
    static let cautionSoft = Color(light: 0xF6EFDF, dark: 0x2A2417)
    static let breach = Color(light: 0x9C4B36, dark: 0xC98069)     // no longer true
    static let breachSoft = Color(light: 0xF6E9E4, dark: 0x2C1D18)

    static let neutralSoft = Color(light: 0xF0EEE8, dark: 0x232220)
}

/// Every qualitative judgement in the app resolves to one of four tones.
/// Keeping the vocabulary this small is what stops the UI turning into a dashboard.
enum Tone {
    case affirm
    case neutral
    case caution
    case breach

    var color: Color {
        switch self {
        case .affirm: Palette.affirm
        case .neutral: Palette.inkSecondary
        case .caution: Palette.caution
        case .breach: Palette.breach
        }
    }

    var soft: Color {
        switch self {
        case .affirm: Palette.affirmSoft
        case .neutral: Palette.neutralSoft
        case .caution: Palette.cautionSoft
        case .breach: Palette.breachSoft
        }
    }
}
