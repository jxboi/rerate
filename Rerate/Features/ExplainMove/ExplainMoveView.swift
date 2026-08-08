import SwiftUI

struct ExplainMoveView: View {
    @Environment(Store.self) private var store
    let holdingID: UUID
    @State private var lensIndex = 0
    @State private var appeared = false

    private var h: Holding { store.holding(holdingID) ?? SeedDBS.holding }
    private var lens: MoveLens { h.lenses[min(lensIndex, h.lenses.count - 1)] }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                hero
                thesisStatement
                lensPicker
                identity
                splitBar
                components
                dividends
                reratingSection
                flowsLink
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 48)
        }
        .background(Palette.canvas)
        .scrollIndicators(.hidden)
        .navigationTitle("Explain the move")
        .navigationBarTitleDisplayMode(.inline)
        .task { withAnimation(Motion.gentle) { appeared = true } }
    }

    // MARK: Hero

    private var hero: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Why did \(h.shortName) \(h.priceReturn >= 0 ? "rise" : "fall")?")
                .font(Type.statement)
                .foregroundStyle(Palette.ink)
                .padding(.top, 8)

            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(Fmt.money(h.averageCost, currency: h.currency))
                    .font(Type.figure(22))
                    .foregroundStyle(Palette.inkTertiary)
                Image(systemName: "arrow.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Palette.inkQuaternary)
                Text(Fmt.money(h.price, currency: h.currency))
                    .font(Type.figure(22))
                    .foregroundStyle(Palette.ink)
                Spacer()
                Text(Fmt.percent(h.priceReturn * 100, places: 0, signed: true))
                    .font(Type.mono(17, .medium))
                    .foregroundStyle(Palette.ink)
            }
            .padding(.top, 18)

            Text("Over \(yearsHeld) since your purchase")
                .font(Type.caption)
                .foregroundStyle(Palette.inkTertiary)
                .padding(.top, 8)
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 8)
    }

    private var yearsHeld: String { Fmt.duration(since: h.purchaseDate) }

    // MARK: The idea

    private var thesisStatement: some View {
        Inset {
            Text("A stock can rise because the business became more valuable — or because investors became willing to pay more for the same business.\n\nThese feel identical in your account balance. They are not the same thing at all.")
                .font(Type.quote)
                .foregroundStyle(Palette.ink)
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 30)
    }

    // MARK: Lens

    private var lensPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionLabel("Measured against")
            HStack(spacing: 8) {
                ForEach(Array(h.lenses.enumerated()), id: \.element.id) { i, l in
                    Button {
                        Haptic.detent()
                        withAnimation(Motion.gentle) { lensIndex = i }
                    } label: {
                        Text(l.name)
                            .font(Type.callout)
                            .foregroundStyle(i == lensIndex ? Palette.canvas : Palette.inkSecondary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 9)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(i == lensIndex ? Palette.ink : Palette.surfaceSunken)
                            )
                    }
                    .buttonStyle(.pressable(scale: 0.96, haptic: false))
                }
                Spacer(minLength: 0)
            }
        }
        .padding(.top, 36)
    }

    // MARK: The identity

    /// Showing the arithmetic makes the split verifiable rather than asserted.
    private var identity: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                identityTerm(Fmt.money(h.price, currency: h.currency), "Price", bold: true)
                Text("=").font(Type.figure(15)).foregroundStyle(Palette.inkQuaternary)
                identityTerm(lens.anchorUnit.format(lens.anchorEnd), lens.anchorName, bold: false)
                Text("×").font(Type.figure(15)).foregroundStyle(Palette.inkQuaternary)
                identityTerm(Fmt.multiple(lens.multipleEnd), lens.multipleName, bold: false)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Palette.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Palette.hairline, lineWidth: 1)
        )
        .padding(.top, 18)
    }

    private func identityTerm(_ value: String, _ label: String, bold: Bool) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(Type.figure(17, bold ? .semibold : .regular))
                .foregroundStyle(Palette.ink)
                .contentTransition(.numericText())
            Text(label)
                .font(.system(size: 9.5, weight: .medium))
                .foregroundStyle(Palette.inkTertiary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Split

    private var splitBar: some View {
        VStack(alignment: .leading, spacing: 14) {
            GeometryReader { geo in
                HStack(spacing: 4) {
                    segment(
                        width: geo.size.width * CGFloat(lens.anchorShare) - 2,
                        fill: Palette.ink,
                        title: "\(Int((lens.anchorShare * 100).rounded()))%",
                        subtitle: "the business",
                        onDark: true
                    )
                    segment(
                        width: geo.size.width * CGFloat(lens.multipleShare) - 2,
                        fill: Palette.caution.opacity(0.22),
                        title: "\(Int((lens.multipleShare * 100).rounded()))%",
                        subtitle: "re-rating",
                        onDark: false
                    )
                }
            }
            .frame(height: 78)

            Text(lens.explanation)
                .font(Type.quote)
                .foregroundStyle(Palette.inkSecondary)
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
                .id(lens.id)
                .transition(.opacity)
        }
        .padding(.top, 22)
    }

    private func segment(width: CGFloat, fill: Color, title: String, subtitle: String, onDark: Bool) -> some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(fill)
            .frame(width: max(width, 40))
            .overlay(alignment: .bottomLeading) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(Type.figure(20, .medium))
                        .contentTransition(.numericText())
                    Text(subtitle)
                        .font(.system(size: 10, weight: .medium))
                        .opacity(0.75)
                }
                .foregroundStyle(onDark ? Palette.canvas : Palette.ink)
                .padding(12)
            }
    }

    // MARK: Components

    private var components: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionLabel("Broken down")
                .padding(.bottom, 8)

            componentRow(
                title: lens.anchorName,
                from: lens.anchorUnit.format(lens.anchorStart),
                to: lens.anchorUnit.format(lens.anchorEnd),
                change: lens.anchorGrowth,
                share: lens.anchorShare,
                isRerating: false,
                detail: anchorDetail
            )
            Hairline().padding(.vertical, 4)
            componentRow(
                title: lens.multipleName,
                from: Fmt.multiple(lens.multipleStart),
                to: Fmt.multiple(lens.multipleEnd),
                change: lens.multipleGrowth,
                share: lens.multipleShare,
                isRerating: true,
                detail: multipleDetail
            )
        }
        .padding(.top, 36)
    }

    private var anchorDetail: String {
        switch h.kind {
        case .bank:
            "Book value per share grows when the bank earns more than it pays out. This is the part of your return the business genuinely produced — retained profit, compounding inside the company. It does not depend on anyone's opinion, and it cannot be taken away by a change in mood."
        case .reit:
            "Net asset value per unit reflects what the properties are independently valued at, less debt. It moves with rents, cap rates and the valuers' view of the assets themselves."
        default:
            "Earnings per share is what the company actually produced for each share you own. Growth here is the part of your return the business created rather than the market granted."
        }
    }

    private var multipleDetail: String {
        "This is the part that depends on other people. \(Fmt.multiple(lens.multipleStart)) means investors paid \(Fmt.multiple(lens.multipleStart)) for each dollar of \(lens.anchorName.lowercased()) when you bought. Today they pay \(Fmt.multiple(lens.multipleEnd)). Nothing inside the company forced that change, and nothing inside the company prevents it reversing. Re-rating is the portion of a return that can be handed back without the business doing anything wrong."
    }

    private func componentRow(
        title: String,
        from: String,
        to: String,
        change: Double,
        share: Double,
        isRerating: Bool,
        detail: String
    ) -> some View {
        Unfold {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .firstTextBaseline) {
                    HStack(spacing: 8) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(isRerating ? Palette.caution.opacity(0.45) : Palette.ink)
                            .frame(width: 9, height: 9)
                        Text(title)
                            .font(Type.bodyMedium)
                            .foregroundStyle(Palette.ink)
                    }
                    Spacer(minLength: 8)
                    Text(Fmt.percent(change * 100, signed: true))
                        .font(Type.mono(15, .medium))
                        .foregroundStyle(isRerating ? Palette.caution : Palette.ink)
                }
                HStack(spacing: 8) {
                    Text(from).font(Type.mono(13)).foregroundStyle(Palette.inkTertiary)
                    Image(systemName: "arrow.right").font(.system(size: 8, weight: .bold)).foregroundStyle(Palette.inkQuaternary)
                    Text(to).font(Type.mono(13)).foregroundStyle(Palette.inkSecondary)
                    Spacer()
                    Text("\(Int((share * 100).rounded()))% of the move")
                        .font(Type.micro)
                        .foregroundStyle(Palette.inkTertiary)
                }
            }
            .padding(.vertical, 14)
        } content: {
            Text(detail)
                .font(Type.callout)
                .foregroundStyle(Palette.inkSecondary)
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 16)
        }
    }

    // MARK: Dividends

    private var dividends: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionLabel("And separately")
            HStack(alignment: .firstTextBaseline) {
                Text("Dividends received")
                    .font(Type.body)
                    .foregroundStyle(Palette.ink)
                Spacer()
                Text(Fmt.money(h.dividendsPerShareSincePurchase, currency: h.currency) + " per share")
                    .font(Type.mono(14))
                    .foregroundStyle(Palette.inkSecondary)
                Text(Fmt.percent(h.dividendReturn * 100, places: 0, signed: true))
                    .font(Type.mono(14, .medium))
                    .foregroundStyle(Palette.ink)
            }
            Text("Cash you have already received and cannot lose to a change of sentiment. Adding it to the price move gives a total return of \(Fmt.percent(h.totalReturn * 100, places: 0, signed: true)).")
                .font(Type.caption)
                .foregroundStyle(Palette.inkTertiary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Palette.surfaceSunken)
        )
        .padding(.top, 30)
    }

    // MARK: Re-rating drivers

    private var reratingSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Why did investors start paying more?")
                .font(Type.title)
                .foregroundStyle(Palette.ink)
                .padding(.bottom, 8)

            Text("Some of these can be evidenced. Some are readings of the evidence. Rerate keeps them apart, and says when it does not know.")
                .font(Type.callout)
                .foregroundStyle(Palette.inkSecondary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 16)

            ForEach(Array(h.reratingDrivers.enumerated()), id: \.element.id) { i, driver in
                if i > 0 { Hairline().padding(.vertical, 2) }
                Unfold {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .top, spacing: 10) {
                            Text(driver.name)
                                .font(Type.bodyMedium)
                                .foregroundStyle(Palette.ink)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer(minLength: 4)
                        }
                        HStack(spacing: 12) {
                            ClaimTag(kind: driver.kind)
                            ConfidenceMark(level: driver.confidence)
                        }
                        Text(driver.summary)
                            .font(Type.caption)
                            .foregroundStyle(Palette.inkSecondary)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.vertical, 14)
                } content: {
                    Text(driver.detail)
                        .font(Type.callout)
                        .foregroundStyle(Palette.inkSecondary)
                        .lineSpacing(5)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.bottom, 16)
                }
            }
        }
        .padding(.top, 42)
    }

    private var flowsLink: some View {
        NavigationLink(value: Route.flows(h.id)) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Who appears to be buying?")
                        .font(Type.body)
                        .foregroundStyle(Palette.ink)
                    Text("Flow evidence, and what it does not tell you")
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
        .padding(.top, 22)
        .overlay(alignment: .top) { Hairline().padding(.top, 22) }
    }
}
