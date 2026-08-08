import Foundation

struct ValuationLever: Identifiable {
    var id: String { name }
    var name: String
    var detail: String
    var range: ClosedRange<Double>
    var step: Double
    var defaultValue: Double
    /// A marker drawn on the track — usually where the business sits today.
    var reference: (label: String, value: Double)?
    /// A second marker, usually the long-run history.
    var history: (label: String, value: Double)?
    var format: (Double) -> String
}

/// Turns three assumptions into a multiple. Two models cover everything in V1:
/// an equity model for businesses whose value is anchored on a balance sheet,
/// and a cash-return model for everything else.
///
/// Both are deliberately simple. The purpose is not to produce a fair value —
/// it is to make visible which assumptions today's price is already carrying.
enum ValuationEngine {

    static func usesEquityModel(_ kind: BusinessKind) -> Bool {
        kind == .bank || kind == .reit
    }

    static func levers(for h: Holding) -> [ValuationLever] {
        if usesEquityModel(h.kind) {
            let currentReturn = h.metrics.first { $0.name.contains("Return on equity") }?.value
                ?? (h.kind == .reit ? 5.5 : 15.0)
            return [
                ValuationLever(
                    name: h.kind == .reit ? "Return on assets" : "Return on equity",
                    detail: h.kind == .reit
                        ? "What the portfolio earns on its net asset value, sustained over the long run."
                        : "What the bank earns on each dollar of equity, sustained — not this year's figure, but the level it settles at.",
                    range: h.kind == .reit ? 0.03...0.09 : 0.10...0.22,
                    step: 0.001,
                    defaultValue: currentReturn / 100,
                    reference: ("Today \(Fmt.percent(currentReturn))", currentReturn / 100),
                    history: h.kind == .reit ? nil : ("10y avg 12.4%", 0.124),
                    format: { Fmt.percent($0 * 100) }
                ),
                ValuationLever(
                    name: "Long-run growth",
                    detail: "How fast the equity base compounds once the business is mature. Above the economy's growth rate forever is a strong claim.",
                    range: 0.01...0.07,
                    step: 0.0025,
                    defaultValue: 0.04,
                    reference: nil,
                    history: ("GDP ≈ 4%", 0.04),
                    format: { Fmt.percent($0 * 100) }
                ),
                ValuationLever(
                    name: "Required return",
                    detail: "What you need to earn to justify owning this rather than something safer. Higher means you demand a bigger discount for the risk.",
                    range: 0.065...0.115,
                    step: 0.0025,
                    defaultValue: 0.09,
                    reference: nil,
                    history: nil,
                    format: { Fmt.percent($0 * 100) }
                )
            ]
        }

        let growth = 0.03
        return [
            ValuationLever(
                name: "Long-run earnings growth",
                detail: "How fast earnings per share compound once the current recovery is complete.",
                range: 0.00...0.07,
                step: 0.0025,
                defaultValue: growth,
                reference: nil,
                history: ("GDP ≈ 4%", 0.04),
                format: { Fmt.percent($0 * 100) }
            ),
            ValuationLever(
                name: "Payout ratio",
                detail: "The share of earnings returned to you as dividends. What is not paid out has to earn a return inside the business.",
                range: 0.30...1.00,
                step: 0.01,
                defaultValue: 0.86,
                reference: ("Today 86%", 0.86),
                history: nil,
                format: { Fmt.percent($0 * 100, places: 0) }
            ),
            ValuationLever(
                name: "Required return",
                detail: "What you need to earn to justify owning this rather than something safer.",
                range: 0.060...0.110,
                step: 0.0025,
                defaultValue: 0.082,
                reference: nil,
                history: nil,
                format: { Fmt.percent($0 * 100) }
            )
        ]
    }

    /// The multiple implied by a set of assumptions.
    static func multiple(kind: BusinessKind, values: [Double]) -> Double {
        guard values.count >= 3 else { return 1 }
        if usesEquityModel(kind) {
            return EquityValuation.justifiedMultiple(
                roe: values[0], growth: values[1], requiredReturn: values[2]
            )
        }
        let (g, payout, r) = (values[0], values[1], values[2])
        let spread = max(r - g, EquityValuation.minimumSpread)
        return max(payout * (1 + g) / spread, 0.5)
    }

    /// Solving the model backwards: holding two assumptions fixed, what does
    /// today's price require of the third?
    static func impliedPrimary(kind: BusinessKind, multiple: Double, values: [Double]) -> Double {
        guard values.count >= 3 else { return 0 }
        if usesEquityModel(kind) {
            return EquityValuation.impliedROE(
                multiple: multiple, growth: values[1], requiredReturn: values[2]
            )
        }
        // Solve payout·(1+g)/(r−g) = multiple for g.
        let (payout, r) = (values[1], values[2])
        var lo = -0.05, hi = r - EquityValuation.minimumSpread
        for _ in 0..<48 {
            let mid = (lo + hi) / 2
            let m = payout * (1 + mid) / max(r - mid, EquityValuation.minimumSpread)
            if m < multiple { lo = mid } else { hi = mid }
        }
        return (lo + hi) / 2
    }

    static func levers(from scenario: Scenario, kind: BusinessKind) -> [Double] {
        if usesEquityModel(kind) {
            return [scenario.roe, scenario.growth, scenario.requiredReturn]
        }
        return [scenario.growth, 0.86, scenario.requiredReturn]
    }
}
