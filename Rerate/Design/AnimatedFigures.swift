import SwiftUI

/// Text that interpolates its *value* rather than cross-fading between strings.
/// Driving `animatableData` means the number genuinely counts through every
/// intermediate value, which is what makes a slider feel connected to a figure.
struct AnimatedFigure: View, Animatable {
    var value: Double
    var format: (Double) -> String
    var font: Font
    var color: Color

    init(
        _ value: Double,
        font: Font = Type.figure(28),
        color: Color = Palette.ink,
        format: @escaping (Double) -> String
    ) {
        self.value = value
        self.font = font
        self.color = color
        self.format = format
    }

    var animatableData: Double {
        get { value }
        set { value = newValue }
    }

    var body: some View {
        Text(format(value))
            .font(font)
            .foregroundStyle(color)
            .monospacedDigit()
    }
}

/// A figure that rolls its digits when it changes discretely (tab switches,
/// new data arriving). Uses the system numeric content transition.
struct RollingFigure: View {
    let value: Double
    var font: Font = Type.figure(28)
    var color: Color = Palette.ink
    var format: (Double) -> String

    var body: some View {
        Text(format(value))
            .font(font)
            .foregroundStyle(color)
            .monospacedDigit()
            .contentTransition(.numericText(value: value))
            .animation(Motion.gentle, value: value)
    }
}

// MARK: - Formatting

enum Fmt {
    static func money(_ v: Double, currency: String = "S$", places: Int = 2) -> String {
        currency + String(format: "%.\(places)f", v)
    }

    /// Decimals chosen by magnitude — "S$66" reads well, "S$3" does not.
    static func price(_ v: Double, currency: String = "S$") -> String {
        money(v, currency: currency, places: abs(v) < 20 ? 2 : 0)
    }

    static func plain(_ v: Double, places: Int = 2) -> String {
        String(format: "%.\(places)f", v)
    }

    static func percent(_ v: Double, places: Int = 1, signed: Bool = false) -> String {
        let s = String(format: "%.\(places)f", abs(v))
        if signed { return (v < 0 ? "−" : "+") + s + "%" }
        return (v < 0 ? "−" : "") + s + "%"
    }

    static func multiple(_ v: Double, places: Int = 2) -> String {
        String(format: "%.\(places)f", v) + "×"
    }

    /// Large money amounts: S$396b, S$2.1b, S$740m
    static func compact(_ v: Double, currency: String = "S$") -> String {
        let a = abs(v)
        switch a {
        case 1_000_000_000...:
            return currency + String(format: "%.1f", v / 1_000_000_000) + "b"
        case 1_000_000...:
            return currency + String(format: "%.0f", v / 1_000_000) + "m"
        default:
            return currency + String(format: "%.0f", v)
        }
    }

    /// "8 months", "2 years", "2.4 years" — never "2.0 years".
    static func duration(since date: Date) -> String {
        let months = Calendar.current.dateComponents([.month], from: date, to: Date()).month ?? 0
        if months < 18 { return "\(months) months" }
        let years = Double(months) / 12
        return years.truncatingRemainder(dividingBy: 1) < 0.08
            ? "\(Int(years.rounded())) years"
            : String(format: "%.1f years", years)
    }

    static let monthYear: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f
    }()

    static let shortDate: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "d MMM yyyy"
        return f
    }()

    static let compactDate: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM yyyy"
        return f
    }()
}
