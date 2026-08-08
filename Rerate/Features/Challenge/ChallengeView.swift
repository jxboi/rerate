import SwiftUI

struct ChallengeView: View {
    @Environment(Store.self) private var store
    let holdingID: UUID
    @State private var showingBear = true
    @State private var appeared = false
    @Namespace private var indicator

    private var h: Holding { store.holding(holdingID) ?? SeedDBS.holding }
    private var argument: Argument { showingBear ? h.bearCase : h.bullCase }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                intro
                toggle
                argumentCard
                crux
                closing
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 48)
        }
        .background(Palette.canvas)
        .scrollIndicators(.hidden)
        .navigationTitle("Challenge")
        .navigationBarTitleDisplayMode(.inline)
        .task { withAnimation(Motion.gentle) { appeared = true } }
    }

    private var intro: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("You wrote a case for owning this. Here is the strongest version of the opposite.")
                .font(Type.statement)
                .foregroundStyle(Palette.ink)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 8)

            Text("Not to talk you out of it. The point is to find out whether you own this because the evidence supports it, or because you already own it.")
                .font(Type.callout)
                .foregroundStyle(Palette.inkSecondary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 8)
    }

    private var toggle: some View {
        HStack(spacing: 0) {
            tab("The case against", selected: showingBear) {
                withAnimation(Motion.snappy) { showingBear = true }
            }
            tab("The case for", selected: !showingBear) {
                withAnimation(Motion.snappy) { showingBear = false }
            }
        }
        .padding(3)
        .background(
            RoundedRectangle(cornerRadius: 13, style: .continuous).fill(Palette.surfaceSunken)
        )
        .padding(.top, 32)
    }

    private func tab(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button {
            Haptic.detent()
            action()
        } label: {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(selected ? Palette.ink : Palette.inkTertiary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
                .background {
                    if selected {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Palette.surface)
                            .shadow(color: .black.opacity(0.05), radius: 3, y: 1)
                            .matchedGeometryEffect(id: "tab", in: indicator)
                    }
                }
        }
        .buttonStyle(.pressable(scale: 0.99, haptic: false))
    }

    private var argumentCard: some View {
        VStack(alignment: .leading, spacing: 22) {
            Text(argument.stance)
                .font(Type.quote)
                .foregroundStyle(Palette.ink)
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(argument.points.enumerated()), id: \.element.id) { i, point in
                    if i > 0 { Hairline().padding(.vertical, 3) }
                    VStack(alignment: .leading, spacing: 8) {
                        Text(point.claim)
                            .font(Type.bodyMedium)
                            .foregroundStyle(Palette.ink)
                            .fixedSize(horizontal: false, vertical: true)
                        ClaimTag(kind: point.kind)
                        Text(point.support)
                            .font(Type.callout)
                            .foregroundStyle(Palette.inkSecondary)
                            .lineSpacing(4)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.vertical, 14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            Inset(tone: showingBear ? .caution : .affirm) {
                VStack(alignment: .leading, spacing: 7) {
                    Text("What would invalidate this")
                        .sectionLabelStyle(showingBear ? Palette.caution : Palette.affirm)
                    Text(argument.invalidatedBy)
                        .font(Type.callout)
                        .foregroundStyle(Palette.ink)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Palette.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Palette.hairline, lineWidth: 1)
        )
        .padding(.top, 18)
        .id(argument.title)
        .transition(.asymmetric(
            insertion: .opacity.combined(with: .offset(y: 10)),
            removal: .opacity
        ))
    }

    /// Both cases usually rest on the same unresolved question. Naming it is
    /// more useful than either argument.
    private var crux: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Both cases turn on the same thing")
                .sectionLabelStyle()
            Text(h.mostUncertainAssumption)
                .font(Type.quote)
                .foregroundStyle(Palette.ink)
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Palette.accentSoft)
        )
        .padding(.top, 26)
    }

    private var closing: some View {
        Text("Rerate does not have a view on which of these is right, and will not tell you what to do about it. Its job is to make sure you have seen both before you decide.")
            .font(Type.caption)
            .foregroundStyle(Palette.inkTertiary)
            .lineSpacing(4)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.top, 28)
    }
}
