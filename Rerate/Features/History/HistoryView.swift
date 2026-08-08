import SwiftUI

/// The investment memory. Read top to bottom it shows not what the stock did,
/// but what the investor understood at each point — which is the thing that
/// actually compounds.
struct HistoryView: View {
    @Environment(Store.self) private var store
    let holdingID: UUID
    @State private var drawn: CGFloat = 0

    private var h: Holding { store.holding(holdingID) ?? SeedDBS.holding }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                intro

                ZStack(alignment: .topLeading) {
                    // The spine, drawn once as the screen settles.
                    GeometryReader { geo in
                        Capsule()
                            .fill(Palette.hairlineStrong)
                            .frame(width: 1.5, height: geo.size.height * drawn)
                            .offset(x: 4.25)
                    }

                    VStack(alignment: .leading, spacing: 0) {
                        purchaseNode
                        ForEach(Array(h.reviews.enumerated()), id: \.element.id) { i, review in
                            reviewNode(review, index: i)
                        }
                        todayNode
                    }
                }
                .padding(.top, 30)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 48)
        }
        .background(Palette.canvas)
        .scrollIndicators(.hidden)
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            withAnimation(.easeInOut(duration: 0.9).delay(0.1)) { drawn = 1 }
        }
    }

    private var intro: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("How your thinking has changed")
                .font(Type.statement)
                .foregroundStyle(Palette.ink)
                .padding(.top, 8)
            Text("Every review you save becomes the baseline for the next one. This is the part of investing that is usually lost.")
                .font(Type.callout)
                .foregroundStyle(Palette.inkSecondary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: Nodes

    private var purchaseNode: some View {
        TimelineNode(
            date: Fmt.monthYear.string(from: h.purchaseDate),
            marker: .hollow,
            index: 0
        ) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text(Fmt.money(h.averageCost, currency: h.currency))
                        .font(Type.figure(22))
                        .foregroundStyle(Palette.ink)
                    Text("bought \(Int(h.shares).formatted()) shares")
                        .font(Type.caption)
                        .foregroundStyle(Palette.inkTertiary)
                }
                Text("“\(h.originalReasoning)”")
                    .font(Type.quote)
                    .foregroundStyle(Palette.inkSecondary)
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)
                Text("\(Fmt.multiple(h.multipleAtPurchase)) \(h.kind.valuationAnchor)")
                    .font(Type.micro)
                    .foregroundStyle(Palette.inkQuaternary)
            }
        }
    }

    private func reviewNode(_ review: Review, index: Int) -> some View {
        TimelineNode(
            date: Fmt.monthYear.string(from: review.date),
            marker: .filled(review.thesisState.tone),
            index: index + 1
        ) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text(Fmt.money(review.price, currency: h.currency))
                        .font(Type.figure(22))
                        .foregroundStyle(Palette.ink)
                    Text(Fmt.multiple(review.anchorMultiple))
                        .font(Type.mono(13))
                        .foregroundStyle(Palette.inkTertiary)
                    Spacer(minLength: 4)
                    Text("\(review.conditionsIntact)/\(review.conditionsTotal)")
                        .font(Type.mono(12, .medium))
                        .foregroundStyle(review.thesisState.tone.color)
                }

                if let prompt = review.prompt {
                    Text("“\(prompt)”")
                        .font(Type.quote)
                        .foregroundStyle(Palette.ink)
                        .italic()
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.leading, 10)
                        .overlay(alignment: .leading) {
                            Capsule().fill(Palette.hairlineStrong).frame(width: 2)
                        }
                }

                Text(review.conclusion)
                    .font(Type.callout)
                    .foregroundStyle(Palette.inkSecondary)
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)

                TonePill(text: review.thesisState.rawValue, tone: review.thesisState.tone)
            }
        }
    }

    private var todayNode: some View {
        TimelineNode(
            date: "Today",
            marker: .current,
            index: h.reviews.count + 1,
            isLast: true
        ) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text(Fmt.money(h.price, currency: h.currency))
                        .font(Type.figure(22))
                        .foregroundStyle(Palette.ink)
                    Text(Fmt.multiple(h.multiple))
                        .font(Type.mono(13))
                        .foregroundStyle(Palette.inkTertiary)
                    Spacer(minLength: 4)
                    Text("\(h.conditionsIntact)/\(h.conditionsTotal)")
                        .font(Type.mono(12, .medium))
                        .foregroundStyle(h.thesisState.tone.color)
                }

                Text(h.whatChangedSummary)
                    .font(Type.callout)
                    .foregroundStyle(Palette.inkSecondary)
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)

                NavigationLink(value: Route.review(h.id)) {
                    HStack(spacing: 6) {
                        Text("Review this position").font(Type.micro)
                        Image(systemName: "arrow.right").font(.system(size: 9, weight: .bold))
                    }
                    .foregroundStyle(Palette.accent)
                }
            }
        }
    }
}

struct TimelineNode<Content: View>: View {
    enum Marker {
        case hollow
        case filled(Tone)
        case current
    }

    let date: String
    let marker: Marker
    let index: Int
    var isLast: Bool = false
    @ViewBuilder var content: Content

    @State private var shown = false

    var body: some View {
        HStack(alignment: .top, spacing: 18) {
            dot
                .frame(width: 10)
                .padding(.top, 5)
                .scaleEffect(shown ? 1 : 0.3)
                .opacity(shown ? 1 : 0)

            VStack(alignment: .leading, spacing: 12) {
                Text(date)
                    .sectionLabelStyle(Palette.inkSecondary)
                content
            }
            .padding(.bottom, isLast ? 0 : 36)
            .opacity(shown ? 1 : 0)
            .offset(y: shown ? 0 : 8)
        }
        .task {
            try? await Task.sleep(nanoseconds: UInt64(200_000_000 + index * 110_000_000))
            withAnimation(.spring(response: 0.5, dampingFraction: 0.78)) { shown = true }
        }
    }

    @ViewBuilder
    private var dot: some View {
        switch marker {
        case .hollow:
            Circle()
                .strokeBorder(Palette.inkTertiary, lineWidth: 1.5)
                .background(Circle().fill(Palette.canvas))
                .frame(width: 10, height: 10)
        case .filled(let tone):
            Circle()
                .fill(tone.color)
                .frame(width: 10, height: 10)
                .overlay(Circle().strokeBorder(Palette.canvas, lineWidth: 2.5).frame(width: 15, height: 15))
        case .current:
            ZStack {
                Circle().fill(Palette.ink).frame(width: 10, height: 10)
                Circle().strokeBorder(Palette.ink.opacity(0.22), lineWidth: 4).frame(width: 18, height: 18)
            }
        }
    }
}
