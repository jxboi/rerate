import Foundation

/// Turns a sentence like
///
///   "Strong Singapore bank, attractive dividend, high ROE, growing
///    wealth-management business, long-term compounder."
///
/// into a set of testable conditions.
///
/// This runs locally and deterministically. In production the same interface
/// would be served by a model — the important part of the design is that the
/// *output* is a structured, editable, falsifiable list rather than a chat
/// response, because that structure is what the rest of the app monitors.
enum ThesisExtractor {

    struct Candidate {
        var statement: String
        var measure: String
        var test: String
        /// Phrase in the user's own words that produced this condition.
        var source: String
    }

    private struct Pattern {
        var keywords: [String]
        var kinds: Set<BusinessKind>?
        var statement: String
        var measure: String
        var test: String
    }

    private static let patterns: [Pattern] = [
        // Returns and profitability
        Pattern(keywords: ["roe", "return on equity", "returns"], kinds: [.bank, .industrial, .telecom, .matureTech],
                statement: "Return on equity stays above 15%", measure: "Return on equity", test: "above 15%"),
        Pattern(keywords: ["roic", "return on capital", "return on invested"], kinds: nil,
                statement: "Return on invested capital stays above 9%", measure: "Return on invested capital", test: "above 9%"),
        Pattern(keywords: ["margin", "margins", "profitable", "profitability"], kinds: nil,
                statement: "Margins hold or improve", measure: "Operating margin", test: "not falling"),

        // Income
        Pattern(keywords: ["dividend", "yield", "income", "payout"], kinds: nil,
                statement: "The dividend stays attractive", measure: "Dividend yield", test: "above 4.5%"),
        Pattern(keywords: ["distribution", "dpu"], kinds: [.reit],
                statement: "Distributions stay steady", measure: "Distribution per unit", test: "not falling"),

        // Growth engines
        Pattern(keywords: ["wealth", "wealth management", "private bank"], kinds: [.bank],
                statement: "Wealth management keeps compounding", measure: "Wealth AUM", test: "growing"),
        Pattern(keywords: ["fee", "fees", "non-interest"], kinds: [.bank],
                statement: "Fee income keeps growing", measure: "Fee income", test: "growing"),
        Pattern(keywords: ["grow", "growing", "growth", "compounder", "compound"], kinds: nil,
                statement: "The business keeps growing", measure: "Revenue growth", test: "positive"),

        // Risk
        Pattern(keywords: ["credit", "npl", "bad debt", "loan quality", "provisions"], kinds: [.bank],
                statement: "Credit quality stays strong", measure: "Non-performing loans", test: "below 1.5%"),
        Pattern(keywords: ["capital", "cet1", "well capitalised", "well capitalized", "balance sheet"], kinds: [.bank],
                statement: "Capital position stays conservative", measure: "CET1 ratio", test: "above 14%"),
        Pattern(keywords: ["debt", "leverage", "gearing", "borrowing"], kinds: nil,
                statement: "Leverage stays conservative", measure: "Leverage", test: "not rising"),
        Pattern(keywords: ["net interest margin", "nim", "interest rate", "rates"], kinds: [.bank],
                statement: "Net interest margin holds up", measure: "Net interest margin", test: "above 1.9%"),

        // REIT specifics
        Pattern(keywords: ["occupancy", "tenant", "tenants", "leases", "landlord"], kinds: [.reit],
                statement: "Occupancy stays high", measure: "Portfolio occupancy", test: "above 95%"),
        Pattern(keywords: ["nav", "book", "asset value", "near book", "below book"], kinds: nil,
                statement: "Trades near or below book value", measure: "Price to book", test: "below 1.5×"),
        Pattern(keywords: ["financing", "cost of debt", "refinanc"], kinds: [.reit],
                statement: "Financing cost stays contained", measure: "Average cost of debt", test: "below 3.5%"),

        // Quality and position
        Pattern(keywords: ["moat", "dominant", "leading", "market share", "franchise", "brand"], kinds: nil,
                statement: "The competitive position holds", measure: "Market position", test: "not eroding"),
        Pattern(keywords: ["management", "ceo", "leadership", "turnaround"], kinds: nil,
                statement: "Management keeps executing", measure: "Guidance delivery", test: "met or exceeded"),
        Pattern(keywords: ["cash flow", "fcf", "free cash"], kinds: nil,
                statement: "Free cash flow keeps growing", measure: "Free cash flow", test: "growing"),
        Pattern(keywords: ["buyback", "repurchase", "capital return"], kinds: nil,
                statement: "Capital returns continue", measure: "Capital returned", test: "not reduced"),
        Pattern(keywords: ["cheap", "undervalued", "valuation", "expensive", "reasonable", "fair value"], kinds: nil,
                statement: "Valuation stays reasonable", measure: "Valuation multiple", test: "within historical range")
    ]

    /// Which fragment of the user's sentence triggered a match — shown back to
    /// them so the extraction never feels like it came from nowhere.
    private static func sourcePhrase(in text: String, keyword: String) -> String {
        let lower = text.lowercased()
        guard let range = lower.range(of: keyword) else { return keyword }
        // Widen to the surrounding comma-delimited clause.
        let separators = CharacterSet(charactersIn: ",.;")
        var start = range.lowerBound
        while start > lower.startIndex {
            let prev = lower.index(before: start)
            if let scalar = lower[prev].unicodeScalars.first, separators.contains(scalar) { break }
            start = prev
        }
        var end = range.upperBound
        while end < lower.endIndex {
            if let scalar = lower[end].unicodeScalars.first, separators.contains(scalar) { break }
            end = lower.index(after: end)
        }
        return text[start..<end].trimmingCharacters(in: .whitespaces)
    }

    static func extract(from text: String, kind: BusinessKind) -> [Candidate] {
        let lower = text.lowercased()
        var found: [Candidate] = []
        var seenStatements = Set<String>()

        // A clause can only justify one condition. Without this, "growing
        // wealth-management business" produces a wealth condition, a growth
        // condition and a management condition — three claims from one phrase,
        // which makes the thesis look padded and the extraction look careless.
        var claimedPhrases = Set<String>()

        for pattern in patterns {
            if let kinds = pattern.kinds, !kinds.contains(kind) { continue }
            guard !seenStatements.contains(pattern.statement) else { continue }

            // Take the first keyword that points at a clause nothing else has
            // already used, so a later keyword can still rescue the pattern.
            let hit = pattern.keywords.first { keyword in
                guard lower.contains(keyword) else { return false }
                return !claimedPhrases.contains(sourcePhrase(in: text, keyword: keyword).lowercased())
            }
            guard let hit else { continue }

            let phrase = sourcePhrase(in: text, keyword: hit)
            claimedPhrases.insert(phrase.lowercased())
            seenStatements.insert(pattern.statement)
            found.append(
                Candidate(
                    statement: pattern.statement,
                    measure: pattern.measure,
                    test: pattern.test,
                    source: phrase
                )
            )
        }

        // A thesis with one condition is not a thesis. Top up with the checks
        // that matter for this kind of business, marked as suggestions.
        if found.count < 4 {
            for fallback in defaults(for: kind) where !seenStatements.contains(fallback.statement) {
                seenStatements.insert(fallback.statement)
                found.append(fallback)
                if found.count >= 4 { break }
            }
        }

        // Valuation is always tracked. It is the condition people most often
        // leave out of their own reasoning and most often regret leaving out.
        if !seenStatements.contains(where: { $0.contains("Valuation") || $0.contains("book value") }) {
            found.append(
                Candidate(
                    statement: "Valuation stays reasonable",
                    measure: kind.anchorShort,
                    test: "within historical range",
                    source: "Added by Rerate"
                )
            )
        }

        return Array(found.prefix(6))
    }

    private static func defaults(for kind: BusinessKind) -> [Candidate] {
        switch kind {
        case .bank:
            [
                Candidate(statement: "Return on equity stays above 15%", measure: "Return on equity", test: "above 15%", source: "Added by Rerate"),
                Candidate(statement: "Credit quality stays strong", measure: "Non-performing loans", test: "below 1.5%", source: "Added by Rerate"),
                Candidate(statement: "The dividend stays attractive", measure: "Dividend yield", test: "above 4.5%", source: "Added by Rerate")
            ]
        case .reit:
            [
                Candidate(statement: "Distributions stay steady", measure: "Distribution per unit", test: "not falling", source: "Added by Rerate"),
                Candidate(statement: "Occupancy stays high", measure: "Portfolio occupancy", test: "above 95%", source: "Added by Rerate"),
                Candidate(statement: "Gearing stays conservative", measure: "Aggregate leverage", test: "below 42%", source: "Added by Rerate")
            ]
        case .telecom, .industrial:
            [
                Candidate(statement: "Free cash flow keeps growing", measure: "Free cash flow", test: "growing", source: "Added by Rerate"),
                Candidate(statement: "The dividend stays attractive", measure: "Dividend yield", test: "above 4.5%", source: "Added by Rerate"),
                Candidate(statement: "Margins hold or improve", measure: "Operating margin", test: "not falling", source: "Added by Rerate")
            ]
        case .matureTech:
            [
                Candidate(statement: "Free cash flow keeps growing", measure: "Free cash flow", test: "growing", source: "Added by Rerate"),
                Candidate(statement: "Margins hold or improve", measure: "Operating margin", test: "not falling", source: "Added by Rerate"),
                Candidate(statement: "The competitive position holds", measure: "Market position", test: "not eroding", source: "Added by Rerate")
            ]
        }
    }
}
