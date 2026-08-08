import SwiftUI

struct SignalsView: View {
    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss
    let onOpen: (String) -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    intro
                    list
                    principle
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .background(Palette.canvas)
            .scrollIndicators(.hidden)
            .navigationTitle("Signals")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Palette.inkSecondary)
                }
                ToolbarItem(placement: .primaryAction) {
                    if !store.unreadSignals.isEmpty {
                        Button("Mark read") {
                            Haptic.soft()
                            withAnimation(Motion.gentle) { store.markAllRead() }
                        }
                        .font(Type.callout)
                        .foregroundStyle(Palette.accent)
                    }
                }
            }
        }
    }

    private var intro: some View {
        Text(store.unreadSignals.isEmpty
             ? "Nothing new. Rerate stays quiet unless something changes that affects your reasoning."
             : "\(store.unreadSignals.count) \(store.unreadSignals.count == 1 ? "change" : "changes") worth your attention.")
            .font(Type.callout)
            .foregroundStyle(Palette.inkSecondary)
            .lineSpacing(4)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.top, 8)
            .padding(.bottom, 22)
    }

    private var list: some View {
        VStack(spacing: 12) {
            ForEach(store.signals.sorted { $0.date > $1.date }) { signal in
                SignalCard(signal: signal) {
                    store.markRead(signal)
                    onOpen(signal.ticker)
                }
            }
        }
    }

    private var principle: some View {
        Inset {
            VStack(alignment: .leading, spacing: 8) {
                Text("What Rerate will never send you")
                    .font(Type.bodyMedium)
                    .foregroundStyle(Palette.ink)
                Text("Daily price moves. Percentage changes. Anything that is only news because it happened today.\n\nA notification here means a condition you defined has changed, a valuation has crossed a level you set, or a result has moved something in your thesis. If it is not worth opening, it should not have been sent.")
                    .font(Type.caption)
                    .foregroundStyle(Palette.inkSecondary)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.top, 30)
    }
}

struct SignalCard: View {
    let signal: Signal
    let onOpen: () -> Void
    @State private var expanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                Haptic.soft()
                withAnimation(Motion.gentle) { expanded.toggle() }
            } label: {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 8) {
                        ZStack {
                            Circle().fill(signal.kind.tone.soft).frame(width: 20, height: 20)
                            Image(systemName: signal.kind.icon)
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(signal.kind.tone.color)
                        }
                        Text(signal.ticker)
                            .font(Type.micro)
                            .foregroundStyle(Palette.inkSecondary)
                        Text("·").foregroundStyle(Palette.inkQuaternary)
                        Text(signal.kind.rawValue)
                            .font(Type.micro)
                            .foregroundStyle(Palette.inkTertiary)
                        Spacer(minLength: 6)
                        if !signal.read {
                            Circle().fill(Palette.accent).frame(width: 6, height: 6)
                        }
                        Text(relativeDate)
                            .font(Type.micro)
                            .foregroundStyle(Palette.inkQuaternary)
                    }

                    Text(signal.headline)
                        .font(Type.title)
                        .foregroundStyle(Palette.ink)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.pressable(scale: 0.99, haptic: false))

            if expanded {
                VStack(alignment: .leading, spacing: 16) {
                    Text(signal.body)
                        .font(Type.callout)
                        .foregroundStyle(Palette.inkSecondary)
                        .lineSpacing(5)
                        .fixedSize(horizontal: false, vertical: true)

                    Button {
                        Haptic.tap()
                        onOpen()
                    } label: {
                        HStack(spacing: 6) {
                            Text("Open position").font(Type.micro)
                            Image(systemName: "arrow.right").font(.system(size: 9, weight: .bold))
                        }
                        .foregroundStyle(Palette.accent)
                    }
                }
                .padding(.top, 14)
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .offset(y: -6)),
                    removal: .opacity
                ))
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(signal.read ? Palette.surface.opacity(0.6) : Palette.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Palette.hairline, lineWidth: 1)
        )
    }

    private var relativeDate: String {
        let days = Calendar.current.dateComponents([.day], from: signal.date, to: Date()).day ?? 0
        switch days {
        case ..<1: return "Today"
        case 1: return "Yesterday"
        case 2..<7: return "\(days)d ago"
        case 7..<30: return "\(days / 7)w ago"
        default: return Fmt.compactDate.string(from: signal.date)
        }
    }
}
