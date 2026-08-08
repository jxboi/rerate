import SwiftUI

struct ThesisView: View {
    @Environment(Store.self) private var store
    let holdingID: UUID
    @State private var appeared = false
    @State private var editing: ThesisCondition?
    @State private var addingNew = false

    private var h: Holding { store.holding(holdingID) ?? SeedDBS.holding }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                originalWords
                conditions
                verdict
                addCondition
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 48)
        }
        .background(Palette.canvas)
        .scrollIndicators(.hidden)
        .navigationTitle("Thesis")
        .navigationBarTitleDisplayMode(.inline)
        .task { withAnimation(Motion.gentle) { appeared = true } }
        .sheet(item: $editing) { condition in
            ConditionEditor(holdingID: holdingID, condition: condition, isNew: false)
        }
        .sheet(isPresented: $addingNew) {
            ConditionEditor(
                holdingID: holdingID,
                condition: ThesisCondition(
                    statement: "", measure: "", test: "", status: .passing,
                    reading: "—", evidence: "", userDefined: true
                ),
                isNew: true
            )
        }
    }

    // MARK: What they wrote

    private var originalWords: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Why you bought \(h.shortName)")
                .sectionLabelStyle()
                .padding(.top, 8)

            Text("“\(h.originalReasoning)”")
                .font(Type.quote)
                .foregroundStyle(Palette.ink)
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)

            Text(Fmt.shortDate.string(from: h.purchaseDate))
                .font(Type.micro)
                .foregroundStyle(Palette.inkTertiary)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Palette.surfaceSunken)
        )
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 8)
    }

    // MARK: Conditions

    private var conditions: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionLabel("What has to stay true", trailing: "Tap to edit")
                .padding(.top, 38)
                .padding(.bottom, 6)

            ForEach(Array(h.conditions.enumerated()), id: \.element.id) { i, condition in
                if i > 0 { Hairline(inset: 34) }
                ConditionRow(condition: condition, index: i, appeared: appeared) {
                    Haptic.tap()
                    editing = condition
                }
            }
        }
    }

    // MARK: Verdict

    private var verdict: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text("\(h.conditionsIntact) of \(h.conditionsTotal)")
                    .font(Type.figure(34))
                    .foregroundStyle(Palette.ink)
                    .contentTransition(.numericText())
                Text("conditions still hold")
                    .font(Type.callout)
                    .foregroundStyle(Palette.inkSecondary)
                Spacer(minLength: 0)
            }

            Text(verdictNarrative)
                .font(Type.quote)
                .foregroundStyle(Palette.ink)
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)

            TonePill(text: h.thesisState.rawValue, tone: h.thesisState.tone)
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
        .padding(.top, 32)
    }

    /// Written from the shape of the failures rather than from a template, so
    /// the summary says something true about *this* position.
    private var verdictNarrative: String {
        let failing = h.conditions.filter { $0.status == .failing }
        let warning = h.conditions.filter { $0.status == .warning }
        let businessFailures = failing.filter { !isValuation($0) }
        let valuationFailing = failing.contains(where: isValuation)

        if failing.isEmpty && warning.isEmpty {
            return "Everything you wrote down when you bought this is still true. Nothing here needs a decision."
        }
        if valuationFailing && businessFailures.isEmpty {
            let extra = warning.isEmpty ? "" : " \(warning[0].measure) is under pressure, but the operating business is intact."
            return "The company remains fundamentally strong. The main change since your purchase is valuation rather than business deterioration.\(extra)"
        }
        if !businessFailures.isEmpty && !valuationFailing {
            return "The change here is in the business, not the price. \(businessFailures[0].statement.lowercased().prefix(1).uppercased() + businessFailures[0].statement.lowercased().dropFirst()) is no longer true — and that is the kind of change that does not fix itself by waiting."
        }
        if !businessFailures.isEmpty && valuationFailing {
            return "Both the business and the valuation have moved against the case you wrote down. This is the combination worth taking seriously."
        }
        return "Nothing has broken outright, but \(warning.count) \(warning.count == 1 ? "condition is" : "conditions are") under pressure. Worth watching rather than acting on."
    }

    private func isValuation(_ c: ThesisCondition) -> Bool {
        let s = (c.statement + c.measure).lowercased()
        return s.contains("valuation") || s.contains("price to") || s.contains("book") || s.contains("nav")
    }

    // MARK: Add

    private var addCondition: some View {
        Button {
            Haptic.tap()
            addingNew = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus").font(.system(size: 12, weight: .semibold))
                Text("Add a condition of your own").font(Type.bodyMedium)
            }
            .foregroundStyle(Palette.inkSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Palette.surfaceSunken)
            )
        }
        .buttonStyle(.pressable(scale: 0.98))
        .padding(.top, 22)
    }
}

// MARK: - Row

struct ConditionRow: View {
    let condition: ThesisCondition
    let index: Int
    let appeared: Bool
    let onTap: () -> Void
    @State private var badgeIn = false

    var body: some View {
        Unfold {
            HStack(alignment: .top, spacing: 14) {
                StatusBadge(status: condition.status)
                    .scaleEffect(badgeIn ? 1 : 0.5)
                    .opacity(badgeIn ? 1 : 0)

                VStack(alignment: .leading, spacing: 5) {
                    Text(condition.statement)
                        .font(Type.body)
                        .foregroundStyle(Palette.ink)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack(spacing: 6) {
                        Text(condition.measure)
                            .font(Type.caption)
                            .foregroundStyle(Palette.inkTertiary)
                        Text("·").foregroundStyle(Palette.inkQuaternary)
                        Text(condition.reading)
                            .font(Type.mono(12.5, .medium))
                            .foregroundStyle(condition.status.tone.color)
                        if let prev = condition.previousReading, prev != condition.reading {
                            Text("was \(prev)")
                                .font(Type.mono(12))
                                .foregroundStyle(Palette.inkQuaternary)
                        }
                        if condition.userDefined {
                            Text("yours")
                                .font(Type.micro)
                                .foregroundStyle(Palette.accent)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 1.5)
                                .background(Capsule().fill(Palette.accentSoft))
                        }
                    }
                }
            }
            .padding(.vertical, 16)
        } content: {
            VStack(alignment: .leading, spacing: 14) {
                Text(condition.evidence)
                    .font(Type.callout)
                    .foregroundStyle(Palette.inkSecondary)
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 10) {
                    Text("Test: \(condition.test)")
                        .font(Type.micro)
                        .foregroundStyle(Palette.inkTertiary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Palette.surfaceSunken))

                    Button(action: onTap) {
                        Text("Edit")
                            .font(Type.micro)
                            .foregroundStyle(Palette.accent)
                    }
                    Spacer()
                }
            }
            .padding(.leading, 34)
            .padding(.bottom, 16)
        }
        .task {
            try? await Task.sleep(nanoseconds: UInt64(140_000_000 + index * 70_000_000))
            withAnimation(.spring(response: 0.42, dampingFraction: 0.68)) { badgeIn = true }
        }
    }
}

struct StatusBadge: View {
    let status: ConditionStatus

    var body: some View {
        ZStack {
            Circle()
                .fill(status.tone.soft)
                .frame(width: 22, height: 22)
            Image(systemName: status.glyph)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(status.tone.color)
        }
    }
}

// MARK: - Editor

struct ConditionEditor: View {
    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss
    let holdingID: UUID
    @State var condition: ThesisCondition
    let isNew: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 26) {
                    field("What has to stay true", text: $condition.statement, placeholder: "Return on equity stays above 15%")
                    field("Measured by", text: $condition.measure, placeholder: "Return on equity")
                    field("The test", text: $condition.test, placeholder: "above 15%")

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Current standing").sectionLabelStyle()
                        HStack(spacing: 8) {
                            ForEach([ConditionStatus.passing, .warning, .failing], id: \.rawValue) { s in
                                Button {
                                    Haptic.detent()
                                    withAnimation(Motion.snappy) { condition.status = s }
                                } label: {
                                    Text(s.rawValue)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundStyle(condition.status == s ? Palette.canvas : Palette.inkSecondary)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(
                                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                .fill(condition.status == s ? s.tone.color : Palette.surfaceSunken)
                                        )
                                }
                                .buttonStyle(.pressable(scale: 0.96, haptic: false))
                            }
                        }
                    }

                    if !isNew {
                        Button(role: .destructive) {
                            Haptic.firm()
                            store.removeCondition(holdingID: holdingID, conditionID: condition.id)
                            dismiss()
                        } label: {
                            Text("Remove this condition")
                                .font(Type.bodyMedium)
                                .foregroundStyle(Palette.breach)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(Palette.breachSoft)
                                )
                        }
                        .buttonStyle(.pressable(scale: 0.98, haptic: false))
                    }
                }
                .padding(20)
            }
            .background(Palette.canvas)
            .navigationTitle(isNew ? "New condition" : "Edit condition")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Palette.inkSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Haptic.settled()
                        var c = condition
                        if c.reading.isEmpty { c.reading = "—" }
                        if isNew {
                            c.userDefined = true
                            if c.evidence.isEmpty {
                                c.evidence = "A condition you defined. Rerate will tell you when it changes."
                            }
                            store.addCondition(holdingID: holdingID, condition: c)
                        } else {
                            store.updateCondition(holdingID: holdingID, condition: c)
                        }
                        dismiss()
                    }
                    .disabled(condition.statement.trimmingCharacters(in: .whitespaces).isEmpty)
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func field(_ label: String, text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(label).sectionLabelStyle()
            TextField(placeholder, text: text, axis: .vertical)
                .font(Type.body)
                .foregroundStyle(Palette.ink)
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Palette.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Palette.hairline, lineWidth: 1)
                )
        }
    }
}
