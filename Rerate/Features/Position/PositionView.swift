import SwiftUI

struct PositionView: View {
    @Environment(Store.self) private var store
    let holdingID: UUID
    @State private var appeared = false

    private var h: Holding { store.holding(holdingID) ?? SeedDBS.holding }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    hero
                    sinceLastReview
                    whatChanged
                    dimensions.id("dimensions")
                    explainMoveCard
                    mustBeTrueCard
                    actions.id("actions")
                    historyLink
                    disclaimer
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 44)
            }
            .background(Palette.canvas)
            .scrollIndicators(.hidden)
            .navigationTitle(h.shortName)
            .navigationBarTitleDisplayMode(.inline)
            .task {
                withAnimation(Motion.gentle) { appeared = true }
                #if DEBUG
                let args = ProcessInfo.processInfo.arguments
                if let i = args.firstIndex(of: "-anchor"), i + 1 < args.count {
                    try? await Task.sleep(nanoseconds: 400_000_000)
                    proxy.scrollTo(args[i + 1], anchor: .top)
                }
                #endif
            }
        }
    }

    // MARK: Hero

    private var hero: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("\(h.exchange) · \(h.ticker) · \(h.kind.label)")
                .sectionLabelStyle()
                .padding(.top, 6)

            Text(h.name)
                .font(Type.statement)
                .foregroundStyle(Palette.ink)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 8)

            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(Fmt.money(h.price, currency: h.currency))
                    .font(Type.figure(42))
                    .foregroundStyle(Palette.ink)
                VStack(alignment: .leading, spacing: 1) {
                    Text(Fmt.percent(h.priceReturn * 100, places: 0, signed: true))
                        .font(Type.mono(16, .medium))
                        .foregroundStyle(Palette.ink)
                    Text("since purchase")
                        .font(Type.micro)
                        .foregroundStyle(Palette.inkTertiary)
                }
            }
            .padding(.top, 12)

            Text("\(Fmt.money(h.averageCost, currency: h.currency)) on \(Fmt.shortDate.string(from: h.purchaseDate)) · \(Int(h.shares).formatted()) shares · \(Fmt.percent(h.totalReturn * 100, places: 0, signed: true)) with dividends")
                .font(Type.caption)
                .foregroundStyle(Palette.inkTertiary)
                .padding(.top, 10)

            DivergenceChart(
                points: h.priceHistory,
                anchorLabel: h.kind == .reit ? "Net asset value" : (h.kind == .bank ? "Book value" : "Earnings")
            )
            .padding(.top, 26)
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 10)
    }

    // MARK: Since last review

    @ViewBuilder
    private var sinceLastReview: some View {
        if let last = h.lastReview {
            VStack(alignment: .leading, spacing: 0) {
                SectionLabel("Since your last review", trailing: Fmt.shortDate.string(from: last.date))
                    .padding(.bottom, 6)

                MetricRow(
                    name: "Price",
                    value: Fmt.money(h.price, currency: h.currency),
                    was: Fmt.money(last.price, currency: h.currency),
                    tone: .neutral
                )
                Hairline()
                MetricRow(
                    name: h.kind.anchorShort == "P/B" ? "Price to book" : "Price to \(h.kind.valuationAnchor)",
                    value: Fmt.multiple(h.multiple),
                    was: Fmt.multiple(last.anchorMultiple),
                    tone: h.multiple > last.anchorMultiple ? .caution : .neutral
                )
                ForEach(keyDeltas) { metric in
                    Hairline()
                    MetricRow(
                        name: metric.name,
                        value: metric.display,
                        was: metric.displayAtLastReview,
                        tone: metric.toneSinceReview
                    )
                }

                Inset {
                    Text(sinceReviewNarrative(last))
                        .font(Type.quote)
                        .foregroundStyle(Palette.ink)
                        .lineSpacing(5)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 14)
            }
            .padding(.top, 38)
        }
    }

    /// Three metrics that actually moved, chosen from the sector-specific set.
    private var keyDeltas: [Metric] {
        h.metrics
            // The valuation multiple already has its own row above.
            .filter { $0.unit != .multiple }
            .filter { abs($0.changeSinceReview) > abs($0.atLastReview) * 0.004 }
            .sorted { abs($0.changeSinceReview / max($0.atLastReview, 0.001)) > abs($1.changeSinceReview / max($1.atLastReview, 0.001)) }
            .prefix(3)
            .map { $0 }
    }

    private func sinceReviewNarrative(_ last: Review) -> String {
        let priceMove = h.price / last.price - 1
        let anchorMove = h.anchorPerShare / h.anchorAtLastReview - 1
        let multipleMove = h.multiple / last.anchorMultiple - 1
        guard abs(priceMove) > 0.005 else {
            return "Little has moved since your last review. The business and the price have both been quiet."
        }
        let direction = priceMove > 0 ? "rose" : "fell"
        let anchorWord = h.kind == .reit ? "net asset value" : (h.kind == .bank ? "book value per share" : "earnings per share")
        if abs(multipleMove) > abs(anchorMove) * 1.6 {
            return "The price \(direction) \(Fmt.percent(abs(priceMove) * 100)). \(anchorWord.prefix(1).uppercased() + anchorWord.dropFirst()) changed \(Fmt.percent(anchorMove * 100, signed: true)), while the multiple changed \(Fmt.percent(multipleMove * 100, signed: true)). Almost all of this move was a change in what investors will pay, not in what the business produced."
        }
        if abs(anchorMove) > abs(multipleMove) * 1.6 {
            return "The price \(direction) \(Fmt.percent(abs(priceMove) * 100)), and \(anchorWord) changed \(Fmt.percent(anchorMove * 100, signed: true)). This move came from the business rather than from a change of opinion about it."
        }
        return "The price \(direction) \(Fmt.percent(abs(priceMove) * 100)) — roughly half from the business and half from a change in the multiple investors apply to it."
    }

    // MARK: What changed

    private var whatChanged: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionLabel("What changed")
            Text(h.whatChangedSummary)
                .proseStyle()
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 40)
    }

    // MARK: Five dimensions

    private var dimensions: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionLabel("Where things stand")
                .padding(.bottom, 4)

            dimensionRow("Business", h.business.rawValue, h.business.tone, businessDetail, .business(h.id))
            Hairline()
            dimensionRow("Valuation", h.valuation.rawValue, h.valuation.tone, valuationDetail, .mustBeTrue(h.id))
            Hairline()
            dimensionRow("Thesis", h.thesisState.rawValue, h.thesisState.tone, "\(h.conditionsIntact) of \(h.conditionsTotal) conditions still hold", .thesis(h.id))
            Hairline()
            dimensionRow("Flows", h.flows.rawValue, h.flows.tone, flowsDetail, .flows(h.id))
            Hairline()
            dimensionRow("Sentiment", h.sentiment.rawValue, h.sentiment.tone, sentimentDetail, .flows(h.id))
        }
        .padding(.top, 40)
    }

    private func dimensionRow(_ label: String, _ value: String, _ tone: Tone, _ detail: String, _ route: Route) -> some View {
        NavigationLink(value: route) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(label)
                        .font(Type.body)
                        .foregroundStyle(Palette.ink)
                    Text(detail)
                        .font(Type.caption)
                        .foregroundStyle(Palette.inkTertiary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 10)
                Text(value)
                    .font(Type.bodyMedium)
                    .foregroundStyle(tone == .neutral ? Palette.ink : tone.color)
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Palette.inkQuaternary)
                    .padding(.top, 2)
            }
            .padding(.vertical, 15)
            .contentShape(Rectangle())
        }
        .buttonStyle(.pressable(scale: 0.99))
    }

    private var businessDetail: String {
        let key = h.metrics.first
        guard let key else { return "How the company itself is performing" }
        return "\(key.name) \(key.display), from \(key.displayAtPurchase) at purchase"
    }

    private var valuationDetail: String {
        "\(Fmt.multiple(h.multiple)) \(h.kind.valuationAnchor), from \(Fmt.multiple(h.multipleAtPurchase)) at purchase"
    }

    private var flowsDetail: String {
        h.flowEvidence.first.map { "\($0.actor.lowercased()) \($0.direction.lowercased()), \($0.magnitude)" }
            ?? "Who appears to be transacting"
    }

    private var sentimentDetail: String {
        switch h.sentiment {
        case .heating: "Attention is rising faster than the fundamentals"
        case .warming: "More discussion than usual"
        case .normal: "Nothing unusual in attention"
        case .quiet: "Largely ignored"
        }
    }

    // MARK: Signature cards

    private var explainMoveCard: some View {
        NavigationLink(value: Route.explainMove(h.id)) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Explain the move")
                            .font(Type.title)
                            .foregroundStyle(Palette.ink)
                        Text("Why did \(h.shortName.split(separator: " ").first.map(String.init) ?? h.ticker) \(h.priceReturn >= 0 ? "rise" : "fall")?")
                            .font(Type.callout)
                            .foregroundStyle(Palette.inkSecondary)
                    }
                    Spacer(minLength: 8)
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Palette.inkQuaternary)
                }

                SplitPreviewBar(lens: h.primaryLens)
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Palette.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(Palette.hairline, lineWidth: 1)
            )
        }
        .buttonStyle(.pressable(scale: 0.985))
        .padding(.top, 40)
    }

    private var mustBeTrueCard: some View {
        NavigationLink(value: Route.mustBeTrue(h.id)) {
            HStack(alignment: .top, spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("What must be true?")
                        .font(Type.title)
                        .foregroundStyle(Palette.ink)
                    Text(mustBeTruePreview)
                        .font(Type.callout)
                        .foregroundStyle(Palette.inkSecondary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 4)
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Palette.inkQuaternary)
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Palette.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(Palette.hairline, lineWidth: 1)
            )
        }
        .buttonStyle(.pressable(scale: 0.985))
        .padding(.top, 14)
    }

    private var mustBeTruePreview: String {
        guard h.kind == .bank || h.kind == .reit else {
            return "The assumptions today's price is carrying"
        }
        let implied = EquityValuation.impliedROE(multiple: h.multiple, growth: 0.04, requiredReturn: 0.09)
        return "Today's price implies about \(Fmt.percent(implied * 100, places: 0)) sustained return on equity"
    }

    // MARK: Actions

    private var actions: some View {
        VStack(spacing: 12) {
            NavigationLink(value: Route.review(h.id)) {
                HStack(spacing: 8) {
                    Text("Review my position").font(Type.bodyMedium)
                    Image(systemName: "arrow.right").font(.system(size: 13, weight: .semibold))
                }
                .foregroundStyle(Palette.canvas)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 17)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Palette.ink)
                )
            }
            .buttonStyle(.pressable(scale: 0.975))
            .simultaneousGesture(TapGesture().onEnded { Haptic.firm() })

            NavigationLink(value: Route.challenge(h.id)) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.triangle.2.circlepath").font(.system(size: 13, weight: .semibold))
                    Text("Challenge my thesis").font(Type.bodyMedium)
                }
                .foregroundStyle(Palette.ink)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Palette.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(Palette.hairlineStrong, lineWidth: 1)
                )
            }
            .buttonStyle(.pressable(scale: 0.98))
            .simultaneousGesture(TapGesture().onEnded { Haptic.tap() })
        }
        .padding(.top, 34)
    }

    private var historyLink: some View {
        NavigationLink(value: Route.history(h.id)) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("How your thinking has changed")
                        .font(Type.body)
                        .foregroundStyle(Palette.ink)
                    Text("\(h.reviews.count) previous \(h.reviews.count == 1 ? "review" : "reviews") since \(Fmt.compactDate.string(from: h.purchaseDate))")
                        .font(Type.caption)
                        .foregroundStyle(Palette.inkTertiary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Palette.inkQuaternary)
            }
            .padding(.vertical, 18)
            .contentShape(Rectangle())
        }
        .buttonStyle(.pressable(scale: 0.99))
        .padding(.top, 20)
        .overlay(alignment: .top) { Hairline().padding(.top, 20) }
    }

    private var disclaimer: some View {
        Text("Figures are illustrative. Rerate does not give investment advice and never tells you what to trade.")
            .font(Type.micro)
            .foregroundStyle(Palette.inkQuaternary)
            .lineSpacing(3)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.top, 28)
    }
}

/// A two-segment bar showing how a move splits between the business and the
/// market's opinion of it. Appears as a preview and again, larger, inside
/// Explain the Move.
struct SplitPreviewBar: View {
    let lens: MoveLens
    @State private var shown = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            GeometryReader { geo in
                HStack(spacing: 3) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Palette.ink)
                        .frame(width: max(geo.size.width * CGFloat(lens.anchorShare) - 1.5, 2))
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Palette.caution.opacity(0.55))
                }
                .frame(width: shown ? geo.size.width : 0, alignment: .leading)
            }
            .frame(height: 8)
            .clipped()

            HStack(spacing: 14) {
                Label {
                    Text("\(Int((lens.anchorShare * 100).rounded()))% the business")
                        .font(Type.micro)
                        .foregroundStyle(Palette.inkSecondary)
                } icon: {
                    RoundedRectangle(cornerRadius: 1.5).fill(Palette.ink).frame(width: 8, height: 8)
                }
                Label {
                    Text("\(Int((lens.multipleShare * 100).rounded()))% re-rating")
                        .font(Type.micro)
                        .foregroundStyle(Palette.inkSecondary)
                } icon: {
                    RoundedRectangle(cornerRadius: 1.5).fill(Palette.caution.opacity(0.55)).frame(width: 8, height: 8)
                }
            }
        }
        .onAppear {
            withAnimation(Motion.draw.delay(0.2)) { shown = true }
        }
    }
}
