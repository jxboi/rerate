import Foundation
import Observation

@Observable
final class Store {
    var holdings: [Holding]
    var signals: [Signal]
    var hasOnboarded: Bool
    /// Set when the user finishes onboarding so the app can take them straight
    /// into the position they just created.
    var pendingFocus: UUID?

    init(demo: Bool = true) {
        if demo {
            holdings = [
                SeedDBS.holding,
                SeedCICT.holding,
                SeedOCBC.holding,
                SeedSingtel.holding
            ]
            signals = Store.seedSignals()
            hasOnboarded = true
        } else {
            holdings = []
            signals = []
            hasOnboarded = false
        }
    }

    // MARK: Lookup

    func holding(_ id: UUID) -> Holding? {
        holdings.first { $0.id == id }
    }

    func index(_ id: UUID) -> Int? {
        holdings.firstIndex { $0.id == id }
    }

    /// The portfolio screen is ordered by what needs thinking about, not by size.
    var byAttention: [Holding] {
        holdings.sorted {
            if $0.attention.priority != $1.attention.priority {
                return $0.attention.priority < $1.attention.priority
            }
            return $0.marketValue > $1.marketValue
        }
    }

    var needsAttention: [Holding] {
        byAttention.filter { $0.attention != .noChange }
    }

    var totalValue: Double { holdings.reduce(0) { $0 + $1.marketValue } }
    var totalCost: Double { holdings.reduce(0) { $0 + $1.costBasis } }

    func weight(of holding: Holding) -> Double {
        totalValue > 0 ? holding.marketValue / totalValue : 0
    }

    // MARK: Signals

    var unreadSignals: [Signal] { signals.filter { !$0.read } }

    func markRead(_ signal: Signal) {
        guard let i = signals.firstIndex(where: { $0.id == signal.id }) else { return }
        signals[i].read = true
    }

    func markAllRead() {
        for i in signals.indices { signals[i].read = true }
    }

    func signals(for ticker: String) -> [Signal] {
        signals.filter { $0.ticker == ticker }
    }

    // MARK: Mutation

    func updateCondition(holdingID: UUID, condition: ThesisCondition) {
        guard let h = index(holdingID),
              let c = holdings[h].conditions.firstIndex(where: { $0.id == condition.id })
        else { return }
        holdings[h].conditions[c] = condition
    }

    func addCondition(holdingID: UUID, condition: ThesisCondition) {
        guard let h = index(holdingID) else { return }
        holdings[h].conditions.append(condition)
    }

    func removeCondition(holdingID: UUID, conditionID: UUID) {
        guard let h = index(holdingID) else { return }
        holdings[h].conditions.removeAll { $0.id == conditionID }
    }

    /// Recording a review is what gives the app its memory. Everything the user
    /// sees on their next visit is measured against the last one of these.
    func recordReview(holdingID: UUID, prompt: String?, conclusion: String) {
        guard let h = index(holdingID) else { return }
        let holding = holdings[h]
        let review = Review(
            date: Date(),
            price: holding.price,
            anchorMultiple: holding.multiple,
            headlineMetric: holding.metrics.first?.value ?? 0,
            conclusion: conclusion,
            thesisState: holding.thesisState,
            conditionsIntact: holding.conditionsIntact,
            conditionsTotal: holding.conditionsTotal,
            prompt: prompt
        )
        holdings[h].reviews.append(review)
        holdings[h].anchorAtLastReview = holding.anchorPerShare
        holdings[h].attention = holding.thesisState == .broken ? .materialChange : .noChange
        for i in holdings[h].metrics.indices {
            holdings[h].metrics[i].atLastReview = holdings[h].metrics[i].value
        }
        for i in holdings[h].conditions.indices {
            holdings[h].conditions[i].previousReading = holdings[h].conditions[i].reading
        }
    }

    func add(_ holding: Holding) {
        holdings.append(holding)
        pendingFocus = holding.id
        hasOnboarded = true
    }

    // MARK: Seed signals

    private static func seedSignals() -> [Signal] {
        [
            Signal(
                ticker: "D05",
                date: makeDate(2026, 8, 5),
                headline: "DBS crossed 3× book value",
                body: "Your operating thesis has not changed. Returns, credit quality and wealth growth are all where they were. What changed is the price investors are willing to pay for each dollar of the bank's equity — now 3.20×, against a ten-year range of 1.06× to 1.63×.\n\nThis is the level you asked to be told about.",
                kind: .valuationThreshold
            ),
            Signal(
                ticker: "C38U",
                date: makeDate(2026, 8, 1),
                headline: "A condition you set is no longer true",
                body: "CICT's average cost of debt reached 3.6%, above the 3.2% limit you defined when you bought it.\n\nNet property income still grew 3.8% and occupancy is 96.4%. The properties are performing. The distribution fell anyway, because the increase in financing cost was larger than the increase in property income.",
                kind: .conditionChanged
            ),
            Signal(
                ticker: "D05",
                date: makeDate(2026, 7, 17),
                headline: "DBS reported. Three conditions strengthened, one weakened.",
                body: "Return on equity, wealth management growth and capital all improved. Net interest margin fell again, from 2.08% to 2.02%, as policy rates eased.\n\nNothing in the result changed the long-term case. It did make the valuation slightly harder to justify, because book value grew more slowly than the price did.",
                kind: .earnings
            ),
            Signal(
                ticker: "O39",
                date: makeDate(2026, 7, 30),
                headline: "OCBC reported. Nothing material changed.",
                body: "Results were close to expectations on every line that matters to your thesis. Capital rose slightly, credit was stable, the dividend was maintained.\n\nNo action, and nothing worth reading in detail.",
                kind: .quiet,
                read: true
            )
        ]
    }
}
