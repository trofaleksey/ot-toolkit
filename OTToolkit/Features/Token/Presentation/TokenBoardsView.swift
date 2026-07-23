import SwiftUI

private enum TokenRewardSymbolOption: CaseIterable, Identifiable, Sendable {
    case star
    case play
    case read
    case music
    case snack
    case outside

    var id: String { systemName }

    var systemName: String {
        switch self {
        case .star: "star"
        case .play: "puzzlepiece"
        case .read: "book.closed"
        case .music: "music.note"
        case .snack: "carrot"
        case .outside: "figure.play"
        }
    }

    var titleKey: LocalizedStringKey {
        switch self {
        case .star: "tokenBoard.symbol.star"
        case .play: "tokenBoard.symbol.play"
        case .read: "tokenBoard.symbol.read"
        case .music: "tokenBoard.symbol.music"
        case .snack: "tokenBoard.symbol.snack"
        case .outside: "tokenBoard.symbol.outside"
        }
    }
}

private enum TokenBoardEditorRoute: Identifiable {
    case create
    case edit(TokenBoardTemplateSnapshot)

    var id: String {
        switch self {
        case .create:
            "create"
        case let .edit(template):
            template.id.uuidString
        }
    }
}

struct TokenBoardsView: View {
    @State private var editorRoute: TokenBoardEditorRoute?

    let controller: TokenBoardController
    let sessionController: TokenBoardSessionController
    let onPresentChildFacing: (UUID) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: OTSpacing.lg) {
                guidance

                if controller.templates.isEmpty {
                    emptyState
                } else {
                    LazyVStack(spacing: OTSpacing.md) {
                        ForEach(controller.templates) { template in
                            templateRow(template)
                        }
                    }
                }
            }
            .frame(maxWidth: 720, alignment: .leading)
            .padding(OTSpacing.xl)
            .frame(maxWidth: .infinity)
        }
        .background(OTColor.background.ignoresSafeArea())
        .navigationTitle("tokenBoard.title")
        .accessibilityIdentifier("tokenBoard.destination")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    editorRoute = .create
                } label: {
                    Label("tokenBoard.action.create", systemImage: "plus")
                }
                .accessibilityIdentifier("tokenBoard.action.create")
            }
        }
        .sheet(item: $editorRoute) { route in
            TokenBoardEditorView(controller: controller, route: route)
        }
        .alert(failureTitle, isPresented: failureBinding) {
            if controller.failure == .load {
                Button("tokenBoard.error.retry") {
                    controller.reload()
                }
            }
            Button("tokenBoard.error.dismiss", role: .cancel) {
                controller.dismissFailure()
            }
        } message: {
            Text(failureMessage)
        }
    }

    private var guidance: some View {
        VStack(alignment: .leading, spacing: OTSpacing.xs) {
            Text("tokenBoard.guidance.title")
                .font(OTTypography.sectionHeading)
                .foregroundStyle(OTColor.primaryText)
                .accessibilityAddTraits(.isHeader)

            Text("tokenBoard.guidance.message")
                .font(OTTypography.body)
                .foregroundStyle(OTColor.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(OTSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(OTColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: OTRadius.card, style: .continuous))
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: OTSpacing.md) {
            Image(systemName: "circle.grid.2x2")
                .font(OTTypography.screenTitle)
                .foregroundStyle(OTColor.accent)
                .accessibilityHidden(true)

            Text("tokenBoard.empty.title")
                .font(OTTypography.sectionHeading)
                .foregroundStyle(OTColor.primaryText)
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier("tokenBoard.empty.title")

            Text("tokenBoard.empty.message")
                .font(OTTypography.body)
                .foregroundStyle(OTColor.secondaryText)
                .fixedSize(horizontal: false, vertical: true)

            Button("tokenBoard.action.create") {
                editorRoute = .create
            }
            .buttonStyle(.borderedProminent)
            .tint(OTColor.accent)
            .controlSize(.large)
            .otMinimumInteractiveSize()
            .accessibilityIdentifier("tokenBoard.empty.create")
        }
        .padding(OTSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(OTColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: OTRadius.card, style: .continuous))
    }

    private func templateRow(_ template: TokenBoardTemplateSnapshot) -> some View {
        HStack(alignment: .top, spacing: OTSpacing.sm) {
            NavigationLink {
                TokenBoardUseView(
                    controller: controller,
                    sessionController: sessionController,
                    templateID: template.id,
                    onPresentChildFacing: onPresentChildFacing
                )
            } label: {
                VStack(alignment: .leading, spacing: OTSpacing.sm) {
                    Text(template.name)
                        .font(OTTypography.sectionHeading)
                        .foregroundStyle(OTColor.primaryText)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: OTSpacing.sm) {
                        Image(systemName: template.reward.systemSymbolName)
                            .frame(width: 28, height: 28)
                            .foregroundStyle(OTColor.accent)
                            .accessibilityHidden(true)

                        Text(TokenBoardStrings.goalSummary(goal: template.goal))
                            .font(OTTypography.controlLabel)
                            .foregroundStyle(OTColor.primaryText)

                        Text(template.reward.label)
                            .font(OTTypography.body)
                            .foregroundStyle(OTColor.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .accessibilityElement(children: .combine)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("tokenBoard.template.\(template.id.uuidString)")

            Button {
                editorRoute = .edit(template)
            } label: {
                Label("tokenBoard.action.edit", systemImage: "pencil")
                    .labelStyle(.iconOnly)
            }
            .buttonStyle(.bordered)
            .otMinimumInteractiveSize()
            .accessibilityLabel("tokenBoard.action.edit")
            .accessibilityIdentifier("tokenBoard.template.edit.\(template.id.uuidString)")
        }
        .padding(OTSpacing.md)
        .background(OTColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: OTRadius.card, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: OTRadius.card, style: .continuous)
                .stroke(OTColor.separator, lineWidth: 1)
                .accessibilityHidden(true)
        }
    }

    private var failureBinding: Binding<Bool> {
        Binding(
            get: { controller.failure == .load || controller.failure == .delete },
            set: { isPresented in
                if !isPresented {
                    controller.dismissFailure()
                }
            }
        )
    }

    private var failureTitle: LocalizedStringKey {
        switch controller.failure {
        case .load:
            "tokenBoard.error.load.title"
        case .create:
            "tokenBoard.error.create.title"
        case .update:
            "tokenBoard.error.update.title"
        case .delete:
            "tokenBoard.error.delete.title"
        case nil:
            "tokenBoard.error.title"
        }
    }

    private var failureMessage: LocalizedStringKey {
        switch controller.failure {
        case .load:
            "tokenBoard.error.load.message"
        case .create, .update, .delete, nil:
            "tokenBoard.error.save.message"
        }
    }
}

enum TokenBoardStrings {
    static func progress(filled: Int, goal: Int) -> String {
        String(
            format: String(localized: "tokenBoard.progress"),
            locale: .current,
            filled,
            goal
        )
    }

    static func goalSummary(goal: TokenBoardGoal) -> String {
        String(
            format: String(localized: "tokenBoard.goal.summary"),
            locale: .current,
            goal.rawValue
        )
    }
}

private struct TokenBoardEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var goal: TokenBoardGoal
    @State private var rewardLabel: String
    @State private var rewardSymbolName: String

    let controller: TokenBoardController
    let route: TokenBoardEditorRoute

    init(controller: TokenBoardController, route: TokenBoardEditorRoute) {
        self.controller = controller
        self.route = route

        let template: TokenBoardTemplateSnapshot?
        switch route {
        case .create:
            template = nil
        case let .edit(existing):
            template = existing
        }

        _name = State(initialValue: template?.name ?? "")
        _goal = State(initialValue: template?.goal ?? .five)
        _rewardLabel = State(initialValue: template?.reward.label ?? "")
        _rewardSymbolName = State(
            initialValue: template?.reward.systemSymbolName
                ?? TokenRewardSymbolOption.star.systemName
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: OTSpacing.lg) {
                    Text("tokenBoard.editor.guidance")
                        .font(OTTypography.body)
                        .foregroundStyle(OTColor.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)

                    VStack(alignment: .leading, spacing: OTSpacing.sm) {
                        Text("tokenBoard.editor.name")
                            .font(OTTypography.sectionHeading)
                            .foregroundStyle(OTColor.primaryText)
                        TextField("tokenBoard.editor.name.placeholder", text: $name)
                            .textFieldStyle(.roundedBorder)
                            .accessibilityIdentifier("tokenBoard.editor.name")
                    }

                    goalEditor
                    rewardEditor

                    if !hasRequiredContent {
                        Label(
                            "tokenBoard.editor.validation",
                            systemImage: "exclamationmark.circle"
                        )
                        .font(OTTypography.body)
                        .foregroundStyle(OTColor.warning)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("tokenBoard.editor.validation")
                    }
                }
                .frame(maxWidth: 640, alignment: .leading)
                .padding(OTSpacing.xl)
                .frame(maxWidth: .infinity)
            }
            .background(OTColor.background.ignoresSafeArea())
            .navigationTitle(editorTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("tokenBoard.action.cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("tokenBoard.action.save") {
                        save()
                    }
                    .disabled(!hasRequiredContent)
                    .accessibilityIdentifier("tokenBoard.editor.save")
                }
            }
        }
        .interactiveDismissDisabled(hasEnteredContent)
        .accessibilityIdentifier("tokenBoard.editor")
        .alert(editorFailureTitle, isPresented: editorFailureBinding) {
            Button("tokenBoard.error.dismiss", role: .cancel) {
                controller.dismissFailure()
            }
        } message: {
            Text("tokenBoard.error.save.message")
        }
    }

    private var goalEditor: some View {
        VStack(alignment: .leading, spacing: OTSpacing.sm) {
            Text("tokenBoard.editor.goal")
                .font(OTTypography.sectionHeading)
                .foregroundStyle(OTColor.primaryText)
                .accessibilityAddTraits(.isHeader)

            Picker("tokenBoard.editor.goal", selection: $goal) {
                ForEach(TokenBoardGoal.allCases, id: \.self) { option in
                    Text(TokenBoardStrings.goalSummary(goal: option))
                        .tag(option)
                }
            }
            .pickerStyle(.segmented)
            .otMinimumInteractiveSize()
            .accessibilityIdentifier("tokenBoard.editor.goal")
        }
        .padding(OTSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(OTColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: OTRadius.card, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: OTRadius.card, style: .continuous)
                .stroke(OTColor.separator, lineWidth: 1)
                .accessibilityHidden(true)
        }
    }

    private var rewardEditor: some View {
        VStack(alignment: .leading, spacing: OTSpacing.sm) {
            Text("tokenBoard.editor.reward")
                .font(OTTypography.sectionHeading)
                .foregroundStyle(OTColor.primaryText)
                .accessibilityAddTraits(.isHeader)

            TextField("tokenBoard.editor.reward.placeholder", text: $rewardLabel)
                .textFieldStyle(.roundedBorder)
                .accessibilityIdentifier("tokenBoard.editor.reward.label")

            Picker("tokenBoard.editor.reward.symbol", selection: $rewardSymbolName) {
                ForEach(TokenRewardSymbolOption.allCases) { option in
                    Label(option.titleKey, systemImage: option.systemName)
                        .tag(option.systemName)
                }
            }
            .pickerStyle(.menu)
            .otMinimumInteractiveSize()
            .accessibilityIdentifier("tokenBoard.editor.reward.symbol")
        }
        .padding(OTSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(OTColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: OTRadius.card, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: OTRadius.card, style: .continuous)
                .stroke(OTColor.separator, lineWidth: 1)
                .accessibilityHidden(true)
        }
    }

    private var editorTitle: LocalizedStringKey {
        switch route {
        case .create:
            "tokenBoard.editor.create.title"
        case .edit:
            "tokenBoard.editor.edit.title"
        }
    }

    private var hasRequiredContent: Bool {
        !trimmed(name).isEmpty && !trimmed(rewardLabel).isEmpty
    }

    private var hasEnteredContent: Bool {
        !name.isEmpty || !rewardLabel.isEmpty
    }

    private var editorFailureBinding: Binding<Bool> {
        Binding(
            get: { controller.failure == .create || controller.failure == .update },
            set: { isPresented in
                if !isPresented {
                    controller.dismissFailure()
                }
            }
        )
    }

    private var editorFailureTitle: LocalizedStringKey {
        switch controller.failure {
        case .create:
            "tokenBoard.error.create.title"
        case .update:
            "tokenBoard.error.update.title"
        case .load, .delete, nil:
            "tokenBoard.error.title"
        }
    }

    private func save() {
        let draft = TokenBoardTemplateDraft(
            name: name,
            goal: goal,
            reward: TokenBoardReward(
                label: rewardLabel,
                systemSymbolName: rewardSymbolName
            )
        )

        let didSave: Bool
        switch route {
        case .create:
            didSave = controller.create(draft)
        case let .edit(template):
            didSave = controller.update(id: template.id, with: draft)
        }

        if didSave {
            dismiss()
        }
    }

    private func trimmed(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private struct TokenBoardUseView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var didStartSession = false
    @State private var editorRoute: TokenBoardEditorRoute?
    @State private var isConfirmingDelete = false

    let controller: TokenBoardController
    let sessionController: TokenBoardSessionController
    let templateID: UUID
    let onPresentChildFacing: (UUID) -> Void

    var body: some View {
        Group {
            if let template = controller.template(id: templateID) {
                content(template)
            } else {
                unavailableState
            }
        }
        .background(OTColor.background.ignoresSafeArea())
        .navigationTitle(controller.template(id: templateID)?.name ?? "")
        .accessibilityIdentifier("tokenBoard.template.use")
        .onAppear {
            guard !didStartSession, let template = controller.template(id: templateID) else {
                return
            }
            sessionController.start(template: template)
            didStartSession = true
        }
        .toolbar {
            if let template = controller.template(id: templateID) {
                ToolbarItemGroup(placement: .primaryAction) {
                    Button {
                        editorRoute = .edit(template)
                    } label: {
                        Label("tokenBoard.action.edit", systemImage: "pencil")
                    }
                    .accessibilityIdentifier("tokenBoard.template.use.edit")

                    Button(role: .destructive) {
                        isConfirmingDelete = true
                    } label: {
                        Label("tokenBoard.action.delete", systemImage: "trash")
                    }
                    .accessibilityIdentifier("tokenBoard.template.use.delete")
                }
            }
        }
        .sheet(item: $editorRoute) { route in
            TokenBoardEditorView(controller: controller, route: route)
        }
        .alert("tokenBoard.delete.title", isPresented: $isConfirmingDelete) {
            Button("tokenBoard.delete.cancel", role: .cancel) {}
            Button("tokenBoard.delete.confirm", role: .destructive) {
                if controller.delete(id: templateID) {
                    sessionController.discardSession(templateID: templateID)
                    dismiss()
                }
            }
        } message: {
            Text("tokenBoard.delete.message")
        }
    }

    private func content(_ template: TokenBoardTemplateSnapshot) -> some View {
        ScrollView {
            VStack(spacing: OTSpacing.lg) {
                Button {
                    onPresentChildFacing(templateID)
                } label: {
                    Label("tokenBoard.action.childFacing", systemImage: "rectangle.inset.filled")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(OTColor.accent)
                .controlSize(.large)
                .otMinimumInteractiveSize()
                .accessibilityIdentifier("tokenBoard.action.childFacing")

                TokenBoardProgressView(
                    template: template,
                    sessionController: sessionController,
                    context: .therapist
                )

                Toggle(isOn: hapticBinding) {
                    Text("tokenBoard.feedback.haptic")
                        .font(OTTypography.controlLabel)
                        .foregroundStyle(OTColor.primaryText)
                }
                .otMinimumInteractiveSize()
                .accessibilityIdentifier("tokenBoard.feedback.haptic")
            }
            .frame(maxWidth: 720)
            .padding(OTSpacing.xl)
            .frame(maxWidth: .infinity)
        }
    }

    private var hapticBinding: Binding<Bool> {
        Binding(
            get: { sessionController.isCompletionHapticEnabled },
            set: { sessionController.setCompletionHapticEnabled($0) }
        )
    }

    private var unavailableState: some View {
        VStack(spacing: OTSpacing.md) {
            Text("tokenBoard.unavailable.title")
                .font(OTTypography.sectionHeading)
                .foregroundStyle(OTColor.primaryText)
            Text("tokenBoard.unavailable.message")
                .font(OTTypography.body)
                .foregroundStyle(OTColor.secondaryText)
                .multilineTextAlignment(.center)
            Button("tokenBoard.unavailable.back") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(OTSpacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct TokenBoardChildView: View {
    let controller: TokenBoardController
    let sessionController: TokenBoardSessionController
    let templateID: UUID

    var body: some View {
        Group {
            if let template = controller.template(id: templateID) {
                VStack(spacing: OTSpacing.lg) {
                    Text(template.name)
                        .font(OTTypography.screenTitle)
                        .foregroundStyle(OTColor.primaryText)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityIdentifier("tokenBoard.child.content")

                    TokenBoardProgressView(
                        template: template,
                        sessionController: sessionController,
                        context: .child
                    )
                }
                .frame(maxWidth: 720)
            } else {
                VStack(spacing: OTSpacing.md) {
                    Text("tokenBoard.unavailable.title")
                        .font(OTTypography.sectionHeading)
                        .foregroundStyle(OTColor.primaryText)
                        .accessibilityAddTraits(.isHeader)
                    Text("tokenBoard.unavailable.message")
                        .font(OTTypography.body)
                        .foregroundStyle(OTColor.secondaryText)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier("tokenBoard.child.unavailable")
            }
        }
    }
}

private enum TokenBoardContext {
    case child
    case therapist

    var boardIdentifier: String {
        switch self {
        case .child: "tokenBoard.child.board"
        case .therapist: "tokenBoard.board"
        }
    }

    var statusIdentifier: String {
        switch self {
        case .child: "tokenBoard.child.status"
        case .therapist: "tokenBoard.status"
        }
    }

    var removeIdentifier: String {
        switch self {
        case .child: "tokenBoard.child.action.remove"
        case .therapist: "tokenBoard.action.remove"
        }
    }

    var resetIdentifier: String {
        switch self {
        case .child: "tokenBoard.child.action.reset"
        case .therapist: "tokenBoard.action.reset"
        }
    }
}

/// Renders the token grid. Filled and empty tokens differ by symbol *shape*
/// (solid vs outlined) and are always accompanied by the count text and an
/// explicit completion label, so state never depends on color alone.
private struct TokenBoardProgressView: View {
    @Environment(\.otAccessibilityPreferences) private var accessibilityPreferences

    let template: TokenBoardTemplateSnapshot
    let sessionController: TokenBoardSessionController
    let context: TokenBoardContext

    var body: some View {
        VStack(spacing: OTSpacing.lg) {
            rewardSummary
            tokenBoard
            statusLabel
            adultControls
        }
    }

    private var snapshot: TokenBoardSnapshot {
        sessionController.snapshot(for: template)
    }

    private var rewardSummary: some View {
        HStack(spacing: OTSpacing.sm) {
            Image(systemName: template.reward.systemSymbolName)
                .font(OTTypography.sectionHeading)
                .foregroundStyle(OTColor.accent)
                .accessibilityHidden(true)

            Text("tokenBoard.reward.workingFor")
                .font(OTTypography.controlLabel)
                .foregroundStyle(OTColor.secondaryText)

            Text(template.reward.label)
                .font(OTTypography.sectionHeading)
                .foregroundStyle(OTColor.primaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(OTSpacing.md)
        .frame(maxWidth: .infinity)
        .background(OTColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: OTRadius.card, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("tokenBoard.reward")
    }

    private var tokenBoard: some View {
        Button {
            sessionController.addToken(for: template)
        } label: {
            tokenGrid
                .padding(OTSpacing.lg)
                .frame(maxWidth: .infinity)
                .background(OTColor.elevatedSurface)
                .clipShape(RoundedRectangle(cornerRadius: OTRadius.card, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: OTRadius.card, style: .continuous)
                        .stroke(
                            OTColor.separator,
                            lineWidth: accessibilityPreferences.boundaryLineWidth
                        )
                        .accessibilityHidden(true)
                }
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(snapshot.isComplete)
        .otMinimumInteractiveSize()
        .accessibilityLabel("tokenBoard.action.addToken")
        .accessibilityValue(
            Text(
                TokenBoardStrings.progress(
                    filled: snapshot.filledCount,
                    goal: snapshot.goal.rawValue
                ))
        )
        .accessibilityIdentifier(context.boardIdentifier)
    }

    private var tokenGrid: some View {
        let columns = [
            GridItem(.adaptive(minimum: 56, maximum: 96), spacing: OTSpacing.md)
        ]

        return LazyVGrid(columns: columns, spacing: OTSpacing.md) {
            ForEach(0..<snapshot.goal.rawValue, id: \.self) { index in
                Image(systemName: index < snapshot.filledCount ? "star.fill" : "star")
                    .font(OTTypography.childFacingValue)
                    .foregroundStyle(
                        index < snapshot.filledCount ? OTColor.accent : OTColor.secondaryText
                    )
                    .frame(minWidth: 44, minHeight: 44)
                    .accessibilityHidden(true)
            }
        }
    }

    private var statusLabel: some View {
        VStack(spacing: OTSpacing.xs) {
            Text(
                TokenBoardStrings.progress(
                    filled: snapshot.filledCount,
                    goal: snapshot.goal.rawValue
                )
            )
            .font(OTTypography.childFacingValue)
            .foregroundStyle(OTColor.primaryText)
            .monospacedDigit()

            if snapshot.isComplete {
                Label("tokenBoard.status.complete", systemImage: "checkmark.circle.fill")
                    .font(OTTypography.sectionHeading)
                    .foregroundStyle(OTColor.primaryText)
                    .padding(OTSpacing.md)
                    .frame(maxWidth: .infinity)
                    .background(OTColor.selection)
                    .clipShape(
                        RoundedRectangle(cornerRadius: OTRadius.card, style: .continuous)
                    )
                    .accessibilityIdentifier("tokenBoard.status.complete")
            } else {
                Text("tokenBoard.status.inProgress")
                    .font(OTTypography.body)
                    .foregroundStyle(OTColor.secondaryText)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(context.statusIdentifier)
    }

    private var adultControls: some View {
        HStack(spacing: OTSpacing.md) {
            Button {
                sessionController.removeToken(for: template)
            } label: {
                Label("tokenBoard.action.remove", systemImage: "arrow.uturn.backward")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .disabled(snapshot.filledCount == 0)
            .otMinimumInteractiveSize()
            .accessibilityIdentifier(context.removeIdentifier)

            Button {
                sessionController.reset(template: template)
            } label: {
                Label("tokenBoard.action.reset", systemImage: "arrow.counterclockwise")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .disabled(snapshot.filledCount == 0)
            .otMinimumInteractiveSize()
            .accessibilityIdentifier(context.resetIdentifier)
        }
    }
}
