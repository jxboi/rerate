import SwiftUI

struct PortfolioView: View {
    @Environment(Store.self) private var store
    @Namespace private var cardNamespace
    @State private var path: [Route] = []
    @State private var showSignals = false
    @State private var showAdd = false
    @State private var appeared = false

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    header
                    attentionSection
                    quietSection
                    footer
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .background(Palette.canvas)
            .scrollIndicators(.hidden)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbar }
            .navigationDestination(for: Route.self) { route in
                RouteView(route: route)
            }
            .sheet(isPresented: $showSignals) {
                SignalsView(onOpen: { ticker in
                    showSignals = false
                    if let h = store.holdings.first(where: { $0.ticker == ticker }) {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            path.append(.position(h.id))
                        }
                    }
                })
            }
            .sheet(isPresented: $showAdd) {
                OnboardingFlow(isSheet: true)
            }
        }
        .task {
            guard !appeared else { return }
            withAnimation(Motion.gentle) { appeared = true }
            #if DEBUG
            applyDebugRoute()
            #endif
        }
        .onChange(of: store.pendingFocus) { _, id in
            guard let id else { return }
            store.pendingFocus = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                path.append(.position(id))
            }
        }
    }

    // MARK: Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text("Rerate")
                    .font(.system(size: 16, weight: .semibold, design: .serif))
                    .foregroundStyle(Palette.ink)
                Spacer()
                Text(Fmt.monthYear.string(from: Date()))
                    .sectionLabelStyle()
            }
            .padding(.top, 4)

            Text("What deserves\nyour attention?")
                .font(Type.statement)
                .foregroundStyle(Palette.ink)
                .lineSpacing(3)
                .padding(.top, 10)

            Text(attentionSummary)
                .font(Type.callout)
                .foregroundStyle(Palette.inkSecondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 10)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 26)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 8)
    }

    private var attentionSummary: String {
        let n = store.needsAttention.count
        switch n {
        case 0: return "Nothing has changed materially across your \(store.holdings.count) positions."
        case 1: return "One position has changed in a way worth thinking about. The rest are quiet."
        default: return "\(n) positions have changed in ways worth thinking about. The rest are quiet."
        }
    }

    // MARK: Sections

    private var attentionSection: some View {
        VStack(spacing: 14) {
            ForEach(Array(store.needsAttention.enumerated()), id: \.element.id) { i, holding in
                NavigationLink(value: Route.position(holding.id)) {
                    holdingCard(holding)
                }
                .buttonStyle(.pressable(scale: 0.985))
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 14)
                .animation(Motion.cascade(i, base: 0.06), value: appeared)
            }
        }
    }

    @ViewBuilder
    private func holdingCard(_ holding: Holding) -> some View {
        if #available(iOS 18.0, *) {
            HoldingCard(holding: holding, namespace: cardNamespace)
                .matchedTransitionSource(id: holding.id, in: cardNamespace)
        } else {
            HoldingCard(holding: holding, namespace: cardNamespace)
        }
    }

    private var quietSection: some View {
        let quiet = store.byAttention.filter { $0.attention == .noChange }
        return Group {
            if !quiet.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    SectionLabel("No material change")
                        .padding(.top, 34)
                        .padding(.bottom, 4)

                    ForEach(Array(quiet.enumerated()), id: \.element.id) { i, holding in
                        NavigationLink(value: Route.position(holding.id)) {
                            quietRow(holding)
                        }
                        .buttonStyle(.pressable(scale: 0.985))
                        .opacity(appeared ? 1 : 0)
                        .animation(Motion.cascade(i + store.needsAttention.count, base: 0.05), value: appeared)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func quietRow(_ holding: Holding) -> some View {
        if #available(iOS 18.0, *) {
            QuietHoldingRow(holding: holding)
                .matchedTransitionSource(id: holding.id, in: cardNamespace)
        } else {
            QuietHoldingRow(holding: holding)
        }
    }

    // MARK: Footer

    /// Portfolio value lives here, deliberately: it is the least useful number
    /// on the screen for the decision the user is actually making.
    private var footer: some View {
        VStack(alignment: .leading, spacing: 14) {
            Hairline().padding(.top, 34)

            HStack(alignment: .firstTextBaseline) {
                Text("Portfolio")
                    .font(Type.callout)
                    .foregroundStyle(Palette.inkTertiary)
                Spacer()
                Text(Fmt.compact(store.totalValue))
                    .font(Type.mono(15))
                    .foregroundStyle(Palette.inkSecondary)
                Text(Fmt.percent((store.totalValue / store.totalCost - 1) * 100, places: 0, signed: true))
                    .font(Type.mono(13))
                    .foregroundStyle(Palette.inkTertiary)
            }
            .padding(.top, 14)

            Button {
                Haptic.tap()
                showAdd = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .semibold))
                    Text("Add a position")
                        .font(Type.bodyMedium)
                }
                .foregroundStyle(Palette.inkSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Palette.surfaceSunken)
                )
            }
            .buttonStyle(.pressable(scale: 0.98))
            .padding(.top, 8)
        }
        .opacity(appeared ? 1 : 0)
    }

    // MARK: Debug routing

    #if DEBUG
    /// Lets a screen be opened directly from the command line during
    /// development, e.g. `-screen mustbetrue -ticker C38U`. Debug builds only.
    private func applyDebugRoute() {
        let args = ProcessInfo.processInfo.arguments
        guard let i = args.firstIndex(of: "-screen"), i + 1 < args.count else { return }
        let ticker = args.firstIndex(of: "-ticker").flatMap { $0 + 1 < args.count ? args[$0 + 1] : nil } ?? "D05"
        guard let holding = store.holdings.first(where: { $0.ticker == ticker }) else { return }
        let id = holding.id

        if args[i + 1] == "signals" {
            showSignals = true
            return
        }
        if args[i + 1] == "add" {
            showAdd = true
            return
        }
        let deeper: Route? = switch args[i + 1] {
        case "explain": .explainMove(id)
        case "mustbetrue": .mustBeTrue(id)
        case "thesis": .thesis(id)
        case "review": .review(id)
        case "challenge": .challenge(id)
        case "history": .history(id)
        case "flows": .flows(id)
        case "business": .business(id)
        default: nil
        }
        path = deeper.map { [.position(id), $0] } ?? [.position(id)]
    }
    #endif

    // MARK: Toolbar

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                Haptic.tap()
                showSignals = true
            } label: {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "bell")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Palette.ink)
                        .padding(4)
                    if !store.unreadSignals.isEmpty {
                        Circle()
                            .fill(Palette.breach)
                            .frame(width: 7, height: 7)
                            .offset(x: 2, y: -1)
                    }
                }
            }
        }
    }
}

// MARK: - Routing

enum Route: Hashable {
    case position(UUID)
    case explainMove(UUID)
    case mustBeTrue(UUID)
    case thesis(UUID)
    case review(UUID)
    case challenge(UUID)
    case history(UUID)
    case flows(UUID)
    case business(UUID)
}

struct RouteView: View {
    @Environment(Store.self) private var store
    let route: Route

    var body: some View {
        switch route {
        case .position(let id): resolve(id) { PositionView(holdingID: $0) }
        case .explainMove(let id): resolve(id) { ExplainMoveView(holdingID: $0) }
        case .mustBeTrue(let id): resolve(id) { MustBeTrueView(holdingID: $0) }
        case .thesis(let id): resolve(id) { ThesisView(holdingID: $0) }
        case .review(let id): resolve(id) { ReviewView(holdingID: $0) }
        case .challenge(let id): resolve(id) { ChallengeView(holdingID: $0) }
        case .history(let id): resolve(id) { HistoryView(holdingID: $0) }
        case .flows(let id): resolve(id) { FlowsView(holdingID: $0) }
        case .business(let id): resolve(id) { BusinessView(holdingID: $0) }
        }
    }

    @ViewBuilder
    private func resolve<V: View>(_ id: UUID, @ViewBuilder content: (UUID) -> V) -> some View {
        if store.holding(id) != nil {
            content(id)
        } else {
            Text("Position not found")
                .font(Type.body)
                .foregroundStyle(Palette.inkTertiary)
        }
    }
}
