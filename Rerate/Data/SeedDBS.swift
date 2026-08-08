import Foundation

// The DBS position is the demonstration case. Every figure below is internally
// consistent: price = book value per share × price-to-book, at every date, so
// the decomposition on the "Explain the move" screen is arithmetic rather than
// a story fitted after the fact.
//
// Figures are illustrative and are labelled as such in the app.

func makeDate(_ y: Int, _ m: Int, _ d: Int) -> Date {
    var c = DateComponents()
    c.year = y; c.month = m; c.day = d
    c.hour = 9
    return Calendar(identifier: .gregorian).date(from: c) ?? Date()
}

enum SeedDBS {
    static let purchaseDate = makeDate(2024, 7, 18)

    // Price = BVPS × P/B holds at each of these dates.
    static let cost = 39.69
    static let bvpsAtPurchase = 18.90     // → 2.10× book
    static let priceNow = 76.00
    static let bvpsNow = 23.75            // → 3.20× book
    static let bvpsAtLastReview = 23.35   // → 2.92× book at S$68.20

    static let monthlyCloses: [Double] = [
        39.69, 40.85, 41.60, 40.90, 42.30, 43.75,
        43.20, 44.10, 45.80, 47.20, 46.40, 48.90,
        51.30, 53.60, 52.40, 55.10, 58.40, 57.20,
        59.90, 62.40, 64.80, 66.10, 68.20, 69.90,
        72.40, 76.00
    ]

    static var priceHistory: [PricePoint] {
        let cal = Calendar(identifier: .gregorian)
        let n = monthlyCloses.count
        return monthlyCloses.enumerated().map { i, close in
            let t = Double(i) / Double(n - 1)
            return PricePoint(
                id: i,
                date: cal.date(byAdding: .month, value: i, to: purchaseDate) ?? purchaseDate,
                price: close,
                anchor: bvpsAtPurchase + (bvpsNow - bvpsAtPurchase) * t
            )
        }
    }

    // MARK: Conditions

    static var conditions: [ThesisCondition] {
        [
            ThesisCondition(
                statement: "Return on equity stays above 15%",
                measure: "Return on equity",
                test: "above 15%",
                status: .passing,
                reading: "17.9%",
                previousReading: "17.8%",
                evidence: "Trailing twelve-month ROE of 17.9%, against a ten-year average of 12.4%. The improvement has held for nine consecutive quarters, through both rising and falling rates."
            ),
            ThesisCondition(
                statement: "Wealth management keeps compounding",
                measure: "Wealth AUM",
                test: "growing",
                status: .passing,
                reading: "+18% y/y",
                previousReading: "+16% y/y",
                evidence: "Assets under management reached S$396b, up from S$318b at your purchase. Fee income from wealth grew 21% year on year and now contributes a larger share of group income than at any point in the past decade."
            ),
            ThesisCondition(
                statement: "Credit quality stays strong",
                measure: "Non-performing loans",
                test: "below 1.5%",
                status: .passing,
                reading: "1.0%",
                previousReading: "1.0%",
                evidence: "NPL ratio of 1.0%, specific provisions of 13bp of loans, and allowance coverage above 125%. No deterioration in the commercial property or SME books."
            ),
            ThesisCondition(
                statement: "The dividend stays attractive",
                measure: "Dividend yield",
                test: "above 4.5%",
                status: .warning,
                reading: "3.8%",
                previousReading: "4.0%",
                evidence: "Dividends per share have risen from S$1.92 to S$2.88 since your purchase — the payout itself has strengthened. The yield has fallen only because the price rose faster. On your cost the yield is 7.3%; on today's price a new buyer receives 3.8%."
            ),
            ThesisCondition(
                statement: "Valuation stays reasonable",
                measure: "Price to book",
                test: "below 2.5× book",
                status: .failing,
                reading: "3.20×",
                previousReading: "2.92×",
                evidence: "DBS trades at 3.20× book. It has spent most of the past decade between 1.1× and 1.6×, and your own purchase was at 2.10×. This is the highest multiple the bank has carried in its listed history."
            )
        ]
    }

    // MARK: Metrics

    static var metrics: [Metric] {
        [
            Metric(name: "Return on equity", value: 17.9, atPurchase: 15.4, atLastReview: 17.8,
                   unit: .percent, direction: .higherIsBetter,
                   note: "Ten-year average 12.4%"),
            Metric(name: "Net interest margin", value: 2.02, atPurchase: 2.14, atLastReview: 2.08,
                   unit: .percent, direction: .higherIsBetter,
                   note: "Easing as policy rates come down — the clearest headwind in the numbers"),
            Metric(name: "Fee income growth", value: 21.4, atPurchase: 8.2, atLastReview: 17.6,
                   unit: .percent, direction: .higherIsBetter,
                   note: "Increasingly offsetting margin pressure"),
            Metric(name: "Wealth management AUM", value: 396, atPurchase: 318, atLastReview: 372,
                   unit: .billions, direction: .higherIsBetter, note: nil),
            Metric(name: "Cost to income", value: 38.6, atPurchase: 40.2, atLastReview: 39.1,
                   unit: .percent, direction: .lowerIsBetter, note: nil),
            Metric(name: "Non-performing loans", value: 1.0, atPurchase: 1.1, atLastReview: 1.0,
                   unit: .percent, direction: .lowerIsBetter, note: nil),
            Metric(name: "CET1 capital ratio", value: 15.8, atPurchase: 14.4, atLastReview: 15.5,
                   unit: .percent, direction: .higherIsBetter,
                   note: "Comfortably above requirement — supports continued buybacks"),
            Metric(name: "Book value per share", value: 23.75, atPurchase: 18.90, atLastReview: 23.35,
                   unit: .currency, direction: .higherIsBetter, note: nil),
            Metric(name: "Earnings per share", value: 4.25, atPurchase: 2.91, atLastReview: 4.16,
                   unit: .currency, direction: .higherIsBetter, note: nil),
            Metric(name: "Dividend per share", value: 2.88, atPurchase: 1.92, atLastReview: 2.70,
                   unit: .currency, direction: .higherIsBetter, note: "Annualised, including specials"),
            Metric(name: "Dividend yield", value: 3.79, atPurchase: 4.84, atLastReview: 3.96,
                   unit: .percent, direction: .higherIsBetter,
                   note: "7.3% measured against your cost"),
            Metric(name: "Price to book", value: 3.20, atPurchase: 2.10, atLastReview: 2.92,
                   unit: .multiple, direction: .lowerIsBetter,
                   note: "Ten-year range 1.06×–1.63×")
        ]
    }

    // MARK: Lenses on the move

    static var lenses: [MoveLens] {
        [
            MoveLens(
                name: "Against book value",
                anchorName: "Book value per share",
                multipleName: "Price to book",
                anchorStart: bvpsAtPurchase, anchorEnd: bvpsNow,
                multipleStart: 2.10, multipleEnd: 3.20,
                anchorUnit: .currency,
                explanation: "A bank is a pile of equity earning a return. Book value per share is what the bank has built; price to book is what investors will pay for each dollar of it. Read this way, most of your gain came from the second."
            ),
            MoveLens(
                name: "Against earnings",
                anchorName: "Earnings per share",
                multipleName: "Price to earnings",
                anchorStart: 2.91, anchorEnd: 4.25,
                multipleStart: 13.64, multipleEnd: 17.88,
                anchorUnit: .currency,
                explanation: "Measured against profit instead, the business looks like it did more of the work. Both readings are correct. The gap between them is the point: DBS did not just grow its equity, it started earning far more on each dollar of it."
            )
        ]
    }

    // MARK: Why the multiple expanded

    static var reratingDrivers: [ReratingDriver] {
        [
            ReratingDriver(
                name: "The bank earns more on each dollar of equity",
                kind: .evidence,
                confidence: .strong,
                summary: "ROE moved from 15.4% to 17.9%, and from a ten-year average of 12.4%.",
                detail: "This is the one driver that is not a matter of opinion. A business earning 17.9% on equity is genuinely worth a higher multiple of that equity than one earning 12%. Some of the re-rating is simply the market correcting a valuation set for a lower-return bank. The open question is not whether this justifies a higher multiple, but whether it justifies this one."
            ),
            ReratingDriver(
                name: "Earnings expectations were revised upward",
                kind: .evidence,
                confidence: .strong,
                summary: "Consensus earnings for the current year rose roughly 24% over the past eighteen months.",
                detail: "Analysts have repeatedly under-forecast fee income and over-forecast the speed of margin decline. Upgrades of this size mechanically lift the price even with no change in the multiple investors are willing to apply."
            ),
            ReratingDriver(
                name: "Institutional and index-linked buying",
                kind: .evidence,
                confidence: .moderate,
                summary: "Institutions were net buyers of roughly S$2.1b over six months while retail investors sold into strength.",
                detail: "Reported net institutional purchases across Singapore banks have been sustained rather than episodic. A rising index weight also creates mechanical demand from passive funds. Flow data tells you who transacted; it does not by itself tell you why, and it cannot separate conviction from mandate."
            ),
            ReratingDriver(
                name: "Falling policy rates made the dividend more valuable",
                kind: .interpretation,
                confidence: .moderate,
                summary: "As deposit and bond yields fell, a growing 3.8% dividend became relatively more attractive.",
                detail: "This cuts both ways and the app will not pretend otherwise. Lower rates compress net interest margin, which is a genuine negative for the earnings line — and the margin has indeed fallen from 2.14% to 2.02%. But they also lower the yield available elsewhere, which supports the multiple. The market appears, so far, to have weighted the second effect more heavily than the first."
            ),
            ReratingDriver(
                name: "A scarcity premium for quality in a small market",
                kind: .interpretation,
                confidence: .weak,
                summary: "Singapore offers few large, liquid, high-return financials.",
                detail: "A plausible reading, but not one that can be evidenced from the data available here. Scarcity arguments tend to appear near the top of re-ratings, precisely because they explain a high price without requiring anything further from the business. Treat this as a hypothesis, not a finding."
            ),
            ReratingDriver(
                name: "Retail attention",
                kind: .uncertainty,
                confidence: .weak,
                summary: "Attention has clearly risen. The evidence does not support retail buying as the cause of the move.",
                detail: "Search interest, forum mentions and brokerage coverage have all increased. But retail investors were net sellers of roughly S$680m over the same six months. Rising attention alongside net retail selling is a fairly common pattern late in a re-rating: people notice a stock because it went up, not before. It is worth watching as a signal of crowding, not as an explanation of the gain."
            )
        ]
    }

    // MARK: Flows

    static var flowEvidence: [FlowEvidence] {
        [
            FlowEvidence(actor: "Institutions", direction: "Net buyers", magnitude: "≈ S$2.1b",
                         window: "Trailing 6 months", confidence: .strong,
                         note: "Sustained across most weeks rather than concentrated in a few sessions."),
            FlowEvidence(actor: "Retail", direction: "Net sellers", magnitude: "≈ S$680m",
                         window: "Trailing 6 months", confidence: .strong,
                         note: "Selling into strength — the opposite of what the current conversation would suggest."),
            FlowEvidence(actor: "Foreign investors", direction: "Net buyers", magnitude: "≈ S$1.4b",
                         window: "Trailing 6 months", confidence: .moderate,
                         note: "Part of a broader return to Singapore equities; hard to attribute to DBS specifically."),
            FlowEvidence(actor: "Passive and index funds", direction: "Mechanical buying", magnitude: "Not separable",
                         window: "Trailing 12 months", confidence: .moderate,
                         note: "Index weight rose with market capitalisation, creating demand unrelated to any view on the bank."),
            FlowEvidence(actor: "Insiders", direction: "No material activity", magnitude: "—",
                         window: "Trailing 12 months", confidence: .moderate,
                         note: "No unusual disposals or purchases disclosed. Absence of a signal, not a positive one.")
        ]
    }

    // MARK: Scenarios

    static var scenarios: [Scenario] {
        [
            Scenario(
                name: "Normalisation",
                premise: "Returns drift back toward the bank's own history.",
                roe: 0.130, growth: 0.030, requiredReturn: 0.095,
                reasoning: "Margins continue to compress as rates fall, wealth fee growth slows to mid-single digits, and credit costs return to a normal part of the cycle. Nothing breaks — the bank simply stops being exceptional. This is not a bear case so much as the absence of a bull one.",
                whatWouldMakeItTrue: [
                    "Net interest margin below 1.85%",
                    "Wealth fee growth slowing under 8%",
                    "Credit costs returning toward 25–30bp"
                ]
            ),
            Scenario(
                name: "Strong franchise",
                premise: "The improvement is real but not permanent at today's level.",
                roe: 0.165, growth: 0.040, requiredReturn: 0.090,
                reasoning: "Wealth management keeps compounding and the deposit franchise holds, but returns settle a little below today's peak as the rate cycle turns. The bank stays clearly better than it was in the 2015–2020 period without matching the last two years.",
                whatWouldMakeItTrue: [
                    "Wealth AUM growth sustained near 12–15%",
                    "Cost to income held under 40%",
                    "Margin stabilising near 1.95%"
                ]
            ),
            Scenario(
                name: "Exceptional compounder",
                premise: "This is a structurally different bank now.",
                roe: 0.190, growth: 0.050, requiredReturn: 0.085,
                reasoning: "Fee and wealth income permanently re-weight the mix away from interest rates, returns hold near 19%, and investors accept a lower required return because earnings have become more predictable. This is what today's price is closest to assuming.",
                whatWouldMakeItTrue: [
                    "Fee income above 40% of group income",
                    "ROE holding above 18% through a full rate cycle",
                    "Wealth AUM compounding above 15% for several more years"
                ]
            )
        ]
    }

    // MARK: Memory

    static var reviews: [Review] {
        [
            Review(
                date: makeDate(2025, 2, 22), price: 44.10, anchorMultiple: 2.19, headlineMetric: 16.2,
                conclusion: "The business is doing what you expected. Returns are improving faster than you assumed and wealth management is compounding. The multiple has moved up but is still defensible against the improvement in returns. Nothing here needs action.",
                thesisState: .intact, conditionsIntact: 5, conditionsTotal: 5,
                prompt: nil
            ),
            Review(
                date: makeDate(2025, 11, 14), price: 58.40, anchorMultiple: 2.68, headlineMetric: 17.4,
                conclusion: "Wealth management has inflected and returns are now well clear of anything the bank has sustained before. But the multiple has left its historical range entirely. For the first time, the price is no longer explained by the business alone. Your valuation condition has broken; the other four are intact.",
                thesisState: .mostlyIntact, conditionsIntact: 4, conditionsTotal: 5,
                prompt: "The stock has run hard. Am I just anchoring on my purchase price?"
            ),
            Review(
                date: makeDate(2026, 5, 9), price: 68.20, anchorMultiple: 2.92, headlineMetric: 17.8,
                conclusion: "Almost nothing changed in the bank this period. Book value grew a little, returns held, credit stayed clean. The price moved because the multiple moved. The dividend yield has now compressed enough to put your income condition under pressure. Valuation is no longer one risk among several — it is the risk.",
                thesisState: .mostlyIntact, conditionsIntact: 4, conditionsTotal: 5,
                prompt: "Is this still about the bank, or about the market?"
            )
        ]
    }

    // MARK: Arguments

    static var bullCase: Argument {
        Argument(
            title: "The case for still owning it",
            stance: "DBS has become a structurally better business, and the market is repricing that rather than speculating.",
            points: [
                ArgumentPoint(
                    claim: "The return on equity improvement is real and durable",
                    kind: .evidence,
                    support: "17.9% ROE sustained across nine quarters, spanning both rising and falling rates. That is not a rate-cycle artefact."
                ),
                ArgumentPoint(
                    claim: "The earnings mix has genuinely changed",
                    kind: .evidence,
                    support: "Wealth AUM up from S$318b to S$396b, fee income growing 21%. Fee income is less rate-sensitive and deserves a higher multiple than spread income."
                ),
                ArgumentPoint(
                    claim: "A higher multiple is arithmetically justified by a higher ROE",
                    kind: .interpretation,
                    support: "A bank earning 17.9% instead of 12.4% on equity should trade at a materially higher multiple of that equity. Some of the re-rating is correction, not excess."
                ),
                ArgumentPoint(
                    claim: "The buyers are the patient kind",
                    kind: .interpretation,
                    support: "Institutions net bought roughly S$2.1b while retail sold. Re-ratings driven by institutional accumulation tend to unwind less violently than retail-driven ones."
                ),
                ArgumentPoint(
                    claim: "Capital returns are still growing",
                    kind: .evidence,
                    support: "Dividend per share up from S$1.92 to S$2.88, CET1 at 15.8%, buybacks continuing. The cash return is expanding, not being financed by leverage."
                )
            ],
            invalidatedBy: "ROE falling below roughly 15% for two consecutive quarters, or wealth fee growth stalling into single digits. Either would remove the basis for the multiple."
        )
    }

    static var bearCase: Argument {
        Argument(
            title: "The strongest case against",
            stance: "You are being paid today for returns the bank has only recently achieved and may not sustain, at a multiple that leaves no room for that to be wrong.",
            points: [
                ArgumentPoint(
                    claim: "Today's price requires roughly 20% sustained return on equity",
                    kind: .evidence,
                    support: "At 3.20× book, with 4% growth and a 9% required return, the implied sustainable ROE is about 20% — above the current 17.9% and far above the ten-year average of 12.4%."
                ),
                ArgumentPoint(
                    claim: "The margin tailwind has already turned",
                    kind: .evidence,
                    support: "Net interest margin has fallen from 2.14% to 2.02% and policy rates are still easing. Much of the ROE improvement was helped by a rate cycle that is now working the other way."
                ),
                ArgumentPoint(
                    claim: "Two-thirds of your gain is re-rating, not earnings",
                    kind: .evidence,
                    support: "Book value per share grew 26% since your purchase. The multiple grew 52%. Re-rating is the part of a return that can be taken back without the business doing anything wrong."
                ),
                ArgumentPoint(
                    claim: "Wealth management growth is partly a bull-market effect",
                    kind: .interpretation,
                    support: "AUM rises when markets rise, and fee income rises with AUM. Some portion of the wealth growth is a function of asset prices rather than net new client money, and would reverse in a drawdown."
                ),
                ArgumentPoint(
                    claim: "The safety margin is gone",
                    kind: .interpretation,
                    support: "At 2.10× book you had a business improving into a modest valuation. At 3.20× a mild disappointment and a mild de-rating multiply together. The same news is worth more against you now than it was then."
                )
            ],
            invalidatedBy: "ROE holding above 18% through a full rate-cutting cycle while fee income share keeps rising. That would show the improvement is structural rather than cyclical, and the multiple would stop looking like an assumption."
        )
    }

    // MARK: The holding

    static var holding: Holding {
        Holding(
            ticker: "D05",
            name: "DBS Group",
            exchange: "SGX",
            currency: "S$",
            kind: .bank,
            averageCost: cost,
            shares: 1200,
            purchaseDate: purchaseDate,
            originalReasoning: "Strong Singapore bank, attractive dividend, high ROE, growing wealth-management business, long-term compounder.",
            price: priceNow,
            anchorPerShare: bvpsNow,
            anchorAtPurchase: bvpsAtPurchase,
            anchorAtLastReview: bvpsAtLastReview,
            dividendsPerShareSincePurchase: 5.42,
            business: .strong,
            valuation: .stretched,
            sentiment: .heating,
            flows: .institutional,
            attention: .reviewRequired,
            conditions: conditions,
            metrics: metrics,
            flowEvidence: flowEvidence,
            scenarios: scenarios,
            reviews: reviews,
            lenses: lenses,
            reratingDrivers: reratingDrivers,
            bullCase: bullCase,
            bearCase: bearCase,
            mostUncertainAssumption: "Whether a 17–18% return on equity survives a full rate-cutting cycle. Everything else in both cases follows from this one number, and it is the number with the least history behind it.",
            situation: "The bank improved. The market improved its opinion of the bank considerably more.",
            whatChangedSummary: "DBS is a genuinely better business than when you bought it — returns, fee mix and capital have all strengthened. But roughly two-thirds of your gain came from investors paying more for each dollar of book value, not from the bank producing more of it.",
            priceHistory: priceHistory
        )
    }
}
