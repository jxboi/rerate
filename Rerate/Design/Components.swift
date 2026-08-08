import SwiftUI

// MARK: - Rules

struct Hairline: View {
    var inset: CGFloat = 0
    var strong: Bool = false

    var body: some View {
        Rectangle()
            .fill(strong ? Palette.hairlineStrong : Palette.hairline)
            .frame(height: 1 / UIScreen.main.scale)
            .padding(.leading, inset)
    }
}

// MARK: - Judgement pill

/// The core vocabulary element. Text carries the meaning; the tone only tints it.
struct TonePill: View {
    let text: String
    let tone: Tone
    var filled: Bool = true

    var body: some View {
        Text(text)
            .font(Type.micro)
            .foregroundStyle(tone.color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule(style: .continuous)
                    .fill(filled ? tone.soft : .clear)
            )
            .overlay(
                Capsule(style: .continuous)
                    .strokeBorder(filled ? .clear : tone.color.opacity(0.35), lineWidth: 1)
            )
    }
}

/// A tiny mark that reads at a glance in a list without shouting.
struct ToneDot: View {
    let tone: Tone
    var size: CGFloat = 6

    var body: some View {
        Circle()
            .fill(tone.color)
            .frame(width: size, height: size)
    }
}

// MARK: - Dimension readout

/// `Business — Strong`. Used on the position header and in list rows.
struct DimensionReadout: View {
    let label: String
    let value: String
    let tone: Tone
    var emphasised: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label).sectionLabelStyle()
            HStack(spacing: 6) {
                if emphasised { ToneDot(tone: tone) }
                Text(value)
                    .font(emphasised ? Type.title : Type.bodyMedium)
                    .foregroundStyle(tone == .neutral ? Palette.ink : tone.color)
            }
        }
    }
}

// MARK: - Surfaces

struct Card<Content: View>: View {
    var padding: CGFloat = 18
    var radius: CGFloat = 18
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(Palette.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(Palette.hairline, lineWidth: 1)
            )
    }
}

/// Quiet inset block for supporting detail — evidence, footnotes, caveats.
struct Inset<Content: View>: View {
    var tone: Tone = .neutral
    @ViewBuilder var content: Content

    var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(tone == .neutral ? Palette.surfaceSunken : tone.soft)
            )
    }
}

// MARK: - Rows

/// `ROE            17.9%` with an optional change trailing it.
struct MetricRow: View {
    let name: String
    let value: String
    var was: String?
    var tone: Tone = .neutral
    var note: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(name)
                    .font(Type.body)
                    .foregroundStyle(Palette.ink)
                Spacer(minLength: 8)
                if let was {
                    Text(was)
                        .font(Type.mono(14))
                        .foregroundStyle(Palette.inkTertiary)
                        .strikethrough(false)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(Palette.inkQuaternary)
                }
                Text(value)
                    .font(Type.mono(15, .medium))
                    .foregroundStyle(tone == .neutral ? Palette.ink : tone.color)
            }
            if let note {
                Text(note)
                    .font(Type.caption)
                    .foregroundStyle(Palette.inkTertiary)
            }
        }
        .padding(.vertical, 9)
    }
}

// MARK: - Disclosure

/// Progressive disclosure that expands in place with a spring rather than
/// pushing a new screen. Used for "why does this matter" detail everywhere.
struct Unfold<Label: View, Content: View>: View {
    @State private var open = false
    @ViewBuilder var label: Label
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(Motion.gentle) { open.toggle() }
                Haptic.soft()
            } label: {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    label
                    Spacer(minLength: 8)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Palette.inkTertiary)
                        .rotationEffect(.degrees(open ? 0 : -90))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.pressable(scale: 0.99))

            if open {
                content
                    .padding(.top, 12)
                    .transition(
                        .asymmetric(
                            insertion: .opacity.combined(with: .offset(y: -6)),
                            removal: .opacity
                        )
                    )
            }
        }
        .clipped()
    }
}

// MARK: - Navigation chrome

/// A large serif screen title that settles under the nav bar.
struct ScreenTitle: View {
    let title: String
    var subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(Type.statement)
                .foregroundStyle(Palette.ink)
            if let subtitle {
                Text(subtitle)
                    .font(Type.callout)
                    .foregroundStyle(Palette.inkSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// The primary action treatment. There is at most one per screen.
struct PrimaryAction: View {
    let title: String
    var icon: String?
    let action: () -> Void

    var body: some View {
        Button(action: {
            Haptic.firm()
            action()
        }) {
            HStack(spacing: 8) {
                if let icon {
                    Image(systemName: icon).font(.system(size: 14, weight: .semibold))
                }
                Text(title).font(Type.bodyMedium)
            }
            .foregroundStyle(Palette.canvas)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Palette.ink)
            )
        }
        .buttonStyle(.pressable(scale: 0.975))
    }
}

struct SecondaryAction: View {
    let title: String
    var icon: String?
    let action: () -> Void

    var body: some View {
        Button(action: {
            Haptic.tap()
            action()
        }) {
            HStack(spacing: 8) {
                if let icon {
                    Image(systemName: icon).font(.system(size: 13, weight: .semibold))
                }
                Text(title).font(Type.bodyMedium)
            }
            .foregroundStyle(Palette.ink)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Palette.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Palette.hairlineStrong, lineWidth: 1)
            )
        }
        .buttonStyle(.pressable(scale: 0.98))
    }
}

// MARK: - Confidence

/// Rerate states how much it trusts each claim. This is deliberately visible
/// rather than buried, because an unsupported explanation is worse than none.
struct ConfidenceMark: View {
    let level: Confidence

    var body: some View {
        HStack(spacing: 5) {
            HStack(spacing: 2) {
                ForEach(0..<3) { i in
                    Capsule()
                        .fill(i < level.bars ? Palette.inkSecondary : Palette.inkQuaternary)
                        .frame(width: 9, height: 3)
                }
            }
            Text(level.label)
                .font(Type.micro)
                .foregroundStyle(Palette.inkTertiary)
        }
    }
}

enum Confidence: String, Codable {
    case strong, moderate, weak

    var bars: Int {
        switch self {
        case .strong: 3
        case .moderate: 2
        case .weak: 1
        }
    }

    var label: String {
        switch self {
        case .strong: "Well supported"
        case .moderate: "Partly supported"
        case .weak: "Thin evidence"
        }
    }
}

/// Labels a passage as fact, reading, or opinion. Used across Review and
/// Explain the Move so the user always knows which they are looking at.
enum ClaimKind: String {
    case evidence = "Evidence"
    case interpretation = "Interpretation"
    case uncertainty = "Uncertain"

    var icon: String {
        switch self {
        case .evidence: "circle.fill"
        case .interpretation: "circle.lefthalf.filled"
        case .uncertainty: "circle.dotted"
        }
    }

    var tint: Color {
        switch self {
        case .evidence: Palette.ink
        case .interpretation: Palette.inkSecondary
        case .uncertainty: Palette.caution
        }
    }
}

struct ClaimTag: View {
    let kind: ClaimKind

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: kind.icon)
                .font(.system(size: 7))
            Text(kind.rawValue)
                .font(Type.micro)
        }
        .foregroundStyle(kind.tint)
        .opacity(0.85)
    }
}
