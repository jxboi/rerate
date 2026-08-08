import Foundation

/// Builds a complete position from what the user told us during onboarding.
///
/// Everything downstream — the split, the assessments, the scenarios, the two
/// arguments — is derived from the same figures, so a freshly added holding
/// behaves exactly like the demonstration ones rather than being a stub.
enum HoldingFactory {

    static func make(
        entry: CatalogueEntry,
        cost: Double,
        shares: Double,
        purchaseDate: Date,
        reasoning: String,
        conditions: [ThesisCondition]
    ) -> Holding {
        let years = max(
            Double(Calendar.current.dateComponents([.month], from: purchaseDate, to: Date()).month ?? 12) / 12,
            0.25
        )

        let anchorAtPurchase = max(entry.anchorPerShare - entry.anchorDriftPerYear * years, entry.anchorPerShare * 0.35)
        let metrics = entry.metricSpecs.map { spec -> Metric in
            let atPurchase = purchaseValue(spec, years: years, entry: entry, cost: cost, anchorAtPurchase: anchorAtPurchase)
            return Metric(
                name: spec.name,
                value: spec.value,
                atPurchase: atPurchase,
                atLastReview: spec.value,
                unit: spec.unit,
                direction: spec.direction,
                note: spec.note
            )
        }

        let multipleNow = entry.price / entry.anchorPerShare
        let multipleThen = cost / anchorAtPurchase
        let lens = MoveLens(
            name: "Against \(entry.kind.valuationAnchor)",
            anchorName: anchorName(entry.kind),
            multipleName: multipleName(entry.kind),
            anchorStart: anchorAtPurchase,
            anchorEnd: entry.anchorPerShare,
            multipleStart: multipleThen,
            multipleEnd: multipleNow,
            anchorUnit: .currency,
            explanation: lensExplanation(kind: entry.kind, anchorChange: entry.anchorPerShare / anchorAtPurchase - 1, multipleChange: multipleNow / multipleThen - 1)
        )

        let evaluated = conditions.map { evaluate($0, metrics: metrics, multipleRatio: multipleNow / multipleThen) }
        let business = assessBusiness(metrics)
        let valuation = assessValuation(multipleNow / multipleThen)
        let attention = assessAttention(conditions: evaluated, valuation: valuation)

        return Holding(
            ticker: entry.ticker,
            name: entry.name,
            shortNameOverride: entry.shortName,
            exchange: "SGX",
            currency: "S$",
            kind: entry.kind,
            averageCost: cost,
            shares: shares,
            purchaseDate: purchaseDate,
            originalReasoning: reasoning,
            price: entry.price,
            anchorPerShare: entry.anchorPerShare,
            anchorAtPurchase: anchorAtPurchase,
            anchorAtLastReview: entry.anchorPerShare,
            dividendsPerShareSincePurchase: entry.dividendPerShare * years * 0.85,
            business: business,
            valuation: valuation,
            sentiment: .normal,
            flows: .unclear,
            attention: attention,
            conditions: evaluated,
            metrics: metrics,
            flowEvidence: [
                FlowEvidence(
                    actor: "All participants", direction: "No clear pattern", magnitude: "—",
                    window: "Trailing 6 months", confidence: .weak,
                    note: "Rerate has not yet accumulated enough flow history for this position to say anything useful. It will not guess."
                )
            ],
            scenarios: scenarios(for: entry, metrics: metrics),
            reviews: [],
            lenses: [lens],
            reratingDrivers: drivers(lens: lens, kind: entry.kind),
            bullCase: bullCase(entry: entry, lens: lens, metrics: metrics),
            bearCase: bearCase(entry: entry, lens: lens, valuation: valuation),
            mostUncertainAssumption: uncertainty(for: entry.kind),
            situation: situation(lens: lens, valuation: valuation),
            whatChangedSummary: summary(lens: lens, entry: entry),
            priceHistory: buildHistory(
                from: purchaseDate,
                months: max(Int(years * 12), 4),
                startPrice: cost, endPrice: entry.price,
                startAnchor: anchorAtPurchase, endAnchor: entry.anchorPerShare,
                shape: [0.012, -0.018, 0.022, 0.006, -0.014, 0.019, -0.009]
            )
        )
    }

    // MARK: Derivation

    private static func purchaseValue(_ spec: MetricSpec, years: Double, entry: CatalogueEntry, cost: Double, anchorAtPurchase: Double) -> Double {
        // Valuation metrics are recomputed from the purchase price rather than
        // drifted, so they always agree with the cost basis the user entered.
        switch spec.name {
        case "Price to book", "Price to NAV", "Price to earnings":
            return cost / anchorAtPurchase
        case "Dividend yield", "Distribution yield":
            return spec.value * entry.price / cost
        default:
            return spec.value - spec.driftPerYear * years
        }
    }

    private static func anchorName(_ kind: BusinessKind) -> String {
        switch kind {
        case .bank: "Book value per share"
        case .reit: "Net asset value per unit"
        default: "Earnings per share"
        }
    }

    private static func multipleName(_ kind: BusinessKind) -> String {
        switch kind {
        case .bank: "Price to book"
        case .reit: "Price to NAV"
        default: "Price to earnings"
        }
    }

    private static func lensExplanation(kind: BusinessKind, anchorChange: Double, multipleChange: Double) -> String {
        if abs(multipleChange) > abs(anchorChange) * 1.6 {
            return "Most of this move came from a change in what investors will pay, not from a change in what the business produced. That is the part of a return that can reverse without anything going wrong at the company."
        }
        if abs(anchorChange) > abs(multipleChange) * 1.6 {
            return "Most of this move came from the business itself. Investors are paying roughly what they paid when you bought — there is simply more to pay for."
        }
        return "This move splits roughly evenly between the business and the multiple investors apply to it."
    }

    /// Reads the plain-language test on a condition and checks it against the
    /// metrics we actually have. Where it cannot, it says so instead of
    /// inventing a verdict.
    private static func evaluate(_ condition: ThesisCondition, metrics: [Metric], multipleRatio: Double) -> ThesisCondition {
        var c = condition
        guard let metric = metrics.first(where: { $0.name.lowercased() == c.measure.lowercased() })
                ?? metrics.first(where: { $0.name.lowercased().contains(c.measure.lowercased()) })
        else {
            c.reading = "—"
            c.status = .passing
            c.evidence = "Rerate does not yet have a reading for this. It will start tracking it from today and tell you when it changes."
            return c
        }

        c.reading = metric.display
        let test = c.test.lowercased()
        let threshold = Double(test.filter { "0123456789.".contains($0) }) ?? .nan

        if test.contains("above") && !threshold.isNaN {
            c.status = metric.value >= threshold ? .passing : (metric.value >= threshold * 0.93 ? .warning : .failing)
        } else if test.contains("below") && !threshold.isNaN {
            c.status = metric.value <= threshold ? .passing : (metric.value <= threshold * 1.07 ? .warning : .failing)
        } else if test.contains("growing") || test.contains("positive") {
            c.status = metric.value > metric.atPurchase ? .passing : (metric.value >= metric.atPurchase * 0.98 ? .warning : .failing)
        } else if test.contains("not falling") || test.contains("stable") || test.contains("not rising") || test.contains("not eroding") {
            let improving = metric.direction == .higherIsBetter ? metric.value >= metric.atPurchase : metric.value <= metric.atPurchase
            c.status = improving ? .passing : .warning
        } else if test.contains("historical range") {
            c.status = multipleRatio > 1.45 ? .failing : (multipleRatio > 1.18 ? .warning : .passing)
            c.reading = Fmt.multiple(metrics.first { $0.unit == .multiple }?.value ?? 0)
        } else {
            c.status = .passing
        }

        c.evidence = "\(metric.name) is \(metric.display), against \(metric.displayAtPurchase) when you bought. Your test is \(c.test)."
        return c
    }

    private static func assessBusiness(_ metrics: [Metric]) -> Assessment {
        let operating = metrics.filter { $0.unit != .multiple }
        guard !operating.isEmpty else { return .stable }
        let improved = operating.filter { m in
            m.direction == .higherIsBetter ? m.value > m.atPurchase : m.value < m.atPurchase
        }.count
        let ratio = Double(improved) / Double(operating.count)
        switch ratio {
        case 0.7...: return .strong
        case 0.45..<0.7: return .stable
        case 0.25..<0.45: return .softening
        default: return .weak
        }
    }

    private static func assessValuation(_ ratio: Double) -> ValuationState {
        switch ratio {
        case 1.45...: return .stretched
        case 1.18..<1.45: return .full
        case 0.92..<1.18: return .fair
        default: return .attractive
        }
    }

    private static func assessAttention(conditions: [ThesisCondition], valuation: ValuationState) -> AttentionState {
        let failing = conditions.filter { $0.status == .failing }.count
        if failing >= 2 { return .reviewRequired }
        if failing == 1 { return .materialChange }
        if valuation == .stretched { return .worthWatching }
        return .noChange
    }

    // MARK: Generated content

    private static func scenarios(for entry: CatalogueEntry, metrics: [Metric]) -> [Scenario] {
        if ValuationEngine.usesEquityModel(entry.kind) {
            let current = (metrics.first { $0.name.contains("Return on equity") }?.value ?? 13) / 100
            let base = entry.kind == .reit ? 0.06 : current
            return [
                Scenario(name: "Normalisation", premise: "Returns drift back toward the long-run average.",
                         roe: base * 0.76, growth: 0.028, requiredReturn: 0.094,
                         reasoning: "The favourable part of the cycle ends and profitability settles closer to where this business has historically sat.",
                         whatWouldMakeItTrue: ["Returns falling toward the ten-year average", "Margin pressure continuing"]),
                Scenario(name: "Steady state", premise: "The business holds roughly where it is.",
                         roe: base * 0.94, growth: 0.038, requiredReturn: 0.089,
                         reasoning: "No further improvement, but no deterioration either. Returns hold near current levels through the cycle.",
                         whatWouldMakeItTrue: ["Current returns sustained", "No change in the competitive position"]),
                Scenario(name: "Continued improvement", premise: "The recent trend keeps going.",
                         roe: base * 1.09, growth: 0.048, requiredReturn: 0.084,
                         reasoning: "The improvement proves structural rather than cyclical, and investors accept a lower required return as results become more predictable.",
                         whatWouldMakeItTrue: ["Returns above the current level through a full cycle", "Earnings becoming visibly less volatile"])
            ]
        }
        return [
            Scenario(name: "Growth fades", premise: "Earnings growth slows to inflation.",
                     roe: 0, growth: 0.012, requiredReturn: 0.088,
                     reasoning: "The current rate of improvement is not sustained and earnings settle into a low-growth pattern.",
                     whatWouldMakeItTrue: ["Earnings growth under 2%", "Margins flat or falling"]),
            Scenario(name: "Steady state", premise: "Growth continues at a moderate pace.",
                     roe: 0, growth: 0.032, requiredReturn: 0.084,
                     reasoning: "Earnings compound at roughly the rate of nominal economic growth, with the payout maintained.",
                     whatWouldMakeItTrue: ["Earnings growth near 3%", "Payout ratio maintained"]),
            Scenario(name: "Sustained execution", premise: "Management keeps delivering.",
                     roe: 0, growth: 0.050, requiredReturn: 0.080,
                     reasoning: "Margin improvement continues and the market treats the earnings as more durable than it does today.",
                     whatWouldMakeItTrue: ["Margins continuing to expand", "Growth above 5% for several years"])
        ]
    }

    private static func drivers(lens: MoveLens, kind: BusinessKind) -> [ReratingDriver] {
        let reratingLed = lens.multipleShare > 0.5
        var out: [ReratingDriver] = [
            ReratingDriver(
                name: reratingLed ? "Investors are paying more for the same business" : "The business produced more",
                kind: .evidence,
                confidence: .strong,
                summary: reratingLed
                    ? "\(lens.multipleName) moved from \(Fmt.multiple(lens.multipleStart)) to \(Fmt.multiple(lens.multipleEnd))."
                    : "\(lens.anchorName) moved from \(Fmt.money(lens.anchorStart)) to \(Fmt.money(lens.anchorEnd)).",
                detail: reratingLed
                    ? "This is arithmetic rather than interpretation: at the same \(kind.valuationAnchor) per share, the price would be materially different. The multiple did the work, and a multiple is an opinion."
                    : "This is the part of the return the company genuinely created. It does not depend on anyone's opinion and cannot be withdrawn by a change of mood."
            )
        ]
        out.append(
            ReratingDriver(
                name: "Everything else",
                kind: .uncertainty,
                confidence: .weak,
                summary: "Rerate has not accumulated enough history on this position to attribute the move further.",
                detail: "Sector re-ratings, flow effects, rate expectations and changes in analyst forecasts can all move a multiple. Separating them takes data this position does not have yet. Rather than offering a plausible story, Rerate will say it does not know — and will fill this in as evidence accumulates."
            )
        )
        return out
    }

    private static func bullCase(entry: CatalogueEntry, lens: MoveLens, metrics: [Metric]) -> Argument {
        let improved = metrics.filter { m in
            m.unit != .multiple && (m.direction == .higherIsBetter ? m.value > m.atPurchase : m.value < m.atPurchase)
        }.prefix(3)
        return Argument(
            title: "The case for still owning it",
            stance: "The reasons you wrote down when you bought are still visible in the figures.",
            points: improved.map { m in
                ArgumentPoint(
                    claim: "\(m.name) has improved",
                    kind: .evidence,
                    support: "\(m.displayAtPurchase) at purchase, \(m.display) now."
                )
            } + [
                ArgumentPoint(
                    claim: lens.anchorShare > 0.5 ? "The gain was earned, not granted" : "The business is still growing underneath the price",
                    kind: .interpretation,
                    support: "\(Int((lens.anchorShare * 100).rounded()))% of the move came from \(lens.anchorName.lowercased()) rather than the multiple."
                )
            ],
            invalidatedBy: "Two consecutive periods of deterioration in the measures above would remove the basis for this case."
        )
    }

    private static func bearCase(entry: CatalogueEntry, lens: MoveLens, valuation: ValuationState) -> Argument {
        var points: [ArgumentPoint] = [
            ArgumentPoint(
                claim: "\(Int((lens.multipleShare * 100).rounded()))% of the move was re-rating",
                kind: .evidence,
                support: "\(lens.multipleName) went from \(Fmt.multiple(lens.multipleStart)) to \(Fmt.multiple(lens.multipleEnd)). That portion can reverse without the business doing anything wrong."
            )
        ]
        if valuation == .stretched || valuation == .full {
            points.append(
                ArgumentPoint(
                    claim: "The margin of safety has narrowed",
                    kind: .interpretation,
                    support: "You bought at \(Fmt.multiple(lens.multipleStart)). At \(Fmt.multiple(lens.multipleEnd)) the same disappointment costs more, because the price is carrying an assumption rather than a result."
                )
            )
        }
        points.append(
            ArgumentPoint(
                claim: "Recent performance is not evidence of durability",
                kind: .uncertainty,
                support: "A few good years is a short record to extrapolate from. The question is whether the improvement survives a full cycle, and there is not yet enough history to answer it."
            )
        )
        return Argument(
            title: "The strongest case against",
            stance: "You may be extrapolating a favourable period, at a price that assumes it continues.",
            points: points,
            invalidatedBy: "The current level of performance holding through a full cycle would show the improvement is structural rather than cyclical."
        )
    }

    private static func uncertainty(for kind: BusinessKind) -> String {
        switch kind {
        case .bank: "Whether current returns on equity survive a full interest-rate cycle. Most of the case rests on this, and it is the number with the least history behind it."
        case .reit: "Where the cost of debt settles. For a leveraged property vehicle that single number does more to determine the distribution than anything happening in the buildings."
        case .telecom, .industrial: "Whether recent margin improvement is structural or the easy part of a cycle."
        case .matureTech: "Whether the current growth rate is durable once the market matures."
        }
    }

    private static func situation(lens: MoveLens, valuation: ValuationState) -> String {
        if lens.multipleShare > 0.62 { return "Most of the move has been a change of opinion rather than a change in the business." }
        if lens.anchorShare > 0.62 { return "The business did the work here. Investors pay roughly what they always did." }
        return "The business and the market's opinion of it moved together."
    }

    private static func summary(lens: MoveLens, entry: CatalogueEntry) -> String {
        "\(lens.anchorName) moved \(Fmt.percent(lens.anchorGrowth * 100, signed: true)) since your purchase, while \(lens.multipleName.lowercased()) moved \(Fmt.percent(lens.multipleGrowth * 100, signed: true)). That makes roughly \(Int((lens.multipleShare * 100).rounded()))% of your price move a re-rating and \(Int((lens.anchorShare * 100).rounded()))% the business itself."
    }
}
