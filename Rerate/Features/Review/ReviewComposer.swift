import Foundation

/// Builds the written review from the position's own data.
///
/// Everything here is derived rather than stored, so a review reads correctly
/// for any holding and stays consistent with the figures on every other screen.
/// This is the layer a language model would sit behind in production — the
/// structure of what gets said is fixed by the product, not by the model.
enum ReviewComposer {

    struct Section: Identifiable {
        var id: String { title }
        var title: String
        var body: String
        var kind: ClaimKind?
        var confidence: Confidence?
        var bullets: [String] = []
    }

    static func headline(_ h: Holding) -> String {
        let rerating = h.reratingShare
        let move = h.priceReturn

        if abs(move) < 0.05 {
            return "Little has happened to the price. The question worth asking is whether anything has happened to the business."
        }
        if move > 0 && rerating > 0.6 {
            return "The business improved. The market's opinion of it improved considerably more. Most of what you have gained is a change of opinion, and opinions are returnable."
        }
        if move > 0 && rerating < 0.35 {
            return "This gain was earned rather than granted. Investors pay roughly what they always paid; there is simply more business to pay for."
        }
        if move < 0 && rerating > 0.6 {
            return "The decline is a change in what investors will pay, not a change in what the business produced."
        }
        if move < 0 {
            return "The decline came from the business itself rather than from sentiment. That is the harder kind to wait out."
        }
        return "The move splits roughly evenly between the business and the multiple applied to it."
    }

    static func sections(_ h: Holding) -> [Section] {
        var out: [Section] = []
        let lens = h.primaryLens

        // 1 — since purchase
        out.append(Section(
            title: "What changed since you bought",
            body: sincePurchase(h),
            kind: .evidence,
            confidence: .strong
        ))

        // 2 — since last review
        if let last = h.lastReview {
            out.append(Section(
                title: "What changed since your last review",
                body: sinceReview(h, last),
                kind: .evidence,
                confidence: .strong,
                bullets: reviewDeltas(h, last)
            ))
        }

        // 3 — the business
        out.append(Section(
            title: "Has the business improved or deteriorated?",
            body: businessNarrative(h),
            kind: .evidence,
            confidence: .strong,
            bullets: businessBullets(h)
        ))

        // 4 — valuation
        out.append(Section(
            title: "Has the valuation changed?",
            body: valuationNarrative(h),
            kind: .evidence,
            confidence: .strong
        ))

        // 5 — why it moved
        out.append(Section(
            title: "Why the price moved",
            body: "Measured against \(lens.anchorName.lowercased()), \(Int((lens.anchorShare * 100).rounded()))% of the move came from the business and \(Int((lens.multipleShare * 100).rounded()))% from the multiple investors apply to it. \(lens.explanation)",
            kind: .evidence,
            confidence: .strong
        ))

        // 6 — flows
        out.append(Section(
            title: "Who appears to be buying?",
            body: flowsNarrative(h),
            kind: .interpretation,
            confidence: flowConfidence(h),
            bullets: h.flowEvidence.prefix(3).map { "\($0.actor): \($0.direction.lowercased()), \($0.magnitude) over \($0.window.lowercased())" }
        ))

        // 7 — thesis
        out.append(Section(
            title: "Which parts of your thesis still hold",
            body: thesisNarrative(h),
            kind: .evidence,
            confidence: .strong,
            bullets: h.conditions.map { "\($0.statement) — \($0.status.rawValue.lowercased()) (\($0.reading))" }
        ))

        // 8 — what matters now
        out.append(Section(
            title: "Which assumptions now matter most",
            body: h.mostUncertainAssumption,
            kind: .uncertainty,
            confidence: .moderate
        ))

        // 9 — what breaks it
        out.append(Section(
            title: "What could break this",
            body: h.bullCase.invalidatedBy + " " + breakageContext(h),
            kind: .interpretation,
            confidence: .moderate
        ))

        // 10 — next
        out.append(Section(
            title: "What deserves attention next",
            body: nextNarrative(h),
            kind: .interpretation,
            confidence: .moderate,
            bullets: watchItems(h)
        ))

        return out
    }

    // MARK: Pieces

    private static func sincePurchase(_ h: Holding) -> String {
        let period = Fmt.duration(since: h.purchaseDate)
        return "You bought at \(Fmt.money(h.averageCost, currency: h.currency)) \(period) ago. The price is now \(Fmt.money(h.price, currency: h.currency)), a change of \(Fmt.percent(h.priceReturn * 100, signed: true)), or \(Fmt.percent(h.totalReturn * 100, signed: true)) including the \(Fmt.money(h.dividendsPerShareSincePurchase, currency: h.currency)) per share of dividends you have received. \(h.kind.valuationAnchor.prefix(1).uppercased() + h.kind.valuationAnchor.dropFirst()) per share moved from \(Fmt.money(h.anchorAtPurchase, currency: h.currency)) to \(Fmt.money(h.anchorPerShare, currency: h.currency)), and the multiple from \(Fmt.multiple(h.multipleAtPurchase)) to \(Fmt.multiple(h.multiple))."
    }

    private static func sinceReview(_ h: Holding, _ last: Review) -> String {
        let priceMove = h.price / last.price - 1
        let multipleMove = h.multiple / last.anchorMultiple - 1
        let anchorMove = h.anchorPerShare / h.anchorAtLastReview - 1
        let when = Fmt.shortDate.string(from: last.date)
        if abs(priceMove) < 0.01 {
            return "You last looked at this on \(when). The price has barely moved since. That is not the same as nothing having changed — the figures below are what actually moved underneath it."
        }
        let dominant = abs(multipleMove) > abs(anchorMove) * 1.5
            ? "Almost all of that was the multiple, not the business."
            : (abs(anchorMove) > abs(multipleMove) * 1.5
                ? "That came from the business rather than from a change of opinion."
                : "Roughly half of that was the business and half a change in the multiple.")
        return "You last reviewed this on \(when), when the price was \(Fmt.money(last.price, currency: h.currency)). It has since \(priceMove > 0 ? "risen" : "fallen") \(Fmt.percent(abs(priceMove) * 100)). \(dominant)"
    }

    private static func reviewDeltas(_ h: Holding, _ last: Review) -> [String] {
        h.metrics
            .filter { abs($0.changeSinceReview) > abs($0.atLastReview) * 0.004 }
            .sorted { abs($0.changeSinceReview / max($0.atLastReview, 0.001)) > abs($1.changeSinceReview / max($1.atLastReview, 0.001)) }
            .prefix(4)
            .map { "\($0.name): \($0.displayAtLastReview) → \($0.display)" }
    }

    private static func businessNarrative(_ h: Holding) -> String {
        switch h.business {
        case .strong:
            return "Improved, and not marginally. The operating figures are better than when you bought on almost every line that matters for this kind of business. Whatever the right conclusion about the price, it is not that the company has deteriorated."
        case .stable:
            return "Broadly unchanged. The business is doing what it did when you bought it — neither compounding faster nor falling behind."
        case .softening:
            return "Softening in specific places rather than across the board. The distinction matters: an isolated pressure point can be waited out, a broad decline usually cannot."
        case .weak:
            return "Deteriorating. This is a change in the company rather than in how it is priced, and it is the kind of change that does not resolve by holding on."
        }
    }

    private static func businessBullets(_ h: Holding) -> [String] {
        h.metrics.prefix(5).map {
            "\($0.name): \($0.displayAtPurchase) at purchase → \($0.display) now"
        }
    }

    private static func valuationNarrative(_ h: Holding) -> String {
        let now = Fmt.multiple(h.multiple)
        let then = Fmt.multiple(h.multipleAtPurchase)
        let anchor = h.kind.valuationAnchor
        switch h.valuation {
        case .stretched:
            return "Substantially. You bought at \(then) \(anchor); it now trades at \(now). This is the largest single change in the position, and it is the one that depends least on the company. A multiple this far above its own history has to be defended by something, and the burden of that defence has shifted onto assumptions rather than results."
        case .full:
            return "Yes. From \(then) to \(now) \(anchor). Not extreme, but the easy part of the re-rating has happened. From here more of the return has to come from the business."
        case .fair:
            return "Only modestly, from \(then) to \(now) \(anchor). The multiple is inside the range this business has normally traded in, so it is neither helping nor hurting your case much."
        case .attractive:
            return "Not upward. The multiple has gone from \(then) to \(now) \(anchor) — investors are paying no more for this business than they did when you bought it, and arguably less."
        }
    }

    private static func flowsNarrative(_ h: Holding) -> String {
        switch h.flows {
        case .institutional:
            return "The available evidence points to institutional rather than retail buying. Retail attention has increased, but the flow data does not support the claim that retail buying created this move — retail investors have on balance been selling into it. Flow data tells you who transacted. It does not tell you why, and it cannot separate conviction from mandate."
        case .broad:
            return "Buying appears broadly distributed, with no single group dominating. There is nothing in the flow data suggesting the price is being driven by one crowded source."
        case .retail:
            return "The evidence points toward retail-led buying. That does not make the move wrong, but retail-driven re-ratings have historically unwound faster than institutionally driven ones."
        case .outflow:
            return "Institutions have been reducing. This is worth noting rather than acting on: professional selling is often mandate-driven and says less about the business than it appears to."
        case .unclear:
            return "There is not enough evidence to determine this confidently. Rather than construct a story from thin data, Rerate will say so: the flows here do not support a firm conclusion in either direction."
        }
    }

    private static func flowConfidence(_ h: Holding) -> Confidence {
        h.flows == .unclear ? .weak : (h.flowEvidence.first?.confidence ?? .moderate)
    }

    private static func thesisNarrative(_ h: Holding) -> String {
        let failing = h.conditions.filter { $0.status == .failing }
        let warning = h.conditions.filter { $0.status == .warning }
        var text = "\(h.conditionsIntact) of \(h.conditionsTotal) conditions you wrote down are still true."
        if let f = failing.first {
            text += " The one that has broken is \(f.statement.lowercased()) — now \(f.reading), against your test of \(f.test)."
        }
        if let w = warning.first {
            text += " \(w.statement) is under pressure at \(w.reading)."
        }
        if failing.isEmpty && warning.isEmpty {
            text += " Nothing has changed in the reasoning you recorded."
        }
        return text
    }

    private static func breakageContext(_ h: Holding) -> String {
        h.valuation == .stretched
            ? "At this multiple you no longer need bad news to lose money — a slightly less good year would be enough, because the price is carrying an assumption rather than a result."
            : "None of these are visible in the current figures. They are what to watch for, not what is happening."
    }

    private static func nextNarrative(_ h: Holding) -> String {
        switch (h.business, h.valuation) {
        case (.strong, .stretched):
            return "Nothing in the business requires action. The open question is entirely about price: whether you are comfortable owning a good company at a valuation that assumes it stays exceptional. That is a question about your own tolerance, not about the company, and Rerate is not going to answer it for you."
        case (.softening, _), (.weak, _):
            return "The pressure here is operational rather than a matter of sentiment. Watch the specific figures below over the next reporting period — they will tell you whether this is a cycle or a trend."
        default:
            return "There is nothing pressing. The figures below are the ones that would change that."
        }
    }

    private static func watchItems(_ h: Holding) -> [String] {
        var items: [String] = []
        for condition in h.conditions where condition.status != .passing {
            items.append("\(condition.measure) — currently \(condition.reading), your test is \(condition.test)")
        }
        let declining = h.metrics.filter { $0.toneSinceReview == .caution }.prefix(2)
        for m in declining {
            items.append("\(m.name) — moved \(m.displayAtLastReview) → \(m.display) since your last review")
        }
        if items.isEmpty {
            items.append("Nothing is currently near a threshold you set")
        }
        return items
    }
}
