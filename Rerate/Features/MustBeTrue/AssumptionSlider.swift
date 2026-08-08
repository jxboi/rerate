import SwiftUI

/// A slider built by hand so it can carry reference marks, feel weighted, and
/// give a detent every step without the system control's visual noise.
struct AssumptionSlider: View {
    let lever: ValuationLever
    @Binding var value: Double
    var onEditingChanged: (Bool) -> Void = { _ in }

    @State private var dragging = false
    @State private var lastDetent: Double = .nan

    private let knob: CGFloat = 27
    private let track: CGFloat = 5

    private var fraction: Double {
        let span = lever.range.upperBound - lever.range.lowerBound
        guard span > 0 else { return 0 }
        return min(max((value - lever.range.lowerBound) / span, 0), 1)
    }

    private func fraction(of v: Double) -> Double {
        let span = lever.range.upperBound - lever.range.lowerBound
        guard span > 0 else { return 0 }
        return min(max((v - lever.range.lowerBound) / span, 0), 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text(lever.name)
                    .font(Type.body)
                    .foregroundStyle(Palette.ink)
                Spacer(minLength: 8)
                AnimatedFigure(value, font: Type.figure(20, .medium), color: Palette.ink) {
                    lever.format($0)
                }
                .scaleEffect(dragging ? 1.06 : 1, anchor: .trailing)
                .animation(Motion.crisp, value: dragging)
            }

            GeometryReader { geo in
                let usable = geo.size.width - knob
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Palette.surfaceSunken)
                        .frame(height: track)
                        .overlay(
                            Capsule().strokeBorder(Palette.hairline, lineWidth: 1)
                        )

                    Capsule()
                        .fill(Palette.ink.opacity(0.85))
                        .frame(width: knob / 2 + usable * fraction, height: track)

                    // Reference marks sit on the track itself, so the user can
                    // see where "today" and "history" are without a legend.
                    ForEach(marks, id: \.0) { markValue, _ in
                        Capsule()
                            .fill(Palette.inkQuaternary)
                            .frame(width: 2, height: 13)
                            .offset(x: knob / 2 + usable * fraction(of: markValue) - 1)
                    }

                    Circle()
                        .fill(Palette.surface)
                        .frame(width: knob, height: knob)
                        .overlay(Circle().strokeBorder(Palette.hairlineStrong, lineWidth: 1))
                        .shadow(color: .black.opacity(dragging ? 0.13 : 0.07), radius: dragging ? 7 : 3, y: 2)
                        .scaleEffect(dragging ? 1.12 : 1)
                        .offset(x: usable * fraction)
                        .animation(Motion.crisp, value: dragging)
                }
                .frame(height: knob)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { g in
                            if !dragging {
                                dragging = true
                                Haptic.prepare()
                                onEditingChanged(true)
                            }
                            let raw = (g.location.x - knob / 2) / max(usable, 1)
                            let span = lever.range.upperBound - lever.range.lowerBound
                            let unclamped = lever.range.lowerBound + Double(min(max(raw, 0), 1)) * span
                            let snapped = (unclamped / lever.step).rounded() * lever.step
                            let clamped = min(max(snapped, lever.range.lowerBound), lever.range.upperBound)
                            if clamped != value {
                                value = clamped
                                if lastDetent.isNaN || abs(clamped - lastDetent) >= lever.step - 1e-9 {
                                    Haptic.detent()
                                    lastDetent = clamped
                                }
                            }
                        }
                        .onEnded { _ in
                            dragging = false
                            lastDetent = .nan
                            onEditingChanged(false)
                        }
                )
            }
            .frame(height: knob)

            // Mark labels sit under their own tick, not spread evenly, so the
            // track reads as a real scale rather than a legend.
            GeometryReader { geo in
                ZStack(alignment: .topLeading) {
                    Text(lever.format(lever.range.lowerBound))
                        .font(Type.micro)
                        .foregroundStyle(Palette.inkQuaternary)
                    Text(lever.format(lever.range.upperBound))
                        .font(Type.micro)
                        .foregroundStyle(Palette.inkQuaternary)
                        .frame(width: 60, alignment: .trailing)
                        .offset(x: geo.size.width - 60)

                    ForEach(marks, id: \.0) { markValue, label in
                        Text(label)
                            .font(Type.micro)
                            .foregroundStyle(Palette.inkTertiary)
                            .lineLimit(1)
                            .fixedSize()
                            .frame(width: 96)
                            .offset(x: markLabelX(markValue, in: geo.size.width))
                    }
                }
            }
            .frame(height: 14)
        }
    }

    /// Centres a 96pt label on its tick, kept clear of the end labels.
    private func markLabelX(_ value: Double, in width: CGFloat) -> CGFloat {
        let usable = width - knob
        let centre = knob / 2 + usable * CGFloat(fraction(of: value))
        let leading = centre - 48
        return min(max(leading, 34), max(width - 130, 34))
    }

    private var marks: [(Double, String)] {
        var out: [(Double, String)] = []
        if let r = lever.reference { out.append((r.value, r.label)) }
        if let hst = lever.history { out.append((hst.value, hst.label)) }
        return out
    }
}

/// Where an implied value sits relative to today's price and the three
/// scenarios. Both markers move on a fixed scale so the comparison holds still
/// while the assumptions change underneath it.
struct ValuationScale: View {
    let domain: ClosedRange<Double>
    let todaysPrice: Double
    let implied: Double
    let currency: String
    let scenarios: [(name: String, price: Double)]

    private func x(_ v: Double, width: CGFloat) -> CGFloat {
        let span = domain.upperBound - domain.lowerBound
        guard span > 0 else { return 0 }
        return width * CGFloat(min(max((v - domain.lowerBound) / span, 0), 1))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            GeometryReader { geo in
                let w = geo.size.width
                ZStack(alignment: .topLeading) {
                    Capsule()
                        .fill(Palette.surfaceSunken)
                        .frame(height: 4)
                        .offset(y: 20)

                    // Scenario ticks
                    ForEach(scenarios, id: \.name) { s in
                        Capsule()
                            .fill(Palette.inkQuaternary)
                            .frame(width: 1.5, height: 12)
                            .offset(x: x(s.price, width: w) - 0.75, y: 16)
                    }

                    // Today's price — the fixed point of comparison
                    VStack(spacing: 3) {
                        Text("Today")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(Palette.inkTertiary)
                        Capsule()
                            .fill(Palette.inkSecondary)
                            .frame(width: 2, height: 18)
                    }
                    .frame(width: 60)
                    .offset(x: x(todaysPrice, width: w) - 30, y: 0)

                    // The implied value, driven by the sliders
                    VStack(spacing: 3) {
                        Capsule()
                            .fill(Palette.accent)
                            .frame(width: 3, height: 22)
                        AnimatedFigure(implied, font: Type.figure(14, .medium), color: Palette.accent) {
                            Fmt.price($0, currency: currency)
                        }
                    }
                    .frame(width: 74)
                    .offset(x: x(implied, width: w) - 37, y: 22)
                }
            }
            .frame(height: 78)

            // Scenario names line up with their own ticks above.
            GeometryReader { geo in
                ZStack(alignment: .topLeading) {
                    ForEach(scenarios, id: \.name) { s in
                        Text(s.name)
                            .font(.system(size: 9.5, weight: .medium))
                            .foregroundStyle(Palette.inkTertiary)
                            .multilineTextAlignment(.center)
                            .frame(width: 92)
                            .offset(x: min(max(x(s.price, width: geo.size.width) - 46, -8), geo.size.width - 84))
                    }
                }
            }
            .frame(height: 26)
        }
    }
}
