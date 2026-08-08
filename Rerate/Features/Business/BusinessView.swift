import SwiftUI

/// The analysis adapts to the business. A bank is read on returns, margin, fee
/// mix, credit and capital; a REIT on occupancy, distributions, gearing and the
/// cost of its debt. Showing a REIT's "net interest margin" would be as useless
/// as showing a bank's occupancy.
struct BusinessView: View {
    @Environment(Store.self) private var store
    let holdingID: UUID
    @State private var basis: Basis = .purchase
    @State private var appeared = false

    enum Basis: String, CaseIterable {
        case purchase = "Since purchase"
        case review = "Since last review"
    }

    private var h: Holding { store.holding(holdingID) ?? SeedDBS.holding }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header
                basisPicker
                groups
                footnote
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 48)
        }
        .background(Palette.canvas)
        .scrollIndicators(.hidden)
        .navigationTitle("Business")
        .navigationBarTitleDisplayMode(.inline)
        .task { withAnimation(Motion.gentle) { appeared = true } }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(h.business.rawValue)
                    .font(Type.statement)
                    .foregroundStyle(h.business.tone == .neutral ? Palette.ink : h.business.tone.color)
                Text("· \(h.kind.label)")
                    .font(Type.callout)
                    .foregroundStyle(Palette.inkTertiary)
            }
            .padding(.top, 8)

            Text(narrative)
                .font(Type.quote)
                .foregroundStyle(Palette.inkSecondary)
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 8)
    }

    private var narrative: String {
        let lead: String
        switch h.business {
        case .strong: lead = "The operating figures are better than when you bought, across most of what matters for a \(h.kind.prose)."
        case .stable: lead = "The operating figures are broadly where they were when you bought."
        case .softening: lead = "Parts of the business are under pressure. The figures below show where, and where they are not."
        case .weak: lead = "The operating figures have deteriorated since your purchase."
        }
        return lead + " These are the measures that actually drive a \(h.kind.prose) — not a generic set applied to every company."
    }

    private var basisPicker: some View {
        HStack(spacing: 0) {
            ForEach(Basis.allCases, id: \.rawValue) { b in
                Button {
                    Haptic.detent()
                    withAnimation(Motion.gentle) { basis = b }
                } label: {
                    Text(b.rawValue)
                        .font(.system(size: 12.5, weight: .medium))
                        .foregroundStyle(basis == b ? Palette.ink : Palette.inkTertiary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background {
                            if basis == b {
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(Palette.surface)
                                    .shadow(color: .black.opacity(0.05), radius: 3, y: 1)
                            }
                        }
                }
                .buttonStyle(.pressable(scale: 0.99, haptic: false))
            }
        }
        .padding(3)
        .background(RoundedRectangle(cornerRadius: 13, style: .continuous).fill(Palette.surfaceSunken))
        .padding(.top, 28)
    }

    private var groups: some View {
        VStack(alignment: .leading, spacing: 30) {
            ForEach(MetricGrouping.groups(for: h), id: \.name) { group in
                VStack(alignment: .leading, spacing: 0) {
                    SectionLabel(group.name).padding(.bottom, 2)
                    ForEach(Array(group.metrics.enumerated()), id: \.element.id) { i, metric in
                        if i > 0 { Hairline() }
                        MetricRow(
                            name: metric.name,
                            value: metric.display,
                            was: basis == .purchase ? metric.displayAtPurchase : metric.displayAtLastReview,
                            tone: tone(for: metric),
                            note: metric.note
                        )
                    }
                }
            }
        }
        .padding(.top, 32)
    }

    private func tone(for metric: Metric) -> Tone {
        let reference = basis == .purchase ? metric.atPurchase : metric.atLastReview
        let delta = metric.value - reference
        guard abs(delta) > abs(reference) * 0.004 else { return .neutral }
        let improving = metric.direction == .higherIsBetter ? delta > 0 : delta < 0
        return improving ? .affirm : .caution
    }

    private var footnote: some View {
        Text("Colour marks the direction of travel for an owner, not whether a figure is good in absolute terms. Figures are illustrative.")
            .font(Type.micro)
            .foregroundStyle(Palette.inkQuaternary)
            .lineSpacing(3)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.top, 34)
    }
}

enum MetricGrouping {
    struct Group {
        var name: String
        var metrics: [Metric]
    }

    private static func definitions(for kind: BusinessKind) -> [(String, [String])] {
        switch kind {
        case .bank:
            [
                ("Profitability", ["Return on equity", "Net interest margin", "Cost to income"]),
                ("Income mix", ["Fee income growth", "Wealth management AUM"]),
                ("Risk and capital", ["Non-performing loans", "CET1 capital ratio"]),
                ("Per share", ["Book value per share", "Earnings per share", "Dividend per share"]),
                ("Valuation", ["Dividend yield", "Price to book"])
            ]
        case .reit:
            [
                ("The properties", ["Portfolio occupancy", "Net property income growth"]),
                ("Distributions", ["Distribution per unit", "Distribution yield"]),
                ("Financing", ["Aggregate leverage", "Average cost of debt", "Interest coverage"]),
                ("Valuation", ["Net asset value per unit", "Price to NAV"])
            ]
        case .telecom, .industrial:
            [
                ("Profitability", ["EBIT margin", "Return on invested capital"]),
                ("Cash generation", ["Earnings per share", "Free cash flow per share"]),
                ("Balance sheet", ["Net debt to EBITDA"]),
                ("Valuation", ["Dividend yield", "Price to earnings"])
            ]
        case .matureTech:
            [
                ("Profitability", ["Operating margin", "Return on invested capital"]),
                ("Cash generation", ["Earnings per share", "Free cash flow per share"]),
                ("Growth", ["Revenue growth"]),
                ("Valuation", ["Price to earnings", "Price to free cash flow"])
            ]
        }
    }

    static func groups(for h: Holding) -> [Group] {
        var used = Set<UUID>()
        var out: [Group] = []
        for (name, names) in definitions(for: h.kind) {
            let metrics = names.compactMap { n in h.metrics.first { $0.name == n } }
            guard !metrics.isEmpty else { continue }
            metrics.forEach { used.insert($0.id) }
            out.append(Group(name: name, metrics: metrics))
        }
        let leftovers = h.metrics.filter { !used.contains($0.id) }
        if !leftovers.isEmpty {
            out.append(Group(name: "Also tracked", metrics: leftovers))
        }
        return out
    }
}
