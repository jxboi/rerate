import SwiftUI

struct OnboardingFlow: View {
    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss
    var isSheet: Bool = false

    @State private var step = 0
    @State private var entry: CatalogueEntry?
    @State private var costText = ""
    @State private var sharesText = ""
    @State private var purchaseDate = Calendar.current.date(byAdding: .year, value: -2, to: Date()) ?? Date()
    @State private var reasoning = ""
    @State private var candidates: [ThesisCondition] = []

    private var totalSteps: Int { isSheet ? 4 : 5 }
    private var stepOffset: Int { isSheet ? 0 : 1 }

    var body: some View {
        VStack(spacing: 0) {
            if step > 0 || isSheet { progress }
            content
        }
        .background(Palette.canvas.ignoresSafeArea())
        .onAppear {
            if isSheet && step == 0 { step = 1 }
            #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("-obPrefill"), entry == nil {
                entry = Catalogue.entry(ticker: "D05")
                costText = "39.69"
                sharesText = "1200"
                reasoning = "Strong Singapore bank, attractive dividend, high ROE, growing wealth-management business, long-term compounder."
                candidates = ThesisExtractor.extract(from: reasoning, kind: .bank).map {
                    ThesisCondition(
                        statement: $0.statement, measure: $0.measure, test: $0.test,
                        status: .passing, reading: "—", evidence: $0.source
                    )
                }
                step = 4
            }
            #endif
        }
    }

    private var progress: some View {
        HStack(spacing: 5) {
            ForEach(1...totalSteps, id: \.self) { i in
                Capsule()
                    .fill(i <= step - (isSheet ? 0 : 0) ? Palette.ink : Palette.hairline)
                    .frame(height: 2.5)
                    .animation(Motion.snappy, value: step)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 12)
        .padding(.bottom, 6)
    }

    @ViewBuilder
    private var content: some View {
        switch step {
        case 0: welcome
        case 1: pickStock
        case 2: costBasis
        case 3: why
        default: thesis
        }
    }

    private func advance() {
        Haptic.tap()
        withAnimation(Motion.gentle) { step += 1 }
    }

    private func back() {
        Haptic.soft()
        withAnimation(Motion.gentle) { step -= 1 }
    }

    // MARK: Step 0 — welcome

    private var welcome: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()
            Text("Rerate")
                .font(.system(size: 17, weight: .semibold, design: .serif))
                .foregroundStyle(Palette.inkTertiary)

            Text("You know what you paid.\nRerate remembers why.")
                .font(Type.display(32))
                .foregroundStyle(Palette.ink)
                .lineSpacing(6)
                .padding(.top, 18)

            Text("Start with something you already own. It takes about a minute, and there is no tutorial.")
                .font(Type.callout)
                .foregroundStyle(Palette.inkSecondary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 20)

            Spacer()

            PrimaryAction(title: "Begin") { advance() }
        }
        .padding(.horizontal, 28)
        .padding(.bottom, 30)
        .transition(.opacity)
    }

    // MARK: Step 1 — what do you own

    private var pickStock: some View {
        StepScaffold(
            question: "What do you own?",
            hint: "Singapore-listed companies. Rerate covers a small number properly rather than everything badly.",
            canContinue: entry != nil,
            onBack: isSheet ? nil : back,
            onContinue: advance,
            onCancel: isSheet ? { dismiss() } : nil
        ) {
            StockPicker(selection: $entry)
        }
    }

    // MARK: Step 2 — cost basis

    private var costBasis: some View {
        StepScaffold(
            question: "What did you pay?",
            hint: "Your average cost, not today's price. This is the number Rerate measures everything against.",
            canContinue: Double(costText) ?? 0 > 0 && Double(sharesText) ?? 0 > 0,
            onBack: back,
            onContinue: advance
        ) {
            VStack(alignment: .leading, spacing: 26) {
                NumberField(label: "Average price", prefix: "S$", text: $costText, placeholder: "39.69")
                NumberField(label: "Shares", prefix: nil, text: $sharesText, placeholder: "1,200")

                VStack(alignment: .leading, spacing: 10) {
                    Text("Purchase date (optional)").sectionLabelStyle()
                    DatePicker("", selection: $purchaseDate, in: ...Date(), displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .tint(Palette.accent)
                }

                if let entry, let cost = Double(costText), cost > 0 {
                    Text("\(entry.name) trades at \(Fmt.money(entry.price)) today — \(Fmt.percent((entry.price / cost - 1) * 100, places: 0, signed: true)) against your cost.")
                        .font(Type.caption)
                        .foregroundStyle(Palette.inkTertiary)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                        .transition(.opacity)
                }
            }
            .animation(Motion.snappy, value: costText)
        }
    }

    // MARK: Step 3 — why

    private var why: some View {
        StepScaffold(
            question: "Why did you buy \(entry?.name.split(separator: " ").first.map(String.init) ?? "it")?",
            hint: "In your own words. Rerate turns this into something it can check for you later.",
            canContinue: reasoning.trimmingCharacters(in: .whitespaces).count > 12,
            onBack: back,
            onContinue: {
                candidates = ThesisExtractor
                    .extract(from: reasoning, kind: entry?.kind ?? .bank)
                    .map {
                        ThesisCondition(
                            statement: $0.statement, measure: $0.measure, test: $0.test,
                            status: .passing, reading: "—", evidence: $0.source
                        )
                    }
                advance()
            }
        ) {
            VStack(alignment: .leading, spacing: 16) {
                TextField(
                    placeholder,
                    text: $reasoning,
                    axis: .vertical
                )
                .font(Type.quote)
                .foregroundStyle(Palette.ink)
                .lineSpacing(5)
                .lineLimit(5...10)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Palette.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Palette.hairline, lineWidth: 1)
                )

                Text("This is the sentence you will be glad to have written in three years, when the price has moved and you cannot quite remember what you were thinking.")
                    .font(Type.caption)
                    .foregroundStyle(Palette.inkTertiary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var placeholder: String {
        switch entry?.kind {
        case .reit: "Dominant landlord, distributions should be steady, trading near book value, strong sponsor."
        case .telecom, .industrial: "Turnaround under new management, cash flow recovering, dividend rising, undemanding valuation."
        default: "Strong Singapore bank, attractive dividend, high ROE, growing wealth-management business, long-term compounder."
        }
    }

    // MARK: Step 4 — thesis

    private var thesis: some View {
        ThesisConfirmStep(
            entry: entry,
            reasoning: reasoning,
            conditions: $candidates,
            onBack: back,
            onConfirm: {
                guard let entry, let cost = Double(costText), let shares = Double(sharesText) else { return }
                let holding = HoldingFactory.make(
                    entry: entry,
                    cost: cost,
                    shares: shares,
                    purchaseDate: purchaseDate,
                    reasoning: reasoning,
                    conditions: candidates
                )
                Haptic.settled()
                store.add(holding)
                if isSheet { dismiss() }
            }
        )
    }
}

// MARK: - Scaffold

struct StepScaffold<Content: View>: View {
    let question: String
    let hint: String
    let canContinue: Bool
    var onBack: (() -> Void)?
    let onContinue: () -> Void
    var onCancel: (() -> Void)?
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                if let onBack {
                    Button(action: onBack) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Palette.inkSecondary)
                    }
                }
                Spacer()
                if let onCancel {
                    Button("Cancel", action: onCancel)
                        .font(Type.callout)
                        .foregroundStyle(Palette.inkSecondary)
                }
            }
            .frame(height: 24)
            .padding(.top, 8)

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text(question)
                        .font(Type.display(29))
                        .foregroundStyle(Palette.ink)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 20)

                    Text(hint)
                        .font(Type.callout)
                        .foregroundStyle(Palette.inkSecondary)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 12)

                    content
                        .padding(.top, 30)
                }
                .padding(.bottom, 28)
            }
            .scrollIndicators(.hidden)

            PrimaryAction(title: "Continue", action: onContinue)
                .disabled(!canContinue)
                .opacity(canContinue ? 1 : 0.28)
                .animation(Motion.snappy, value: canContinue)
                .padding(.bottom, 12)
                .padding(.top, 8)
                .background(
                    // Content should fade out under the action rather than
                    // being cut off by it.
                    LinearGradient(
                        colors: [Palette.canvas.opacity(0), Palette.canvas],
                        startPoint: .top, endPoint: .bottom
                    )
                    .frame(height: 130)
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    .allowsHitTesting(false)
                )
        }
        .padding(.horizontal, 24)
        .transition(.asymmetric(
            insertion: .opacity.combined(with: .offset(x: 24)),
            removal: .opacity.combined(with: .offset(x: -24))
        ))
    }
}

// MARK: - Pieces

struct NumberField: View {
    let label: String
    let prefix: String?
    @Binding var text: String
    let placeholder: String
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(label).sectionLabelStyle()
            HStack(spacing: 6) {
                if let prefix {
                    Text(prefix)
                        .font(Type.figure(22))
                        .foregroundStyle(Palette.inkTertiary)
                }
                TextField(placeholder, text: $text)
                    .font(Type.figure(22))
                    .foregroundStyle(Palette.ink)
                    .keyboardType(.decimalPad)
                    .focused($focused)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Palette.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(focused ? Palette.accent.opacity(0.5) : Palette.hairline, lineWidth: 1)
            )
            .animation(Motion.snappy, value: focused)
        }
    }
}

struct StockPicker: View {
    @Binding var selection: CatalogueEntry?
    @State private var query = ""

    private var results: [CatalogueEntry] { Catalogue.search(query) }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Palette.inkTertiary)
                TextField("DBS", text: $query)
                    .font(Type.body)
                    .autocorrectionDisabled()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Palette.surface))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Palette.hairline, lineWidth: 1)
            )

            VStack(spacing: 0) {
                ForEach(results) { item in
                    Button {
                        Haptic.detent()
                        withAnimation(Motion.snappy) { selection = item }
                    } label: {
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(item.name)
                                    .font(Type.body)
                                    .foregroundStyle(Palette.ink)
                                    .multilineTextAlignment(.leading)
                                    .lineLimit(1)
                                Text("SGX · \(item.ticker) · \(item.kind.label)")
                                    .font(Type.micro)
                                    .foregroundStyle(Palette.inkTertiary)
                            }
                            Spacer(minLength: 8)
                            Text(Fmt.money(item.price))
                                .font(Type.mono(14))
                                .foregroundStyle(Palette.inkSecondary)
                            Image(systemName: selection == item ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 17))
                                .foregroundStyle(selection == item ? Palette.accent : Palette.inkQuaternary)
                        }
                        .padding(.vertical, 13)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.pressable(scale: 0.99, haptic: false))
                    if item.id != results.last?.id { Hairline() }
                }
            }
        }
    }
}

// MARK: - Thesis confirmation

struct ThesisConfirmStep: View {
    let entry: CatalogueEntry?
    let reasoning: String
    @Binding var conditions: [ThesisCondition]
    let onBack: () -> Void
    let onConfirm: () -> Void

    @State private var reading = true
    @State private var revealed = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Palette.inkSecondary)
                }
                Spacer()
            }
            .frame(height: 24)
            .padding(.top, 8)

            if reading {
                readingState
            } else {
                editor
            }
        }
        .padding(.horizontal, 24)
        .task {
            try? await Task.sleep(nanoseconds: 1_300_000_000)
            withAnimation(Motion.gentle) { reading = false }
            Haptic.soft()
            for i in 0...conditions.count {
                try? await Task.sleep(nanoseconds: 110_000_000)
                withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) { revealed = i + 1 }
            }
        }
    }

    private var readingState: some View {
        VStack(alignment: .leading, spacing: 18) {
            Spacer()
            Text("Reading what you wrote")
                .font(Type.display(26))
                .foregroundStyle(Palette.inkSecondary)
            Text("“\(reasoning)”")
                .font(Type.quote)
                .foregroundStyle(Palette.inkTertiary)
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .transition(.opacity)
    }

    private var editor: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Your \(entry?.name.split(separator: " ").first.map(String.init) ?? "") thesis")
                        .font(Type.display(29))
                        .foregroundStyle(Palette.ink)
                        .padding(.top, 20)

                    Text("These are the things that have to stay true. Rerate will check them for you and say something only when one changes. Edit anything that is not quite right.")
                        .font(Type.callout)
                        .foregroundStyle(Palette.inkSecondary)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 12)

                    VStack(spacing: 0) {
                        ForEach(Array($conditions.enumerated()), id: \.element.id) { i, $condition in
                            if i > 0 { Hairline(inset: 26) }
                            HStack(alignment: .top, spacing: 12) {
                                Text("\(i + 1)")
                                    .font(Type.mono(12, .medium))
                                    .foregroundStyle(Palette.inkQuaternary)
                                    .frame(width: 14, alignment: .leading)
                                    .padding(.top, 3)

                                VStack(alignment: .leading, spacing: 5) {
                                    TextField("Condition", text: $condition.statement, axis: .vertical)
                                        .font(Type.body)
                                        .foregroundStyle(Palette.ink)
                                    Text(condition.evidence.isEmpty ? condition.measure : "from “\(condition.evidence)”")
                                        .font(Type.micro)
                                        .foregroundStyle(Palette.inkQuaternary)
                                        .lineLimit(1)
                                }

                                Button {
                                    Haptic.soft()
                                    withAnimation(Motion.snappy) {
                                        conditions.removeAll { $0.id == condition.id }
                                    }
                                } label: {
                                    Image(systemName: "minus.circle")
                                        .font(.system(size: 15))
                                        .foregroundStyle(Palette.inkQuaternary)
                                }
                                .padding(.top, 1)
                            }
                            .padding(.vertical, 14)
                            .opacity(i < revealed ? 1 : 0)
                            .offset(y: i < revealed ? 0 : 10)
                        }
                    }
                    .padding(.top, 22)

                    Button {
                        Haptic.tap()
                        withAnimation(Motion.snappy) {
                            conditions.append(
                                ThesisCondition(statement: "", measure: "", test: "", status: .passing,
                                                reading: "—", evidence: "", userDefined: true)
                            )
                            revealed = conditions.count
                        }
                    } label: {
                        HStack(spacing: 7) {
                            Image(systemName: "plus").font(.system(size: 11, weight: .semibold))
                            Text("Add a condition").font(Type.callout)
                        }
                        .foregroundStyle(Palette.accent)
                    }
                    .padding(.top, 16)
                }
                .padding(.bottom, 28)
            }
            .scrollIndicators(.hidden)

            PrimaryAction(title: "This is my thesis", action: onConfirm)
                .disabled(conditions.isEmpty)
                .opacity(conditions.isEmpty ? 0.28 : 1)
                .padding(.bottom, 12)
                .padding(.top, 8)
                .background(
                    LinearGradient(
                        colors: [Palette.canvas.opacity(0), Palette.canvas],
                        startPoint: .top, endPoint: .bottom
                    )
                    .frame(height: 130)
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    .allowsHitTesting(false)
                )
        }
        .transition(.opacity.combined(with: .offset(y: 10)))
    }
}
