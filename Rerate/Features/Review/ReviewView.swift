import SwiftUI

struct ReviewView: View {
    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss
    let holdingID: UUID

    @State private var phase: Phase = .working
    @State private var revealed = 0
    @State private var showSave = false
    @State private var saved = false

    enum Phase { case working, ready }

    private var h: Holding { store.holding(holdingID) ?? SeedDBS.holding }
    private var sections: [ReviewComposer.Section] { ReviewComposer.sections(h) }

    var body: some View {
        ZStack {
            Palette.canvas.ignoresSafeArea()
            switch phase {
            case .working:
                WorkingState(name: h.name)
                    .transition(.opacity)
            case .ready:
                content.transition(.opacity.combined(with: .offset(y: 8)))
            }
        }
        .navigationTitle("Review")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            try? await Task.sleep(nanoseconds: 2_300_000_000)
            withAnimation(Motion.gentle) { phase = .ready }
            Haptic.soft()
            for i in 0...sections.count {
                try? await Task.sleep(nanoseconds: 80_000_000)
                withAnimation(Motion.gentle) { revealed = i + 1 }
            }
        }
        .sheet(isPresented: $showSave) {
            SaveReviewSheet(holdingID: holdingID) { saved = true }
                .presentationDetents([.height(390)])
                .presentationDragIndicator(.visible)
        }
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header
                ForEach(Array(sections.enumerated()), id: \.element.id) { i, section in
                    sectionView(section)
                        .opacity(i < revealed ? 1 : 0)
                        .offset(y: i < revealed ? 0 : 10)
                }
                saveAction
                footer
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 48)
        }
        .scrollIndicators(.hidden)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(Fmt.shortDate.string(from: Date()))
                    .sectionLabelStyle()
                Spacer()
                TonePill(text: h.attention.rawValue, tone: h.attention.tone)
            }
            .padding(.top, 8)

            Text(ReviewComposer.headline(h))
                .font(Type.statement)
                .foregroundStyle(Palette.ink)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            SplitPreviewBar(lens: h.primaryLens)
                .padding(.top, 4)
        }
        .padding(.bottom, 12)
    }

    private func sectionView(_ section: ReviewComposer.Section) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Hairline().padding(.vertical, 12)

            HStack(alignment: .firstTextBaseline) {
                Text(section.title)
                    .font(Type.title)
                    .foregroundStyle(Palette.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 8)
            }

            if section.kind != nil || section.confidence != nil {
                HStack(spacing: 12) {
                    if let kind = section.kind { ClaimTag(kind: kind) }
                    if let c = section.confidence { ConfidenceMark(level: c) }
                }
            }

            Text(section.body)
                .font(Type.quote)
                .foregroundStyle(Palette.inkSecondary)
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)

            if !section.bullets.isEmpty {
                VStack(alignment: .leading, spacing: 9) {
                    ForEach(section.bullets, id: \.self) { bullet in
                        HStack(alignment: .top, spacing: 9) {
                            Circle()
                                .fill(Palette.inkQuaternary)
                                .frame(width: 3.5, height: 3.5)
                                .padding(.top, 7)
                            Text(bullet)
                                .font(Type.caption)
                                .foregroundStyle(Palette.inkTertiary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(.bottom, 14)
    }

    private var saveAction: some View {
        VStack(spacing: 12) {
            if saved {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .semibold))
                    Text("Saved to your investment history")
                        .font(Type.bodyMedium)
                }
                .foregroundStyle(Palette.affirm)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 17)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Palette.affirmSoft)
                )
                .transition(.scale(scale: 0.96).combined(with: .opacity))
            } else {
                PrimaryAction(title: "Save this review", icon: "bookmark") {
                    showSave = true
                }
            }
        }
        .animation(Motion.gentle, value: saved)
        .padding(.top, 34)
    }

    private var footer: some View {
        Text("Rerate does not issue buy, hold or sell recommendations. This review describes what changed and what today's price assumes. The decision is yours.")
            .font(Type.micro)
            .foregroundStyle(Palette.inkQuaternary)
            .lineSpacing(3)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.top, 26)
    }
}

// MARK: - Working state

/// Loading should feel like thinking, not like waiting. The lines describe what
/// is actually being compared, and the rule fills at a steady, unhurried pace.
struct WorkingState: View {
    let name: String
    @State private var step = 0
    @State private var progress: CGFloat = 0

    private var lines: [String] {
        [
            "Reading the last four quarters of \(name)",
            "Comparing against the conditions you set",
            "Separating the business from the valuation",
            "Weighing the flow evidence",
            "Writing it up"
        ]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 26) {
            Spacer()

            Text(lines[min(step, lines.count - 1)])
                .font(Type.quote)
                .foregroundStyle(Palette.inkSecondary)
                .id(step)
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .offset(y: 6)),
                    removal: .opacity.combined(with: .offset(y: -6))
                ))
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Palette.hairline).frame(height: 2)
                    Capsule().fill(Palette.ink).frame(width: geo.size.width * progress, height: 2)
                }
            }
            .frame(height: 2)

            Spacer()
        }
        .padding(.horizontal, 32)
        .task {
            withAnimation(.easeInOut(duration: 2.3)) { progress = 1 }
            for i in 1..<lines.count {
                try? await Task.sleep(nanoseconds: 460_000_000)
                withAnimation(Motion.snappy) { step = i }
            }
        }
    }
}

// MARK: - Save

struct SaveReviewSheet: View {
    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss
    let holdingID: UUID
    let onSaved: () -> Void

    @State private var note = ""
    @FocusState private var focused: Bool

    private var h: Holding { store.holding(holdingID) ?? SeedDBS.holding }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Save this review")
                    .font(Type.title)
                    .foregroundStyle(Palette.ink)
                Text("Next time you open \(h.name), Rerate will start from here rather than from the beginning.")
                    .font(Type.callout)
                    .foregroundStyle(Palette.inkSecondary)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("What brought you here? (optional)").sectionLabelStyle()
                TextField("Everyone is talking about this. Is it becoming speculative?", text: $note, axis: .vertical)
                    .font(Type.body)
                    .lineLimit(2...4)
                    .focused($focused)
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Palette.surface)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(focused ? Palette.accent.opacity(0.5) : Palette.hairline, lineWidth: 1)
                    )
                    .animation(Motion.snappy, value: focused)
            }

            Spacer(minLength: 0)

            PrimaryAction(title: "Save to history") {
                store.recordReview(
                    holdingID: holdingID,
                    prompt: note.trimmingCharacters(in: .whitespaces).isEmpty ? nil : note,
                    conclusion: ReviewComposer.headline(h)
                )
                Haptic.settled()
                onSaved()
                dismiss()
            }
        }
        .padding(22)
        .background(Palette.canvas)
    }
}
