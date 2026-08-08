import SwiftUI

/// The four judgements, side by side. This is the unit of scanning: the user
/// should be able to read a whole portfolio in a few seconds without meeting a
/// single number they did not ask for.
struct JudgementStrip: View {
    let holding: Holding
    var compact: Bool = false

    private var items: [(String, String, Tone)] {
        [
            ("Thesis", holding.thesisState.short, holding.thesisState.tone),
            ("Business", holding.business.short, holding.business.tone),
            ("Valuation", holding.valuation.short, holding.valuation.tone),
            ("Sentiment", holding.sentiment.short, holding.sentiment.tone)
        ]
    }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            ForEach(items, id: \.0) { label, value, tone in
                VStack(alignment: .leading, spacing: 4) {
                    Text(label)
                        .font(.system(size: 9.5, weight: .semibold))
                        .tracking(0.6)
                        .textCase(.uppercase)
                        .foregroundStyle(Palette.inkQuaternary)
                    Text(value)
                        .font(.system(size: compact ? 12 : 13, weight: .medium))
                        .foregroundStyle(tone == .neutral ? Palette.inkSecondary : tone.color)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

struct HoldingCard: View {
    let holding: Holding
    var namespace: Namespace.ID

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(holding.shortName)
                        .font(Type.title)
                        .foregroundStyle(Palette.ink)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(holding.hasShortName
                         ? "\(holding.exchange) · \(holding.ticker) · \(holding.name)"
                         : "\(holding.exchange) · \(holding.ticker)")
                        .font(Type.micro)
                        .foregroundStyle(Palette.inkTertiary)
                        .lineLimit(1)
                }
                Spacer(minLength: 10)
                TonePill(text: holding.attention.short, tone: holding.attention.tone)
                    .fixedSize()
            }

            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(Fmt.money(holding.price, currency: holding.currency))
                    .font(Type.figure(30))
                    .foregroundStyle(Palette.ink)
                Text(Fmt.percent(holding.priceReturn * 100, places: 0, signed: true))
                    .font(Type.mono(14, .medium))
                    .foregroundStyle(Palette.inkSecondary)
                Text("since purchase")
                    .font(Type.caption)
                    .foregroundStyle(Palette.inkTertiary)
            }
            .padding(.top, 14)

            Text(holding.situation)
                .font(Type.quote)
                .foregroundStyle(Palette.inkSecondary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 10)

            Hairline().padding(.vertical, 15)

            JudgementStrip(holding: holding)
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
}

/// Positions with nothing to say get a quieter treatment. Not hidden, just
/// smaller — the hierarchy itself is the message.
struct QuietHoldingRow: View {
    let holding: Holding

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text(holding.shortName)
                    .font(Type.bodyMedium)
                    .foregroundStyle(Palette.ink)
                    .lineLimit(1)
                Spacer(minLength: 8)
                Text(Fmt.money(holding.price, currency: holding.currency))
                    .font(Type.mono(15))
                    .foregroundStyle(Palette.ink)
                Text(Fmt.percent(holding.priceReturn * 100, places: 0, signed: true))
                    .font(Type.mono(13))
                    .foregroundStyle(Palette.inkTertiary)
                    .frame(width: 46, alignment: .trailing)
            }
            JudgementStrip(holding: holding, compact: true)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Palette.surface.opacity(0.6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Palette.hairline, lineWidth: 1)
        )
    }
}
