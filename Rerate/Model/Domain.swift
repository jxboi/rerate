import Foundation

// MARK: - Business kind

/// The analysis adapts to what actually drives the business. A bank is not
/// judged on the same lines as a REIT, so the metric set and the valuation
/// identity both change with this.
enum BusinessKind: String, Codable {
    case bank
    case reit
    case telecom
    case matureTech
    case industrial

    var label: String {
        switch self {
        case .bank: "Bank"
        case .reit: "REIT"
        case .telecom: "Telecom"
        case .matureTech: "Mature technology"
        case .industrial: "Industrial"
        }
    }

    /// Same label in running prose. "REIT" must not be lowercased.
    var prose: String {
        switch self {
        case .bank: "bank"
        case .reit: "REIT"
        case .telecom: "telecom"
        case .matureTech: "mature technology company"
        case .industrial: "industrial business"
        }
    }

    /// The anchor a price is most naturally expressed against.
    var valuationAnchor: String {
        switch self {
        case .bank: "book value"
        case .reit: "net asset value"
        case .telecom, .industrial: "earnings"
        case .matureTech: "free cash flow"
        }
    }

    var anchorShort: String {
        switch self {
        case .bank: "P/B"
        case .reit: "P/NAV"
        case .telecom, .industrial: "P/E"
        case .matureTech: "P/FCF"
        }
    }
}

// MARK: - Judgements

enum Assessment: String, Codable, CaseIterable {
    case strong = "Strong"
    case stable = "Stable"
    case softening = "Softening"
    case weak = "Weak"

    var tone: Tone {
        switch self {
        case .strong: .affirm
        case .stable: .neutral
        case .softening: .caution
        case .weak: .breach
        }
    }
}

enum ValuationState: String, Codable {
    case attractive = "Attractive"
    case fair = "Fair"
    case full = "Full"
    case stretched = "Stretched"

    var tone: Tone {
        switch self {
        case .attractive: .affirm
        case .fair: .neutral
        case .full: .caution
        case .stretched: .breach
        }
    }
}

enum SentimentState: String, Codable {
    case quiet = "Quiet"
    case normal = "Normal"
    case warming = "Warming"
    case heating = "Heating up"

    var tone: Tone {
        switch self {
        case .quiet, .normal: .neutral
        case .warming: .caution
        case .heating: .caution
        }
    }
}

enum FlowState: String, Codable {
    case institutional = "Institutionally supported"
    case broad = "Broadly supported"
    case retail = "Retail led"
    case outflow = "Under distribution"
    case unclear = "Not enough evidence"

    var tone: Tone {
        switch self {
        case .institutional, .broad: .neutral
        case .retail: .caution
        case .outflow: .breach
        case .unclear: .neutral
        }
    }
}

enum ThesisState: String, Codable {
    case intact = "Intact"
    case mostlyIntact = "Mostly intact"
    case weakening = "Weakening"
    case broken = "Requires review"

    var tone: Tone {
        switch self {
        case .intact: .affirm
        case .mostlyIntact: .affirm
        case .weakening: .caution
        case .broken: .breach
        }
    }
}

/// The headline verdict on a holding. Never a trade instruction.
enum AttentionState: String, Codable {
    case reviewRequired = "Review required"
    case materialChange = "Material change detected"
    case worthWatching = "Worth watching"
    case noChange = "No material change"

    var tone: Tone {
        switch self {
        case .reviewRequired: .breach
        case .materialChange: .caution
        case .worthWatching: .caution
        case .noChange: .neutral
        }
    }

    /// Drives ordering on the portfolio screen.
    var priority: Int {
        switch self {
        case .reviewRequired: 0
        case .materialChange: 1
        case .worthWatching: 2
        case .noChange: 3
        }
    }
}

// MARK: - Thesis

enum ConditionStatus: String, Codable {
    case passing = "Holding"
    case warning = "Under pressure"
    case failing = "No longer true"

    var tone: Tone {
        switch self {
        case .passing: .affirm
        case .warning: .caution
        case .failing: .breach
        }
    }

    var glyph: String {
        switch self {
        case .passing: "checkmark"
        case .warning: "exclamationmark"
        case .failing: "xmark"
        }
    }
}

/// One testable claim the investor is making. The whole product hangs off these.
struct ThesisCondition: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var statement: String
    /// The metric this is judged against, e.g. "ROE".
    var measure: String
    /// Human-readable threshold, e.g. "above 15%".
    var test: String
    var status: ConditionStatus
    /// Current reading, e.g. "17.9%".
    var reading: String
    /// Reading at the last review, for the change view.
    var previousReading: String?
    var evidence: String
    /// Whether the user added this themselves rather than it being extracted.
    var userDefined: Bool = false
}

// MARK: - Metrics

struct Metric: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var value: Double
    var atPurchase: Double
    var atLastReview: Double
    var unit: MetricUnit
    var direction: MetricDirection
    var note: String?

    var display: String { unit.format(value) }
    var displayAtPurchase: String { unit.format(atPurchase) }
    var displayAtLastReview: String { unit.format(atLastReview) }

    var changeSinceReview: Double { value - atLastReview }

    /// Whether movement since the last review is favourable for the owner.
    var toneSinceReview: Tone {
        let delta = value - atLastReview
        let threshold = abs(atLastReview) * 0.005
        if abs(delta) <= threshold { return .neutral }
        let improving = direction == .higherIsBetter ? delta > 0 : delta < 0
        return improving ? .affirm : .caution
    }
}

enum MetricDirection: String, Codable {
    case higherIsBetter
    case lowerIsBetter
}

enum MetricUnit: String, Codable {
    case percent
    case currency
    case cents
    case multiple
    case ratio
    case billions

    func format(_ v: Double) -> String {
        switch self {
        case .percent: Fmt.percent(v, places: 1)
        case .currency: Fmt.money(v)
        case .cents: String(format: "%.1f", v) + "¢"
        case .multiple: Fmt.multiple(v)
        case .ratio: Fmt.plain(v, places: 2)
        case .billions: "S$" + String(format: "%.0f", v) + "b"
        }
    }
}

// MARK: - Return decomposition

/// Price moves are split along an identity so the split is arithmetic, not
/// opinion: price = anchor per share × multiple. Each lens is a different but
/// equally true way of cutting the same move.
struct MoveLens: Identifiable, Hashable {
    var id: String { name }
    var name: String
    var anchorName: String
    var multipleName: String
    var anchorStart: Double
    var anchorEnd: Double
    var multipleStart: Double
    var multipleEnd: Double
    var anchorUnit: MetricUnit
    var explanation: String

    var anchorGrowth: Double { anchorEnd / anchorStart - 1 }
    var multipleGrowth: Double { multipleEnd / multipleStart - 1 }

    /// Log shares sum exactly to 100% with no leftover interaction term, which
    /// is why the bars can be drawn honestly side by side.
    var anchorShare: Double {
        let total = log(anchorEnd / anchorStart) + log(multipleEnd / multipleStart)
        guard total != 0 else { return 0.5 }
        return log(anchorEnd / anchorStart) / total
    }

    var multipleShare: Double { 1 - anchorShare }
}

struct MoveComponent: Identifiable {
    var id: String { label }
    var label: String
    var share: Double        // 0...1 of the total move
    var contribution: Double // percentage points of price change
    var detail: String
    var isRerating: Bool
}

// MARK: - Flows and sentiment

struct FlowEvidence: Identifiable {
    var id: UUID = UUID()
    var actor: String
    var direction: String
    var magnitude: String
    var window: String
    var confidence: Confidence
    var note: String
}

// MARK: - Scenarios

struct Scenario: Identifiable, Hashable {
    var id: String { name }
    var name: String
    var premise: String
    var roe: Double
    var growth: Double
    var requiredReturn: Double
    var reasoning: String
    var whatWouldMakeItTrue: [String]
}

// MARK: - Reviews and memory

struct Review: Identifiable, Codable {
    var id: UUID = UUID()
    var date: Date
    var price: Double
    var anchorMultiple: Double
    var headlineMetric: Double      // ROE for banks, DPU yield for REITs
    var conclusion: String
    var thesisState: ThesisState
    var conditionsIntact: Int
    var conditionsTotal: Int
    /// The question the investor brought to that review, if they wrote one.
    var prompt: String?
}

// MARK: - Signals

struct Signal: Identifiable, Codable {
    var id: UUID = UUID()
    var ticker: String
    var date: Date
    var headline: String
    var body: String
    var kind: SignalKind
    var read: Bool = false
}

enum SignalKind: String, Codable {
    case valuationThreshold = "Valuation threshold"
    case conditionChanged = "Thesis condition"
    case earnings = "Earnings"
    case guidance = "Guidance"
    case distribution = "Distribution"
    case quiet = "Nothing material"

    var tone: Tone {
        switch self {
        case .valuationThreshold: .caution
        case .conditionChanged: .breach
        case .earnings: .neutral
        case .guidance: .caution
        case .distribution: .breach
        case .quiet: .neutral
        }
    }

    var icon: String {
        switch self {
        case .valuationThreshold: "arrow.up.right"
        case .conditionChanged: "exclamationmark"
        case .earnings: "doc.text"
        case .guidance: "megaphone"
        case .distribution: "arrow.down.right"
        case .quiet: "equal"
        }
    }
}

// MARK: - Argument

struct Argument: Identifiable {
    var id: String { title }
    var title: String
    var stance: String
    var points: [ArgumentPoint]
    var invalidatedBy: String
}

struct ArgumentPoint: Identifiable {
    var id: String { claim }
    var claim: String
    var kind: ClaimKind
    var support: String
}
