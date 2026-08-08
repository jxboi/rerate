import Foundation

// Compact forms used in the portfolio grid, where four judgements have to sit
// side by side without wrapping.

extension ThesisState {
    var short: String {
        switch self {
        case .intact: "Intact"
        case .mostlyIntact: "Mostly intact"
        case .weakening: "Weakening"
        case .broken: "Needs review"
        }
    }
}

extension Assessment {
    var short: String { rawValue }
}

extension ValuationState {
    var short: String { rawValue }
}

extension SentimentState {
    var short: String {
        switch self {
        case .quiet: "Quiet"
        case .normal: "Normal"
        case .warming: "Warming"
        case .heating: "Heating"
        }
    }
}

extension AttentionState {
    /// The card has a name beside it, so the pill has to stay short.
    var short: String {
        switch self {
        case .reviewRequired: "Review required"
        case .materialChange: "Material change"
        case .worthWatching: "Worth watching"
        case .noChange: "No change"
        }
    }
}

extension FlowState {
    var short: String {
        switch self {
        case .institutional: "Institutional"
        case .broad: "Broad"
        case .retail: "Retail led"
        case .outflow: "Distribution"
        case .unclear: "Unclear"
        }
    }
}
