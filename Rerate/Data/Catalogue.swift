import Foundation

/// The universe Rerate covers in V1. Singapore first, and deliberately narrow —
/// a small number of companies understood properly is worth more here than a
/// global list nobody can analyse well.
struct CatalogueEntry: Identifiable, Hashable {
    var id: String { ticker }
    var ticker: String
    var name: String
    var shortName: String?
    var kind: BusinessKind
    var price: Double
    /// Book value, net asset value or earnings per share, depending on kind.
    var anchorPerShare: Double
    /// Typical annual change in the anchor, used to reconstruct where it stood
    /// when the investor bought.
    var anchorDriftPerYear: Double
    var dividendPerShare: Double
    var metricSpecs: [MetricSpec]
    /// Positions Rerate already covers in depth.
    var richSeed: String?

    static func == (a: CatalogueEntry, b: CatalogueEntry) -> Bool { a.ticker == b.ticker }
    func hash(into hasher: inout Hasher) { hasher.combine(ticker) }
}

struct MetricSpec {
    var name: String
    var value: Double
    var unit: MetricUnit
    var direction: MetricDirection
    /// Absolute change per year, used to derive the figure at purchase.
    var driftPerYear: Double
    var note: String?

    init(_ name: String, _ value: Double, _ unit: MetricUnit, _ direction: MetricDirection, drift: Double, note: String? = nil) {
        self.name = name
        self.value = value
        self.unit = unit
        self.direction = direction
        self.driftPerYear = drift
        self.note = note
    }
}

enum Catalogue {
    static let entries: [CatalogueEntry] = [
        CatalogueEntry(
            ticker: "D05", name: "DBS Group", shortName: nil, kind: .bank, price: 76.00,
            anchorPerShare: 23.75, anchorDriftPerYear: 2.33, dividendPerShare: 2.88,
            metricSpecs: bankMetrics(roe: 17.9, nim: 2.02, npl: 1.0, cet1: 15.8, bvps: 23.75, eps: 4.25, dps: 2.88, price: 76.00),
            richSeed: "DBS"
        ),
        CatalogueEntry(
            ticker: "O39", name: "OCBC", shortName: nil, kind: .bank, price: 18.40,
            anchorPerShare: 12.95, anchorDriftPerYear: 0.60, dividendPerShare: 0.94,
            metricSpecs: bankMetrics(roe: 13.8, nim: 2.16, npl: 0.9, cet1: 16.1, bvps: 12.95, eps: 1.79, dps: 0.94, price: 18.40),
            richSeed: "OCBC"
        ),
        CatalogueEntry(
            ticker: "U11", name: "UOB", shortName: nil, kind: .bank, price: 41.20,
            anchorPerShare: 30.10, anchorDriftPerYear: 1.45, dividendPerShare: 2.02,
            metricSpecs: bankMetrics(roe: 13.1, nim: 2.00, npl: 1.5, cet1: 15.4, bvps: 30.10, eps: 3.94, dps: 2.02, price: 41.20),
            richSeed: nil
        ),
        CatalogueEntry(
            ticker: "Z74", name: "Singtel", shortName: nil, kind: .telecom, price: 3.42,
            anchorPerShare: 0.198, anchorDriftPerYear: 0.017, dividendPerShare: 0.170,
            metricSpecs: telecomMetrics(eps: 0.198, fcf: 0.239, ebit: 14.2, roic: 9.4, netDebt: 1.6, dps: 0.170, price: 3.42),
            richSeed: "Singtel"
        ),
        CatalogueEntry(
            ticker: "S63", name: "ST Engineering", shortName: nil, kind: .industrial, price: 8.94,
            anchorPerShare: 0.268, anchorDriftPerYear: 0.028, dividendPerShare: 0.180,
            metricSpecs: telecomMetrics(eps: 0.268, fcf: 0.302, ebit: 10.4, roic: 12.8, netDebt: 2.3, dps: 0.180, price: 8.94),
            richSeed: nil
        ),
        CatalogueEntry(
            ticker: "S68", name: "Singapore Exchange", shortName: nil, kind: .industrial, price: 15.60,
            anchorPerShare: 0.472, anchorDriftPerYear: 0.030, dividendPerShare: 0.360,
            metricSpecs: telecomMetrics(eps: 0.472, fcf: 0.498, ebit: 45.1, roic: 21.4, netDebt: 0.4, dps: 0.360, price: 15.60),
            richSeed: nil
        ),
        CatalogueEntry(
            ticker: "U96", name: "Sembcorp Industries", shortName: nil, kind: .industrial, price: 7.85,
            anchorPerShare: 0.685, anchorDriftPerYear: 0.062, dividendPerShare: 0.230,
            metricSpecs: telecomMetrics(eps: 0.685, fcf: 0.540, ebit: 18.6, roic: 13.2, netDebt: 2.8, dps: 0.230, price: 7.85),
            richSeed: nil
        ),
        CatalogueEntry(
            ticker: "BN4", name: "Keppel", shortName: nil, kind: .industrial, price: 8.42,
            anchorPerShare: 0.640, anchorDriftPerYear: 0.048, dividendPerShare: 0.340,
            metricSpecs: telecomMetrics(eps: 0.640, fcf: 0.512, ebit: 15.8, roic: 9.8, netDebt: 2.1, dps: 0.340, price: 8.42),
            richSeed: nil
        ),
        CatalogueEntry(
            ticker: "C38U", name: "CapitaLand Integrated Commercial Trust", shortName: "CICT", kind: .reit, price: 2.05,
            anchorPerShare: 2.10, anchorDriftPerYear: -0.016, dividendPerShare: 0.109,
            metricSpecs: reitMetrics(nav: 2.10, dpu: 10.9, gearing: 39.8, costOfDebt: 3.6, coverage: 3.1, occupancy: 96.4, npi: 3.8, price: 2.05),
            richSeed: "CICT"
        ),
        CatalogueEntry(
            ticker: "A17U", name: "CapitaLand Ascendas REIT", shortName: nil, kind: .reit, price: 2.78,
            anchorPerShare: 3.03, anchorDriftPerYear: -0.011, dividendPerShare: 0.152,
            metricSpecs: reitMetrics(nav: 3.03, dpu: 15.2, gearing: 37.9, costOfDebt: 3.8, coverage: 3.4, occupancy: 92.8, npi: 2.4, price: 2.78),
            richSeed: nil
        ),
        CatalogueEntry(
            ticker: "M44U", name: "Mapletree Logistics Trust", shortName: nil, kind: .reit, price: 1.24,
            anchorPerShare: 1.62, anchorDriftPerYear: -0.024, dividendPerShare: 0.078,
            metricSpecs: reitMetrics(nav: 1.62, dpu: 7.8, gearing: 40.6, costOfDebt: 3.1, coverage: 3.3, occupancy: 95.7, npi: -1.2, price: 1.24),
            richSeed: nil
        ),
        CatalogueEntry(
            ticker: "N2IU", name: "Mapletree Pan Asia Commercial Trust", shortName: "MPACT", kind: .reit, price: 1.32,
            anchorPerShare: 1.71, anchorDriftPerYear: -0.029, dividendPerShare: 0.081,
            metricSpecs: reitMetrics(nav: 1.71, dpu: 8.1, gearing: 38.4, costOfDebt: 3.5, coverage: 2.9, occupancy: 96.1, npi: 1.1, price: 1.32),
            richSeed: nil
        )
    ]

    static func search(_ query: String) -> [CatalogueEntry] {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return entries }
        return entries.filter {
            $0.name.lowercased().contains(q) || $0.ticker.lowercased().contains(q)
        }
    }

    static func entry(ticker: String) -> CatalogueEntry? {
        entries.first { $0.ticker == ticker }
    }

    // MARK: Metric templates

    private static func bankMetrics(roe: Double, nim: Double, npl: Double, cet1: Double, bvps: Double, eps: Double, dps: Double, price: Double) -> [MetricSpec] {
        [
            MetricSpec("Return on equity", roe, .percent, .higherIsBetter, drift: 1.1),
            MetricSpec("Net interest margin", nim, .percent, .higherIsBetter, drift: -0.05),
            MetricSpec("Cost to income", 41.0, .percent, .lowerIsBetter, drift: -0.7),
            MetricSpec("Non-performing loans", npl, .percent, .lowerIsBetter, drift: -0.05),
            MetricSpec("CET1 capital ratio", cet1, .percent, .higherIsBetter, drift: 0.5),
            MetricSpec("Book value per share", bvps, .currency, .higherIsBetter, drift: bvps * 0.09),
            MetricSpec("Earnings per share", eps, .currency, .higherIsBetter, drift: eps * 0.11),
            MetricSpec("Dividend per share", dps, .currency, .higherIsBetter, drift: dps * 0.13),
            MetricSpec("Dividend yield", dps / price * 100, .percent, .higherIsBetter, drift: 0.0),
            MetricSpec("Price to book", price / bvps, .multiple, .lowerIsBetter, drift: 0.0)
        ]
    }

    private static func reitMetrics(nav: Double, dpu: Double, gearing: Double, costOfDebt: Double, coverage: Double, occupancy: Double, npi: Double, price: Double) -> [MetricSpec] {
        [
            MetricSpec("Portfolio occupancy", occupancy, .percent, .higherIsBetter, drift: 0.2),
            MetricSpec("Net property income growth", npi, .percent, .higherIsBetter, drift: 0.3),
            MetricSpec("Distribution per unit", dpu, .cents, .higherIsBetter, drift: -0.15),
            MetricSpec("Distribution yield", dpu / 100 / price * 100, .percent, .higherIsBetter, drift: 0.0),
            MetricSpec("Aggregate leverage", gearing, .percent, .lowerIsBetter, drift: -0.2),
            MetricSpec("Average cost of debt", costOfDebt, .percent, .lowerIsBetter, drift: 0.35, note: "Refinancing at higher rates"),
            MetricSpec("Interest coverage", coverage, .ratio, .higherIsBetter, drift: -0.4),
            MetricSpec("Net asset value per unit", nav, .currency, .higherIsBetter, drift: -0.015),
            MetricSpec("Price to NAV", price / nav, .multiple, .lowerIsBetter, drift: 0.0)
        ]
    }

    private static func telecomMetrics(eps: Double, fcf: Double, ebit: Double, roic: Double, netDebt: Double, dps: Double, price: Double) -> [MetricSpec] {
        [
            MetricSpec("EBIT margin", ebit, .percent, .higherIsBetter, drift: 0.8),
            MetricSpec("Return on invested capital", roic, .percent, .higherIsBetter, drift: 0.7),
            MetricSpec("Earnings per share", eps, .currency, .higherIsBetter, drift: eps * 0.12),
            MetricSpec("Free cash flow per share", fcf, .currency, .higherIsBetter, drift: fcf * 0.10),
            MetricSpec("Net debt to EBITDA", netDebt, .ratio, .lowerIsBetter, drift: -0.15),
            MetricSpec("Dividend yield", dps / price * 100, .percent, .higherIsBetter, drift: 0.0),
            MetricSpec("Price to earnings", price / eps, .multiple, .lowerIsBetter, drift: 0.0)
        ]
    }
}
