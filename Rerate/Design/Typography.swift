import SwiftUI

// Two families do all the work.
//
//   New York (serif) — statements, headline numbers, anything the user is meant
//                      to slow down and read. It gives the app the feeling of a
//                      research note rather than a terminal.
//   SF Pro          — labels, controls, dense figures. Gets out of the way.

enum Type {
    // Serif voice
    static func display(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }

    static let hero = display(46, .regular)
    static let statement = display(26, .regular)
    static let title = display(21, .medium)
    static let quote = display(17, .regular)

    // Sans voice
    static let sectionLabel = Font.system(size: 11, weight: .semibold)
    static let body = Font.system(size: 15.5, weight: .regular)
    static let bodyMedium = Font.system(size: 15.5, weight: .medium)
    static let callout = Font.system(size: 14, weight: .regular)
    static let caption = Font.system(size: 12.5, weight: .regular)
    static let micro = Font.system(size: 11, weight: .medium)

    // Figures
    static func figure(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .serif).monospacedDigit()
    }

    static func mono(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight).monospacedDigit()
    }
}

extension View {
    /// Small tracked-out uppercase label. The only place we use letterspacing.
    func sectionLabelStyle(_ color: Color = Palette.inkTertiary) -> some View {
        self.font(Type.sectionLabel)
            .tracking(0.9)
            .textCase(.uppercase)
            .foregroundStyle(color)
    }

    /// Serif body copy with generous leading — used for the written analysis.
    func proseStyle() -> some View {
        self.font(Type.quote)
            .foregroundStyle(Palette.ink)
            .lineSpacing(6)
    }
}

struct SectionLabel: View {
    let text: String
    var trailing: String?

    init(_ text: String, trailing: String? = nil) {
        self.text = text
        self.trailing = trailing
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(text).sectionLabelStyle()
            Spacer(minLength: 12)
            if let trailing {
                Text(trailing)
                    .font(Type.micro)
                    .foregroundStyle(Palette.inkTertiary)
            }
        }
    }
}
