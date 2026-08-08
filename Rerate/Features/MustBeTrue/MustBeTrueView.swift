import SwiftUI

struct MustBeTrueView: View {
    @Environment(Store.self) private var store
    let holdingID: UUID

    @State private var values: [Double] = []
    @State private var activeScenario: String?
    @State private var appeared = false
    @State private var editing = false

    private var h: Holding { store.holding(holdingID) ?? SeedDBS.holding }
    private var levers: [ValuationLever] { ValuationEngine.levers(for: h) }

    private var impliedMultiple: Double {
        ValuationEngine.multiple(kind: h.kind, values: values)
    }

    private var impliedPrice: Double {
        impliedMultiple * h.anchorPerShare
    }

    /// What the current price demands of the primary assumption, holding the
    /// other two where the user has them.
    private var priceRequires: Double {
        ValuationEngine.impliedPrimary(kind: h.kind, multiple: h.multiple, values: values)
    }

    private var scenarioPrices: [(name: String, price: Double)] {
        h.scenarios.map { s in
            let v = ValuationEngine.levers(from: s, kind: h.kind)
            return (shortName(s.name), ValuationEngine.multiple(kind: h.kind, values: v) * h.anchorPerShare)
        }
    }

    /// The scale is narrow; scenario names have to fit under their own tick.
    private func shortName(_ name: String) -> String {
        switch name {
        case "Exceptional compounder": "Exceptional"
        case "Strong franchise": "Strong franchise"
        case "Continued improvement": "Improving"
        case "Sustained execution": "Sustained"
        case "Rates stay high for longer": "Rates high"
        case "Cost of debt plateaus": "Plateau"
        case "Rates fall": "Rates fall"
        case "Re-rating toward peers": "Re-rating"
        case "Recovery stalls": "Stalls"
        case "Target achieved": "Target met"
        case "Re-rated as an infrastructure owner": "Re-rated"
        case "Growth fades": "Fades"
        default: name
        }
    }

    private var domain: ClosedRange<Double> {
        let prices = scenarioPrices.map(\.price) + [h.price]
        let lo = (prices.min() ?? 10) * 0.72
        let hi = (prices.max() ?? 100) * 1.22
        return lo...max(hi, lo + 1)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                hero
                impliedHeadline
                scale
                sliders
                scenarioSection
                caveat
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 48)
        }
        .background(Palette.canvas)
        .scrollIndicators(.hidden)
        .scrollDisabled(editing)
        .navigationTitle("What must be true?")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if values.isEmpty { values = levers.map(\.defaultValue) }
            withAnimation(Motion.gentle) { appeared = true }
        }
    }

    // MARK: Hero

    private var hero: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("What must be true for \(Fmt.money(h.price, currency: h.currency)) to make sense?")
                .font(Type.statement)
                .foregroundStyle(Palette.ink)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 8)

            Text("Every price is a set of assumptions. Move them and watch what today's price is already asking for.")
                .font(Type.callout)
                .foregroundStyle(Palette.inkSecondary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 8)
    }

    // MARK: The implied requirement

    private var impliedHeadline: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionLabel("At today's price the market is betting on")
                .padding(.bottom, 12)

            HStack(alignment: .firstTextBaseline, spacing: 10) {
                AnimatedFigure(priceRequires * 100, font: Type.figure(40), color: Palette.ink) {
                    Fmt.percent($0, places: 1)
                }
                Text(primaryLabel)
                    .font(Type.callout)
                    .foregroundStyle(Palette.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let ref = levers.first?.reference, ValuationEngine.usesEquityModel(h.kind) {
                Text(comparison(implied: priceRequires, today: ref.value))
                    .font(Type.callout)
                    .foregroundStyle(Palette.inkSecondary)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 14)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Palette.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Palette.hairline, lineWidth: 1)
        )
        .padding(.top, 30)
    }

    private var primaryLabel: String {
        ValuationEngine.usesEquityModel(h.kind)
            ? "sustained \(levers.first?.name.lowercased() ?? "return")"
            : "sustained earnings growth"
    }

    private func comparison(implied: Double, today: Double) -> String {
        let gap = implied - today
        if gap > 0.008 {
            return "That is above the \(Fmt.percent(today * 100)) the business earns today, and it has to hold indefinitely — not for a good year, but through whatever comes next."
        }
        if gap < -0.008 {
            return "That is below the \(Fmt.percent(today * 100)) the business earns today. On these assumptions the price is asking for less than the company is currently delivering."
        }
        return "That is roughly what the business earns today — the price assumes the present continues, without improving."
    }

    // MARK: Scale

    private var scale: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                SectionLabel("On your assumptions")
                Spacer()
                AnimatedFigure(impliedMultiple, font: Type.mono(13, .medium), color: Palette.inkSecondary) {
                    Fmt.multiple($0) + " " + h.kind.valuationAnchor
                }
            }

            ValuationScale(
                domain: domain,
                todaysPrice: h.price,
                implied: impliedPrice,
                currency: h.currency,
                scenarios: scenarioPrices
            )

            Text(gapNarrative)
                .font(Type.quote)
                .foregroundStyle(Palette.ink)
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 34)
    }

    private var gapNarrative: String {
        let ratio = impliedPrice / h.price
        switch ratio {
        case ..<0.75:
            return "On these assumptions the price would be well below where it trades. The market is either seeing something these numbers do not capture, or paying for optimism."
        case 0.75..<0.93:
            return "On these assumptions the price sits somewhat above what the model supports. The gap is the part you are taking on trust."
        case 0.93..<1.08:
            return "On these assumptions the price is roughly where the model puts it. This is close to what the market appears to be assuming."
        case 1.08..<1.35:
            return "On these assumptions the price would be somewhat higher than it is. The market is asking for less than you are."
        default:
            return "On these assumptions the price would be far higher than it is. Assumptions this favourable are worth testing against the bear case before relying on them."
        }
    }

    // MARK: Sliders

    private var sliders: some View {
        VStack(alignment: .leading, spacing: 30) {
            SectionLabel("The assumptions")
            ForEach(Array(levers.enumerated()), id: \.element.id) { i, lever in
                if i < values.count {
                    VStack(alignment: .leading, spacing: 10) {
                        AssumptionSlider(
                            lever: lever,
                            value: Binding(
                                get: { values[i] },
                                set: { newValue in
                                    values[i] = newValue
                                    if activeScenario != nil { activeScenario = nil }
                                }
                            ),
                            onEditingChanged: { editing = $0 }
                        )
                        Text(lever.detail)
                            .font(Type.caption)
                            .foregroundStyle(Palette.inkTertiary)
                            .lineSpacing(3)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .padding(.top, 40)
    }

    // MARK: Scenarios

    private var scenarioSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionLabel("Or start from a scenario")
                .padding(.bottom, 12)

            HStack(spacing: 8) {
                ForEach(h.scenarios) { s in
                    Button {
                        Haptic.firm()
                        withAnimation(Motion.gentle) {
                            values = ValuationEngine.levers(from: s, kind: h.kind)
                            activeScenario = s.name
                        }
                    } label: {
                        Text(s.name)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(activeScenario == s.name ? Palette.canvas : Palette.inkSecondary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 11)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(activeScenario == s.name ? Palette.ink : Palette.surfaceSunken)
                            )
                    }
                    .buttonStyle(.pressable(scale: 0.96, haptic: false))
                }
            }

            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(h.scenarios.enumerated()), id: \.element.id) { i, s in
                    if i > 0 { Hairline().padding(.vertical, 2) }
                    scenarioRow(s)
                }
            }
            .padding(.top, 22)
        }
        .padding(.top, 44)
    }

    private func scenarioRow(_ s: Scenario) -> some View {
        let v = ValuationEngine.levers(from: s, kind: h.kind)
        let price = ValuationEngine.multiple(kind: h.kind, values: v) * h.anchorPerShare
        return Unfold {
            VStack(alignment: .leading, spacing: 7) {
                HStack(alignment: .firstTextBaseline) {
                    Text(s.name)
                        .font(Type.bodyMedium)
                        .foregroundStyle(Palette.ink)
                    Spacer(minLength: 8)
                    Text(Fmt.price(price, currency: h.currency))
                        .font(Type.mono(15, .medium))
                        .foregroundStyle(price >= h.price ? Palette.ink : Palette.inkSecondary)
                }
                Text(s.premise)
                    .font(Type.caption)
                    .foregroundStyle(Palette.inkTertiary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical, 14)
        } content: {
            VStack(alignment: .leading, spacing: 14) {
                Text(s.reasoning)
                    .font(Type.callout)
                    .foregroundStyle(Palette.inkSecondary)
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(alignment: .leading, spacing: 8) {
                    Text("What would have to happen")
                        .sectionLabelStyle()
                    ForEach(s.whatWouldMakeItTrue, id: \.self) { item in
                        HStack(alignment: .top, spacing: 8) {
                            Circle()
                                .fill(Palette.inkQuaternary)
                                .frame(width: 4, height: 4)
                                .padding(.top, 7)
                            Text(item)
                                .font(Type.caption)
                                .foregroundStyle(Palette.inkSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
            .padding(.bottom, 16)
        }
    }

    // MARK: Caveat

    private var caveat: some View {
        Inset(tone: .neutral) {
            VStack(alignment: .leading, spacing: 8) {
                Text("This is not a fair value")
                    .font(Type.bodyMedium)
                    .foregroundStyle(Palette.ink)
                Text("A single number here would be false precision. Small changes in the required return move the result a long way, which is exactly why the range matters more than any point inside it.\n\nWhat this screen is for is the reverse question: given what the market is paying, what is it assuming? That question has a much more stable answer.")
                    .font(Type.caption)
                    .foregroundStyle(Palette.inkSecondary)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.top, 40)
    }
}
