import Foundation

/// Everything Rerate knows about one position. A holding is not a row in a
/// portfolio — it is a standing argument the investor made, plus the evidence
/// that has accumulated for and against it since.
struct Holding: Identifiable {
    var id: UUID = UUID()

    // Identity
    var ticker: String
    var name: String
    /// Set only where the legal name is too long to sit in a card title.
    /// Investors use the short form for these anyway.
    var shortNameOverride: String? = nil
    var exchange: String
    var currency: String
    var kind: BusinessKind

    // What the investor did
    var averageCost: Double
    var shares: Double
    var purchaseDate: Date
    /// The sentence they wrote when asked why they bought it.
    var originalReasoning: String

    // Where things stand
    var price: Double
    var anchorPerShare: Double        // BVPS for a bank, NAV for a REIT, EPS for others
    var anchorAtPurchase: Double
    var anchorAtLastReview: Double
    var dividendsPerShareSincePurchase: Double

    // Judgements
    var business: Assessment
    var valuation: ValuationState
    var sentiment: SentimentState
    var flows: FlowState
    var attention: AttentionState

    // Substance
    var conditions: [ThesisCondition]
    var metrics: [Metric]
    var flowEvidence: [FlowEvidence]
    var scenarios: [Scenario]
    var reviews: [Review]
    var lenses: [MoveLens]
    var reratingDrivers: [ReratingDriver]
    var bullCase: Argument
    var bearCase: Argument
    var mostUncertainAssumption: String
    /// One sentence summarising the position. Shown under the price.
    var situation: String
    var whatChangedSummary: String
    var priceHistory: [PricePoint]

    // MARK: Derived

    var shortName: String { shortNameOverride ?? name }
    var hasShortName: Bool { shortNameOverride != nil }

    var multiple: Double { price / anchorPerShare }
    var multipleAtPurchase: Double { averageCost / anchorAtPurchase }
    var multipleAtLastReview: Double {
        guard let last = reviews.last else { return multiple }
        return last.anchorMultiple
    }

    var priceReturn: Double { price / averageCost - 1 }
    var dividendReturn: Double { dividendsPerShareSincePurchase / averageCost }
    var totalReturn: Double { priceReturn + dividendReturn }

    var marketValue: Double { price * shares }
    var costBasis: Double { averageCost * shares }
    var gain: Double { marketValue - costBasis }

    var lastReview: Review? { reviews.last }

    /// "Intact" means not yet broken. A condition under pressure still holds —
    /// collapsing warnings into failures would overstate what has happened.
    var conditionsIntact: Int { conditions.filter { $0.status != .failing }.count }
    var conditionsTotal: Int { conditions.count }

    var thesisState: ThesisState {
        let failing = conditions.filter { $0.status == .failing }.count
        let warning = conditions.filter { $0.status == .warning }.count
        if failing == 0 && warning == 0 { return .intact }
        if failing >= 2 || (failing >= 1 && warning >= 2) { return .broken }
        if failing >= 1 { return .mostlyIntact }
        return warning >= 2 ? .weakening : .mostlyIntact
    }

    /// The lens used for headline messaging — the first one is the primary
    /// identity for that business kind.
    var primaryLens: MoveLens { lenses[0] }

    /// Share of the move that came from paying more, not from the business.
    var reratingShare: Double { primaryLens.multipleShare }

    var sinceLastReviewPriceChange: Double? {
        guard let last = reviews.last else { return nil }
        return price / last.price - 1
    }
}

struct PricePoint: Identifiable {
    var id: Int
    var date: Date
    var price: Double
    /// Anchor per share at that date — lets the chart show the business line
    /// underneath the price line.
    var anchor: Double
}

/// A candidate explanation for why the multiple expanded. Rerate separates the
/// ones it can evidence from the ones that are only plausible.
struct ReratingDriver: Identifiable {
    var id: String { name }
    var name: String
    var kind: ClaimKind
    var confidence: Confidence
    var summary: String
    var detail: String
}

// MARK: - Valuation model

/// Justified multiple for a business whose value is anchored on equity:
///
///     P/B = (ROE − g) / (r − g)
///
/// Deliberately simple and completely visible to the user. The point is not
/// precision — it is showing what set of assumptions the current price implies.
enum EquityValuation {
    static let minimumSpread = 0.015

    static func justifiedMultiple(roe: Double, growth: Double, requiredReturn: Double) -> Double {
        let spread = max(requiredReturn - growth, minimumSpread)
        return max((roe - growth) / spread, 0.05)
    }

    static func impliedPrice(
        roe: Double,
        growth: Double,
        requiredReturn: Double,
        anchorPerShare: Double
    ) -> Double {
        justifiedMultiple(roe: roe, growth: growth, requiredReturn: requiredReturn) * anchorPerShare
    }

    /// Given the price the market is actually paying, what return on equity
    /// does it need the business to sustain?
    static func impliedROE(
        multiple: Double,
        growth: Double,
        requiredReturn: Double
    ) -> Double {
        let spread = max(requiredReturn - growth, minimumSpread)
        return multiple * spread + growth
    }
}
