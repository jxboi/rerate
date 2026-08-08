import Foundation

/// Builds a plausible monthly path that starts and ends exactly where the
/// position says it does, so charts never contradict the figures.
func buildHistory(
    from: Date,
    months: Int,
    startPrice: Double,
    endPrice: Double,
    startAnchor: Double,
    endAnchor: Double,
    shape: [Double]
) -> [PricePoint] {
    let cal = Calendar(identifier: .gregorian)
    return (0..<months).map { i in
        let t = Double(i) / Double(max(months - 1, 1))
        let wobble = shape.isEmpty ? 0 : shape[i % shape.count] * (1 - abs(t - 0.5) * 0.6)
        let base = startPrice + (endPrice - startPrice) * t
        let price = i == 0 ? startPrice : (i == months - 1 ? endPrice : base * (1 + wobble))
        return PricePoint(
            id: i,
            date: cal.date(byAdding: .month, value: i, to: from) ?? from,
            price: price,
            anchor: startAnchor + (endAnchor - startAnchor) * t
        )
    }
}

enum SeedOCBC {
    static var holding: Holding {
        let purchase = makeDate(2023, 9, 12)
        return Holding(
            ticker: "O39",
            name: "OCBC",
            exchange: "SGX",
            currency: "S$",
            kind: .bank,
            averageCost: 12.60,
            shares: 3000,
            purchaseDate: purchase,
            originalReasoning: "Well capitalised, cheaper than DBS, decent dividend, Great Eastern gives some diversification away from pure lending.",
            price: 18.40,
            anchorPerShare: 12.95,
            anchorAtPurchase: 11.20,
            anchorAtLastReview: 12.80,
            dividendsPerShareSincePurchase: 2.34,
            business: .strong,
            valuation: .fair,
            sentiment: .normal,
            flows: .broad,
            attention: .noChange,
            conditions: [
                ThesisCondition(statement: "Capital position stays conservative", measure: "CET1 ratio",
                                test: "above 14%", status: .passing, reading: "16.1%", previousReading: "15.9%",
                                evidence: "CET1 of 16.1%, the highest of the three local banks. Supports the dividend without needing earnings growth."),
                ThesisCondition(statement: "Dividend keeps rising", measure: "Dividend per share",
                                test: "growing", status: .passing, reading: "S$0.94", previousReading: "S$0.90",
                                evidence: "Ordinary dividend raised again this year, with the payout ratio held near 50%."),
                ThesisCondition(statement: "Insurance earnings stay steady", measure: "Great Eastern contribution",
                                test: "stable", status: .warning, reading: "−6% y/y", previousReading: "+2% y/y",
                                evidence: "Insurance profit fell on mark-to-market movements. Underlying new business value still grew, so this may be noise rather than deterioration."),
                ThesisCondition(statement: "Cheaper than DBS on book", measure: "Price to book",
                                test: "below 1.6×", status: .passing, reading: "1.42×", previousReading: "1.38×",
                                evidence: "1.42× book against DBS at 3.20×. The discount has widened, not narrowed, since your purchase."),
                ThesisCondition(statement: "Return on equity stays above 12%", measure: "Return on equity",
                                test: "above 12%", status: .passing, reading: "13.8%", previousReading: "13.1%",
                                evidence: "Returns improved with the rate cycle and have held better than expected as rates eased.")
            ],
            metrics: [
                Metric(name: "Return on equity", value: 13.8, atPurchase: 13.1, atLastReview: 13.5, unit: .percent, direction: .higherIsBetter, note: nil),
                Metric(name: "Net interest margin", value: 2.16, atPurchase: 2.28, atLastReview: 2.20, unit: .percent, direction: .higherIsBetter, note: nil),
                Metric(name: "CET1 capital ratio", value: 16.1, atPurchase: 14.8, atLastReview: 15.9, unit: .percent, direction: .higherIsBetter, note: nil),
                Metric(name: "Non-performing loans", value: 0.9, atPurchase: 1.0, atLastReview: 0.9, unit: .percent, direction: .lowerIsBetter, note: nil),
                Metric(name: "Book value per share", value: 12.95, atPurchase: 11.20, atLastReview: 12.80, unit: .currency, direction: .higherIsBetter, note: nil),
                Metric(name: "Dividend yield", value: 5.11, atPurchase: 6.51, atLastReview: 5.34, unit: .percent, direction: .higherIsBetter, note: "6.7% against your cost"),
                Metric(name: "Price to book", value: 1.42, atPurchase: 1.13, atLastReview: 1.38, unit: .multiple, direction: .lowerIsBetter, note: "Ten-year range 0.87×–1.45×")
            ],
            flowEvidence: [
                FlowEvidence(actor: "Institutions", direction: "Modest net buying", magnitude: "≈ S$310m", window: "Trailing 6 months", confidence: .moderate, note: "Nothing unusual in scale or pace."),
                FlowEvidence(actor: "Retail", direction: "Roughly balanced", magnitude: "—", window: "Trailing 6 months", confidence: .moderate, note: "No sign of crowding in either direction."),
                FlowEvidence(actor: "Insiders", direction: "No material activity", magnitude: "—", window: "Trailing 12 months", confidence: .moderate, note: "")
            ],
            scenarios: [
                Scenario(name: "Normalisation", premise: "Returns drift back to the long-run average.",
                         roe: 0.115, growth: 0.025, requiredReturn: 0.090,
                         reasoning: "Margins keep compressing and insurance stays choppy. Returns settle near the pre-2022 level.",
                         whatWouldMakeItTrue: ["Margin below 2.0%", "Insurance earnings falling further"]),
                Scenario(name: "Strong franchise", premise: "The bank holds most of its gains.",
                         roe: 0.132, growth: 0.035, requiredReturn: 0.088,
                         reasoning: "Capital stays high, credit stays clean, dividends keep rising modestly.",
                         whatWouldMakeItTrue: ["ROE held near 13%", "Payout ratio maintained near 50%"]),
                Scenario(name: "Re-rating toward peers", premise: "The discount to DBS narrows.",
                         roe: 0.145, growth: 0.040, requiredReturn: 0.085,
                         reasoning: "Investors decide the capital buffer and insurance arm deserve more credit than they currently receive.",
                         whatWouldMakeItTrue: ["Sustained ROE above 14%", "Clearer disclosure on insurance value"])
            ],
            reviews: [
                Review(date: makeDate(2024, 10, 3), price: 15.20, anchorMultiple: 1.27, headlineMetric: 13.4,
                       conclusion: "Doing exactly what you bought it for. Capital is strong, the dividend rose, and the valuation is still inside its historical range.",
                       thesisState: .intact, conditionsIntact: 5, conditionsTotal: 5, prompt: nil),
                Review(date: makeDate(2026, 2, 18), price: 17.60, anchorMultiple: 1.38, headlineMetric: 13.5,
                       conclusion: "Still unremarkable in the best sense. The only soft spot is insurance earnings, which look like mark-to-market noise rather than a change in the business.",
                       thesisState: .intact, conditionsIntact: 5, conditionsTotal: 5, prompt: nil)
            ],
            lenses: [
                MoveLens(name: "Against book value", anchorName: "Book value per share", multipleName: "Price to book",
                         anchorStart: 11.20, anchorEnd: 12.95, multipleStart: 1.125, multipleEnd: 1.421,
                         anchorUnit: .currency,
                         explanation: "A more even split than DBS. The bank built book value and investors paid somewhat more for it, but the multiple is still inside the range it has traded in for a decade."),
                MoveLens(name: "Against earnings", anchorName: "Earnings per share", multipleName: "Price to earnings",
                         anchorStart: 1.52, anchorEnd: 1.79, multipleStart: 8.29, multipleEnd: 10.28,
                         anchorUnit: .currency,
                         explanation: "On earnings the stock still trades near ten times profit — a level that assumes fairly little.")
            ],
            reratingDrivers: [
                ReratingDriver(name: "Sector re-rating", kind: .interpretation, confidence: .moderate,
                               summary: "Singapore banks as a group re-rated; OCBC moved less than DBS.",
                               detail: "Most of OCBC's multiple expansion appears to be sector beta rather than anything specific to the bank. It has lagged DBS throughout, which is consistent with a group move rather than a company-specific reassessment."),
                ReratingDriver(name: "Dividend support", kind: .evidence, confidence: .strong,
                               summary: "A rising dividend became more valuable as rates fell.",
                               detail: "Dividend per share rose while deposit rates fell. At 5.1% the yield is still well above the local risk-free rate, which limits how far the multiple can fall without the stock looking cheap on income alone.")
            ],
            bullCase: Argument(
                title: "The case for still owning it",
                stance: "A conservatively run bank at a normal price, with a yield that does most of the work.",
                points: [
                    ArgumentPoint(claim: "Valuation still sits inside its historical range", kind: .evidence,
                                  support: "1.42× book, against a ten-year range of 0.87×–1.45×. You are not relying on a re-rating that has already happened."),
                    ArgumentPoint(claim: "The capital position is the strongest of the three", kind: .evidence,
                                  support: "CET1 of 16.1% supports the dividend even if earnings fall."),
                    ArgumentPoint(claim: "The discount to DBS has widened", kind: .interpretation,
                                  support: "If the two banks' returns converge at all, the gap between 1.42× and 3.20× book is a large one to defend.")
                ],
                invalidatedBy: "ROE falling below 12% or the dividend being held flat for two years."
            ),
            bearCase: Argument(
                title: "The strongest case against",
                stance: "A perpetually cheap bank can stay cheap, and the discount to DBS may be telling you something true.",
                points: [
                    ArgumentPoint(claim: "The discount has persisted for a decade", kind: .evidence,
                                  support: "OCBC has traded below DBS on book for most of its recent history. A gap that never closes is not an opportunity."),
                    ArgumentPoint(claim: "Insurance makes earnings harder to read", kind: .interpretation,
                                  support: "Great Eastern introduces mark-to-market volatility that investors discount rather than value."),
                    ArgumentPoint(claim: "Returns are structurally lower", kind: .evidence,
                                  support: "13.8% against DBS at 17.9%. Some of the valuation gap is simply arithmetic.")
                ],
                invalidatedBy: "Sustained ROE above 14% alongside clearer insurance disclosure."
            ),
            mostUncertainAssumption: "Whether the discount to DBS is a mispricing or an accurate reflection of a lower-return business. Your thesis quietly assumes the first.",
            situation: "Doing what it was bought to do. Nothing here needs your attention.",
            whatChangedSummary: "Book value grew, the dividend rose, and the multiple moved up modestly but stayed inside its normal range. This is the ordinary version of what DBS did dramatically.",
            priceHistory: buildHistory(from: purchase, months: 36, startPrice: 12.60, endPrice: 18.40,
                                       startAnchor: 11.20, endAnchor: 12.95,
                                       shape: [0.01, -0.015, 0.02, 0.005, -0.01, 0.018])
        )
    }
}

enum SeedSingtel {
    static var holding: Holding {
        let purchase = makeDate(2023, 5, 4)
        return Holding(
            ticker: "Z74",
            name: "Singtel",
            exchange: "SGX",
            currency: "S$",
            kind: .telecom,
            averageCost: 2.48,
            shares: 12000,
            purchaseDate: purchase,
            originalReasoning: "Turnaround under new management, asset recycling should surface value, dividend recovering, regional associates worth more than the market credits.",
            price: 3.42,
            anchorPerShare: 0.198,
            anchorAtPurchase: 0.142,
            anchorAtLastReview: 0.190,
            dividendsPerShareSincePurchase: 0.34,
            business: .strong,
            valuation: .fair,
            sentiment: .normal,
            flows: .broad,
            attention: .noChange,
            conditions: [
                ThesisCondition(statement: "Underlying earnings keep recovering", measure: "Earnings per share",
                                test: "growing", status: .passing, reading: "19.8¢", previousReading: "19.0¢",
                                evidence: "Underlying net profit has grown for eleven consecutive halves. The recovery is now longer than the decline that preceded it."),
                ThesisCondition(statement: "Asset recycling continues", measure: "Capital released",
                                test: "ongoing", status: .passing, reading: "S$8.1b to date", previousReading: "S$7.2b",
                                evidence: "Further data-centre and tower stakes monetised, with proceeds returned through the value realisation dividend."),
                ThesisCondition(statement: "Dividend keeps recovering", measure: "Dividend per share",
                                test: "growing", status: .passing, reading: "17.0¢", previousReading: "16.0¢",
                                evidence: "Core plus value realisation dividend now above the pre-decline level."),
                ThesisCondition(statement: "Associates hold their value", measure: "Associate contribution",
                                test: "stable", status: .warning, reading: "−4% y/y", previousReading: "+3% y/y",
                                evidence: "Airtel remains strong but competitive pressure in Indonesia and Thailand has reduced the regional contribution. Currency accounts for roughly half the decline."),
                ThesisCondition(statement: "Valuation stays undemanding", measure: "Price to earnings",
                                test: "below 20×", status: .passing, reading: "17.3×", previousReading: "17.2×",
                                evidence: "The multiple has barely moved since your purchase. Essentially all of your gain came from earnings.")
            ],
            metrics: [
                Metric(name: "Earnings per share", value: 19.8, atPurchase: 14.2, atLastReview: 19.0, unit: .cents, direction: .higherIsBetter, note: "Underlying"),
                Metric(name: "Free cash flow per share", value: 23.9, atPurchase: 17.6, atLastReview: 22.8, unit: .cents, direction: .higherIsBetter, note: nil),
                Metric(name: "EBIT margin", value: 14.2, atPurchase: 11.1, atLastReview: 13.8, unit: .percent, direction: .higherIsBetter, note: nil),
                Metric(name: "Return on invested capital", value: 9.4, atPurchase: 7.1, atLastReview: 9.1, unit: .percent, direction: .higherIsBetter, note: "Management target is above 9%"),
                Metric(name: "Net debt to EBITDA", value: 1.6, atPurchase: 2.1, atLastReview: 1.7, unit: .ratio, direction: .lowerIsBetter, note: nil),
                Metric(name: "Dividend yield", value: 4.97, atPurchase: 4.44, atLastReview: 4.91, unit: .percent, direction: .higherIsBetter, note: "6.9% against your cost"),
                Metric(name: "Price to earnings", value: 17.3, atPurchase: 17.5, atLastReview: 17.2, unit: .multiple, direction: .lowerIsBetter, note: "Almost unchanged since purchase")
            ],
            flowEvidence: [
                FlowEvidence(actor: "Institutions", direction: "Net buyers", magnitude: "≈ S$420m", window: "Trailing 6 months", confidence: .moderate, note: "Steady accumulation, no single large block."),
                FlowEvidence(actor: "Retail", direction: "Net buyers", magnitude: "≈ S$95m", window: "Trailing 6 months", confidence: .moderate, note: "A long-standing retail holding in Singapore; participation is normal rather than elevated."),
                FlowEvidence(actor: "Insiders", direction: "No material activity", magnitude: "—", window: "Trailing 12 months", confidence: .moderate, note: "")
            ],
            scenarios: [
                Scenario(name: "Recovery stalls", premise: "Cost savings run out and associates keep sliding.",
                         roe: 0.075, growth: 0.015, requiredReturn: 0.085,
                         reasoning: "The easy part of the turnaround is done. Without further asset sales, growth flattens.",
                         whatWouldMakeItTrue: ["ROIC falling back under 8%", "Associate contribution declining a further 10%"]),
                Scenario(name: "Target achieved", premise: "Management hits and holds its return target.",
                         roe: 0.098, growth: 0.030, requiredReturn: 0.082,
                         reasoning: "ROIC sustained above 9%, dividend keeps rising, leverage stays low.",
                         whatWouldMakeItTrue: ["ROIC above 9% for two more years", "Continued capital recycling"]),
                Scenario(name: "Re-rated as an infrastructure owner", premise: "Data centres and towers are valued separately.",
                         roe: 0.115, growth: 0.040, requiredReturn: 0.078,
                         reasoning: "The market stops valuing Singtel as a telco and starts valuing the infrastructure assets on their own multiples.",
                         whatWouldMakeItTrue: ["Separate disclosure of infrastructure earnings", "A third-party transaction confirming the valuation"])
            ],
            reviews: [
                Review(date: makeDate(2024, 8, 21), price: 2.92, anchorMultiple: 17.6, headlineMetric: 16.6,
                       conclusion: "The turnaround is showing up in the numbers rather than only in the presentations. Earnings and dividend both moving the right way.",
                       thesisState: .intact, conditionsIntact: 5, conditionsTotal: 5, prompt: nil),
                Review(date: makeDate(2026, 3, 12), price: 3.26, anchorMultiple: 17.2, headlineMetric: 19.0,
                       conclusion: "Unusually clean: the multiple has not moved at all since purchase, so every cent of your gain is earnings the company actually produced. Associates are the one soft area.",
                       thesisState: .intact, conditionsIntact: 5, conditionsTotal: 5, prompt: "Have I just been lucky with the market, or did this actually work?")
            ],
            lenses: [
                MoveLens(name: "Against earnings", anchorName: "Earnings per share", multipleName: "Price to earnings",
                         anchorStart: 0.142, anchorEnd: 0.198, multipleStart: 17.46, multipleEnd: 17.27,
                         anchorUnit: .currency,
                         explanation: "The clean opposite of DBS. Investors are paying almost exactly what they paid at your purchase for each dollar of profit. The entire gain is profit the company did not previously have."),
                MoveLens(name: "Against free cash flow", anchorName: "Free cash flow per share", multipleName: "Price to free cash flow",
                         anchorStart: 0.176, anchorEnd: 0.239, multipleStart: 14.09, multipleEnd: 14.31,
                         anchorUnit: .currency,
                         explanation: "Cash tells the same story as earnings here, which is a good sign — the recovery is not an accounting artefact.")
            ],
            reratingDrivers: [
                ReratingDriver(name: "There was essentially no re-rating", kind: .evidence, confidence: .strong,
                               summary: "The multiple moved from 17.5× to 17.3×.",
                               detail: "This is worth noticing precisely because it is unusual. Nearly all of the return came from the business. A position like this carries far less valuation risk than one where the multiple did the work — but it also means further gains have to be earned rather than granted.")
            ],
            bullCase: Argument(
                title: "The case for still owning it",
                stance: "The turnaround has been delivered in cash, and none of it has been priced in as optimism.",
                points: [
                    ArgumentPoint(claim: "Every cent of the gain was earned", kind: .evidence,
                                  support: "EPS up 39% while the multiple fell slightly. There is no re-rating to give back."),
                    ArgumentPoint(claim: "Cash confirms the earnings", kind: .evidence,
                                  support: "Free cash flow per share grew in line with EPS, so the improvement is not accounting."),
                    ArgumentPoint(claim: "The balance sheet has room", kind: .evidence,
                                  support: "Net debt to EBITDA down from 2.1× to 1.6×, funding both dividends and further investment.")
                ],
                invalidatedBy: "ROIC falling back below 8%, or the value realisation dividend being withdrawn."
            ),
            bearCase: Argument(
                title: "The strongest case against",
                stance: "The recovery was the easy part; what follows is a mature telco with declining associates.",
                points: [
                    ArgumentPoint(claim: "Associates are deteriorating", kind: .evidence,
                                  support: "Regional contribution down 4% year on year, with competitive pressure in two major markets."),
                    ArgumentPoint(claim: "Asset recycling is finite", kind: .interpretation,
                                  support: "Selling assets to fund dividends works until the sellable assets run out. Roughly S$8.1b has already been realised."),
                    ArgumentPoint(claim: "Core telecom is still low growth", kind: .evidence,
                                  support: "Underlying service revenue growth remains in the low single digits.")
                ],
                invalidatedBy: "Associate earnings stabilising while ROIC holds above 9%."
            ),
            mostUncertainAssumption: "Whether regional associates stabilise. They are the largest single earnings contributor and the one you have least visibility into.",
            situation: "The rare case where the market's opinion did not change at all. You simply own more earnings.",
            whatChangedSummary: "Earnings per share grew 39% while the price-to-earnings multiple went nowhere. This position gained almost entirely because the company got better, not because investors got keener.",
            priceHistory: buildHistory(from: purchase, months: 40, startPrice: 2.48, endPrice: 3.42,
                                       startAnchor: 0.142, endAnchor: 0.198,
                                       shape: [-0.02, 0.015, 0.025, -0.018, 0.008, 0.02, -0.012])
        )
    }
}

enum SeedCICT {
    static var holding: Holding {
        let purchase = makeDate(2022, 11, 8)
        return Holding(
            ticker: "C38U",
            name: "CapitaLand Integrated Commercial Trust",
            shortNameOverride: "CICT",
            exchange: "SGX",
            currency: "S$",
            kind: .reit,
            averageCost: 2.12,
            shares: 15000,
            purchaseDate: purchase,
            originalReasoning: "Dominant Singapore retail and office landlord, distributions should be steady, trading near book, sponsor is strong.",
            price: 2.05,
            anchorPerShare: 2.10,
            anchorAtPurchase: 2.16,
            anchorAtLastReview: 2.12,
            dividendsPerShareSincePurchase: 0.42,
            business: .softening,
            valuation: .attractive,
            sentiment: .quiet,
            flows: .unclear,
            attention: .materialChange,
            conditions: [
                ThesisCondition(statement: "Occupancy stays high", measure: "Portfolio occupancy",
                                test: "above 95%", status: .passing, reading: "96.4%", previousReading: "97.1%",
                                evidence: "Retail occupancy is effectively full; the softness is entirely in older office space."),
                ThesisCondition(statement: "Distributions stay steady", measure: "Distribution per unit",
                                test: "not falling", status: .warning, reading: "10.9¢", previousReading: "11.2¢",
                                evidence: "DPU fell 2.7% as higher financing costs absorbed the growth in net property income. Operations improved; the interest bill improved faster."),
                ThesisCondition(statement: "Gearing stays conservative", measure: "Aggregate leverage",
                                test: "below 42%", status: .passing, reading: "39.8%", previousReading: "39.4%",
                                evidence: "Within the regulatory limit and the trust's own stated range, though the buffer is narrower than at purchase."),
                ThesisCondition(statement: "Trades near or below book", measure: "Price to NAV",
                                test: "below 1.05×", status: .passing, reading: "0.98×", previousReading: "1.03×",
                                evidence: "Effectively at net asset value. The market is not paying a premium for the portfolio."),
                ThesisCondition(statement: "Financing cost stays below 3.2%", measure: "Average cost of debt",
                                test: "below 3.2%", status: .failing, reading: "3.6%", previousReading: "3.1%",
                                evidence: "Refinancing of the 2021 tranches completed at materially higher rates. This is the condition you set yourself, and it is the one that broke.",
                                userDefined: true)
            ],
            metrics: [
                Metric(name: "Net asset value per unit", value: 2.10, atPurchase: 2.16, atLastReview: 2.12, unit: .currency, direction: .higherIsBetter, note: "Modest revaluation losses on older office assets"),
                Metric(name: "Distribution per unit", value: 10.9, atPurchase: 10.4, atLastReview: 11.2, unit: .cents, direction: .higherIsBetter, note: "Annualised"),
                Metric(name: "Distribution yield", value: 5.32, atPurchase: 4.91, atLastReview: 5.14, unit: .percent, direction: .higherIsBetter, note: nil),
                Metric(name: "Aggregate leverage", value: 39.8, atPurchase: 40.6, atLastReview: 39.4, unit: .percent, direction: .lowerIsBetter, note: nil),
                Metric(name: "Average cost of debt", value: 3.6, atPurchase: 2.4, atLastReview: 3.1, unit: .percent, direction: .lowerIsBetter, note: "The single largest change in this position"),
                Metric(name: "Interest coverage", value: 3.1, atPurchase: 4.6, atLastReview: 3.5, unit: .ratio, direction: .higherIsBetter, note: nil),
                Metric(name: "Portfolio occupancy", value: 96.4, atPurchase: 95.8, atLastReview: 97.1, unit: .percent, direction: .higherIsBetter, note: nil),
                Metric(name: "Net property income growth", value: 3.8, atPurchase: 2.1, atLastReview: 4.2, unit: .percent, direction: .higherIsBetter, note: "The properties are performing"),
                Metric(name: "Price to NAV", value: 0.98, atPurchase: 0.98, atLastReview: 1.03, unit: .multiple, direction: .lowerIsBetter, note: "Essentially unchanged since purchase")
            ],
            flowEvidence: [
                FlowEvidence(actor: "Institutions", direction: "Net sellers", magnitude: "≈ S$180m", window: "Trailing 6 months", confidence: .moderate, note: "Consistent with broad rotation out of rate-sensitive income vehicles."),
                FlowEvidence(actor: "Retail", direction: "Net buyers", magnitude: "≈ S$120m", window: "Trailing 6 months", confidence: .moderate, note: "Retail has been absorbing institutional supply — the reverse of the DBS pattern."),
                FlowEvidence(actor: "Insiders and sponsor", direction: "No material activity", magnitude: "—", window: "Trailing 12 months", confidence: .weak, note: "Sponsor stake unchanged.")
            ],
            scenarios: [
                Scenario(name: "Rates stay high for longer", premise: "The remaining debt refinances at current rates.",
                         roe: 0.052, growth: 0.005, requiredReturn: 0.075,
                         reasoning: "Cost of debt rises toward 4% as the last of the cheap tranches roll off. DPU falls further before it stabilises.",
                         whatWouldMakeItTrue: ["Cost of debt above 3.9%", "DPU below 10.5¢"]),
                Scenario(name: "Cost of debt plateaus", premise: "Refinancing is largely done at these levels.",
                         roe: 0.061, growth: 0.020, requiredReturn: 0.072,
                         reasoning: "Property income growth of 3–4% starts flowing through to distributions again once the interest step-up is absorbed.",
                         whatWouldMakeItTrue: ["Cost of debt stable near 3.6%", "Occupancy held above 96%"]),
                Scenario(name: "Rates fall", premise: "The refinancing headwind reverses.",
                         roe: 0.072, growth: 0.030, requiredReturn: 0.068,
                         reasoning: "Falling policy rates reduce financing costs and lift the value investors place on a stable distribution at the same time.",
                         whatWouldMakeItTrue: ["Cost of debt back below 3.2%", "DPU growth resuming above 3%"])
            ],
            reviews: [
                Review(date: makeDate(2024, 4, 16), price: 1.94, anchorMultiple: 0.90, headlineMetric: 10.8,
                       conclusion: "Properties are fine, the unit price is not. The gap is entirely interest costs. Worth holding while the refinancing works through, but the distribution will be under pressure first.",
                       thesisState: .intact, conditionsIntact: 5, conditionsTotal: 5, prompt: "Why is this down when the malls are full?"),
                Review(date: makeDate(2026, 1, 27), price: 2.18, anchorMultiple: 1.03, headlineMetric: 11.2,
                       conclusion: "Recovered as rate expectations softened. Occupancy strong, distributions holding. The cost of debt is the number to watch — it has been rising steadily and is close to the limit you set.",
                       thesisState: .intact, conditionsIntact: 5, conditionsTotal: 5, prompt: nil)
            ],
            lenses: [
                MoveLens(name: "Against net asset value", anchorName: "Net asset value per unit", multipleName: "Price to NAV",
                         anchorStart: 2.16, anchorEnd: 2.10, multipleStart: 0.981, multipleEnd: 0.976,
                         anchorUnit: .currency,
                         explanation: "The market's opinion of this trust has barely moved in four years. What changed is the asset value itself, and beneath that, the cost of the debt financing it."),
                MoveLens(name: "Against distributions", anchorName: "Distribution per unit", multipleName: "Price to distribution",
                         anchorStart: 0.104, anchorEnd: 0.109, multipleStart: 20.38, multipleEnd: 18.81,
                         anchorUnit: .currency,
                         explanation: "Distributions grew slightly while investors became willing to pay less for each dollar of them — the exact inverse of what happened at DBS.")
            ],
            reratingDrivers: [
                ReratingDriver(name: "There was no re-rating to explain", kind: .evidence, confidence: .strong,
                               summary: "Price to NAV moved from 0.98× to 0.98×.",
                               detail: "The unit price is essentially where it started because the market is paying the same relative price for a slightly smaller asset base. Nothing here is a sentiment story."),
                ReratingDriver(name: "The cost of debt did the damage", kind: .evidence, confidence: .strong,
                               summary: "Average financing cost rose from 2.4% to 3.6%.",
                               detail: "Net property income grew 3.8%. Distributions still fell. The difference went to lenders. For a leveraged property vehicle, the interest rate is not background context — it is one of the two or three variables that determine the outcome."),
                ReratingDriver(name: "Older office assets were written down", kind: .evidence, confidence: .moderate,
                               summary: "NAV per unit fell from S$2.16 to S$2.10.",
                               detail: "Valuers marked down some ageing office space. Retail assets were held or marked up. This is a portfolio composition issue rather than a Singapore property issue.")
            ],
            bullCase: Argument(
                title: "The case for still owning it",
                stance: "The properties are performing; the problem is financing, and financing costs are cyclical.",
                points: [
                    ArgumentPoint(claim: "The underlying business improved", kind: .evidence,
                                  support: "Net property income grew 3.8% with occupancy at 96.4%. Tenant demand is not the issue."),
                    ArgumentPoint(claim: "You are paying net asset value", kind: .evidence,
                                  support: "0.98× NAV. No premium is embedded in the price for anything to go right."),
                    ArgumentPoint(claim: "The headwind is identifiable and finite", kind: .interpretation,
                                  support: "Most of the cheap debt has already been refinanced. The step-up is largely in the numbers rather than ahead of them.")
                ],
                invalidatedBy: "Occupancy falling below 94% or gearing rising above 42%, which would turn a financing problem into an operating one."
            ),
            bearCase: Argument(
                title: "The strongest case against",
                stance: "A leveraged owner of ageing offices in a structurally weaker part of the property market.",
                points: [
                    ArgumentPoint(claim: "Distributions are falling despite full occupancy", kind: .evidence,
                                  support: "DPU down from 11.2¢ to 10.9¢ while net property income rose. Leverage is transferring the gains to lenders."),
                    ArgumentPoint(claim: "Interest coverage has weakened materially", kind: .evidence,
                                  support: "From 4.6× to 3.1×. Still adequate, but the direction has been one-way."),
                    ArgumentPoint(claim: "Office demand may be permanently lower", kind: .uncertainty,
                                  support: "Write-downs are concentrated in older office assets. Whether this is cyclical or structural is genuinely unresolved.")
                ],
                invalidatedBy: "Cost of debt stabilising while DPU resumes growth — that would confirm the problem was the rate cycle, not the assets."
            ),
            mostUncertainAssumption: "Whether the older office assets hold their value. That is where the NAV decline came from, and it is the part of the portfolio least supported by the current occupancy figures.",
            situation: "The malls are full and the distribution still fell. The difference went to lenders.",
            whatChangedSummary: "Almost none of this position's story is valuation. The market pays the same multiple of net asset value it did four years ago. What changed is the cost of the trust's debt, which rose from 2.4% to 3.6% and took the distribution with it.",
            priceHistory: buildHistory(from: purchase, months: 46, startPrice: 2.12, endPrice: 2.05,
                                       startAnchor: 2.16, endAnchor: 2.10,
                                       shape: [-0.03, -0.05, -0.04, 0.02, 0.03, -0.02, 0.04, 0.01])
        )
    }
}
