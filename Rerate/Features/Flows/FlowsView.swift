import SwiftUI

struct FlowsView: View {
    @Environment(Store.self) private var store
    let holdingID: UUID
    @State private var appeared = false

    private var h: Holding { store.holding(holdingID) ?? SeedDBS.holding }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header
                verdict
                evidence
                sentiment
                limits
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 48)
        }
        .background(Palette.canvas)
        .scrollIndicators(.hidden)
        .navigationTitle("Flows & sentiment")
        .navigationBarTitleDisplayMode(.inline)
        .task { withAnimation(Motion.gentle) { appeared = true } }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Who appears to be driving the move?")
                .font(Type.statement)
                .foregroundStyle(Palette.ink)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 8)
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 8)
    }

    private var verdict: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                TonePill(text: h.flows.rawValue, tone: h.flows.tone)
                Spacer()
                ConfidenceMark(level: h.flowEvidence.first?.confidence ?? .weak)
            }
            Text(ReviewComposer.sections(h).first { $0.title.contains("buying") }?.body ?? "")
                .font(Type.quote)
                .foregroundStyle(Palette.ink)
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Palette.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Palette.hairline, lineWidth: 1)
        )
        .padding(.top, 26)
    }

    private var evidence: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionLabel("The evidence")
                .padding(.top, 40)
                .padding(.bottom, 6)

            ForEach(Array(h.flowEvidence.enumerated()), id: \.element.id) { i, e in
                if i > 0 { Hairline() }
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(e.actor)
                            .font(Type.bodyMedium)
                            .foregroundStyle(Palette.ink)
                        Spacer(minLength: 8)
                        Text(e.magnitude)
                            .font(Type.mono(14, .medium))
                            .foregroundStyle(Palette.ink)
                    }
                    HStack(spacing: 10) {
                        Text(e.direction)
                            .font(Type.caption)
                            .foregroundStyle(Palette.inkSecondary)
                        Text("·").foregroundStyle(Palette.inkQuaternary)
                        Text(e.window)
                            .font(Type.caption)
                            .foregroundStyle(Palette.inkTertiary)
                        Spacer(minLength: 4)
                        ConfidenceMark(level: e.confidence)
                    }
                    if !e.note.isEmpty {
                        Text(e.note)
                            .font(Type.caption)
                            .foregroundStyle(Palette.inkTertiary)
                            .lineSpacing(3)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.vertical, 16)
                .opacity(appeared ? 1 : 0)
                .animation(Motion.cascade(i, base: 0.05), value: appeared)
            }
        }
    }

    private var sentiment: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionLabel("Attention")
            HStack(alignment: .firstTextBaseline) {
                Text(h.sentiment.rawValue)
                    .font(Type.title)
                    .foregroundStyle(h.sentiment.tone == .neutral ? Palette.ink : h.sentiment.tone.color)
                Spacer()
            }
            Text(attentionNarrative)
                .font(Type.callout)
                .foregroundStyle(Palette.inkSecondary)
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Palette.surfaceSunken)
        )
        .padding(.top, 34)
    }

    private var attentionNarrative: String {
        switch h.sentiment {
        case .heating:
            return "Mentions, search interest and brokerage coverage have all risen sharply over the past two quarters. Rising attention is not itself a reason to do anything — but it changes who the marginal buyer is, and the marginal buyer sets the price.\n\nNote the tension with the flow data above: attention has risen while retail investors were net sellers. People are noticing this stock because it went up, which is the usual order of events."
        case .warming:
            return "Somewhat more discussion than usual, without the sharp increase that tends to accompany a crowded position."
        case .normal:
            return "Nothing unusual. Coverage and discussion are in line with a company of this size."
        case .quiet:
            return "Largely ignored. That is neither good nor bad on its own, but it does mean the price is being set by fewer participants and can move more on modest flows."
        }
    }

    private var limits: some View {
        Inset {
            VStack(alignment: .leading, spacing: 8) {
                Text("What flow data cannot tell you")
                    .font(Type.bodyMedium)
                    .foregroundStyle(Palette.ink)
                Text("Flows show who transacted, not why. A fund buying because its mandate changed looks identical to a fund buying out of conviction. Index-driven purchases look like enthusiasm. And every buyer had a seller.\n\nRerate reports flows because they are useful context for a re-rating, and marks the confidence because the data is genuinely uneven. Where the evidence does not support a conclusion, it says so rather than inventing one.")
                    .font(Type.caption)
                    .foregroundStyle(Palette.inkSecondary)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.top, 34)
    }
}
