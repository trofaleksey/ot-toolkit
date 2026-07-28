import SwiftUI

enum ChoiceSymbolOption: CaseIterable, Identifiable, Sendable {
    case play
    case read
    case create
    case move
    case music
    case snack

    var id: String { systemName }

    var systemName: String {
        switch self {
        case .play: "puzzlepiece"
        case .read: "book.closed"
        case .create: "paintbrush"
        case .move: "figure.walk"
        case .music: "music.note"
        case .snack: "carrot"
        }
    }

    var titleKey: LocalizedStringKey {
        switch self {
        case .play: "choice.symbol.play"
        case .read: "choice.symbol.read"
        case .create: "choice.symbol.create"
        case .move: "choice.symbol.move"
        case .music: "choice.symbol.music"
        case .snack: "choice.symbol.snack"
        }
    }
}

private enum ChoiceEditorRoute: Identifiable {
    case create
    case edit(ChoiceBoardSnapshot)

    var id: String {
        switch self {
        case .create: "create"
        case let .edit(board): board.id.uuidString
        }
    }
}

struct ChoiceBoardsView: View {
    @State private var editorRoute: ChoiceEditorRoute?

    let controller: ChoiceBoardController
    let sessionController: ChoiceBoardSessionController
    let onPresentChildFacing: (UUID) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: OTSpacing.lg) {
                guidance

                if controller.boards.isEmpty {
                    emptyState
                } else {
                    LazyVStack(spacing: OTSpacing.md) {
                        ForEach(controller.boards) { board in
                            boardRow(board)
                        }
                    }
                }
            }
            .frame(maxWidth: 720, alignment: .leading)
            .padding(OTSpacing.xl)
            .frame(maxWidth: .infinity)
        }
        .background(OTColor.background.ignoresSafeArea())
        .navigationTitle("choice.title")
        .accessibilityIdentifier("choice.destination")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    editorRoute = .create
                } label: {
                    Label("choice.action.create", systemImage: "plus")
                }
                .accessibilityIdentifier("choice.action.create")
            }
        }
        .sheet(item: $editorRoute) { route in
            ChoiceBoardEditorView(controller: controller, route: route)
        }
        .alert(failureTitle, isPresented: failureBinding) {
            if controller.failure == .load {
                Button("choice.error.retry") {
                    controller.reload()
                }
            }
            Button("choice.error.dismiss", role: .cancel) {
                controller.dismissFailure()
            }
        } message: {
            Text("choice.error.message")
        }
    }

    private var guidance: some View {
        VStack(alignment: .leading, spacing: OTSpacing.xs) {
            Text("choice.guidance.title")
                .font(OTTypography.sectionHeading)
                .foregroundStyle(OTColor.primaryText)
                .accessibilityAddTraits(.isHeader)

            Text("choice.guidance.message")
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
            Image(systemName: "square.grid.2x2")
                .font(OTTypography.screenTitle)
                .foregroundStyle(OTColor.accent)
                .accessibilityHidden(true)

            Text("choice.empty.title")
                .font(OTTypography.sectionHeading)
                .foregroundStyle(OTColor.primaryText)
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier("choice.empty.title")

            Text("choice.empty.message")
                .font(OTTypography.body)
                .foregroundStyle(OTColor.secondaryText)
                .fixedSize(horizontal: false, vertical: true)

            Button("choice.action.create") {
                editorRoute = .create
            }
            .buttonStyle(.borderedProminent)
            .tint(OTColor.accent)
            .controlSize(.large)
            .otMinimumInteractiveSize()
            .accessibilityIdentifier("choice.empty.create")
        }
        .padding(OTSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(OTColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: OTRadius.card, style: .continuous))
    }

    private func boardRow(_ board: ChoiceBoardSnapshot) -> some View {
        HStack(alignment: .top, spacing: OTSpacing.sm) {
            NavigationLink {
                ChoiceBoardUseView(
                    controller: controller,
                    sessionController: sessionController,
                    boardID: board.id,
                    onPresentChildFacing: onPresentChildFacing
                )
            } label: {
                VStack(alignment: .leading, spacing: OTSpacing.xs) {
                    Text(board.name)
                        .font(OTTypography.sectionHeading)
                        .foregroundStyle(OTColor.primaryText)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("choice.summary.count \(board.options.count)")
                        .font(OTTypography.body)
                        .foregroundStyle(OTColor.secondaryText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("choice.board.\(board.id.uuidString)")

            Button {
                editorRoute = .edit(board)
            } label: {
                Label("choice.action.edit", systemImage: "pencil")
                    .labelStyle(.iconOnly)
            }
            .buttonStyle(.bordered)
            .otMinimumInteractiveSize()
            .accessibilityLabel("choice.action.edit")
            .accessibilityIdentifier("choice.board.edit.\(board.id.uuidString)")
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
        case .load: "choice.error.load.title"
        case .create: "choice.error.create.title"
        case .update: "choice.error.update.title"
        case .duplicate: "choice.error.duplicate.title"
        case .delete: "choice.error.delete.title"
        case nil: "choice.error.title"
        }
    }
}

// MARK: - Editor

private struct ChoiceOptionDraftState: Identifiable, Equatable {
    let id = UUID()
    var label: String
    var systemSymbolName: String
}

private struct ChoiceBoardEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var options: [ChoiceOptionDraftState]

    let controller: ChoiceBoardController
    let route: ChoiceEditorRoute

    init(controller: ChoiceBoardController, route: ChoiceEditorRoute) {
        self.controller = controller
        self.route = route

        switch route {
        case .create:
            _name = State(initialValue: "")
            _options = State(
                initialValue: [
                    ChoiceOptionDraftState(
                        label: "",
                        systemSymbolName: ChoiceSymbolOption.play.systemName
                    ),
                    ChoiceOptionDraftState(
                        label: "",
                        systemSymbolName: ChoiceSymbolOption.read.systemName
                    ),
                ]
            )
        case let .edit(board):
            _name = State(initialValue: board.name)
            _options = State(
                initialValue: board.options.map {
                    ChoiceOptionDraftState(
                        label: $0.label,
                        systemSymbolName: $0.systemSymbolName
                    )
                }
            )
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: OTSpacing.lg) {
                    Text("choice.editor.guidance")
                        .font(OTTypography.body)
                        .foregroundStyle(OTColor.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)

                    VStack(alignment: .leading, spacing: OTSpacing.sm) {
                        Text("choice.editor.name")
                            .font(OTTypography.sectionHeading)
                            .foregroundStyle(OTColor.primaryText)
                        TextField("choice.editor.name.placeholder", text: $name)
                            .textFieldStyle(.roundedBorder)
                            .accessibilityIdentifier("choice.editor.name")
                    }

                    ForEach(Array(options.enumerated()), id: \.element.id) { index, option in
                        optionEditor(index: index, option: option)
                    }

                    addOptionButton

                    if !hasRequiredContent {
                        Label("choice.editor.validation", systemImage: "exclamationmark.circle")
                            .font(OTTypography.body)
                            .foregroundStyle(OTColor.warning)
                            .fixedSize(horizontal: false, vertical: true)
                            .accessibilityIdentifier("choice.editor.validation")
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
                    Button("choice.action.cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("choice.action.save") {
                        save()
                    }
                    .disabled(!hasRequiredContent)
                    .accessibilityIdentifier("choice.editor.save")
                }
            }
        }
        .accessibilityIdentifier("choice.editor")
    }

    private func optionEditor(index: Int, option: ChoiceOptionDraftState) -> some View {
        let canMoveUp = index > 0
        let canMoveDown = index < options.count - 1
        let canRemove = options.count > ChoiceBoardLimits.minimumOptionCount

        return VStack(alignment: .leading, spacing: OTSpacing.sm) {
            Text("choice.editor.option \(index + 1)")
                .font(OTTypography.sectionHeading)
                .foregroundStyle(OTColor.primaryText)
                .accessibilityAddTraits(.isHeader)

            TextField(
                "choice.editor.label.placeholder",
                text: Binding(
                    get: { options[index].label },
                    set: { options[index].label = $0 }
                )
            )
            .textFieldStyle(.roundedBorder)
            .accessibilityIdentifier("choice.editor.option.label.\(index)")

            Picker(
                "choice.editor.symbol",
                selection: Binding(
                    get: { options[index].systemSymbolName },
                    set: { options[index].systemSymbolName = $0 }
                )
            ) {
                ForEach(ChoiceSymbolOption.allCases) { symbol in
                    Label(symbol.titleKey, systemImage: symbol.systemName)
                        .tag(symbol.systemName)
                }
            }
            .pickerStyle(.menu)
            .otMinimumInteractiveSize()
            .accessibilityIdentifier("choice.editor.option.symbol.\(index)")

            // Ordering is done with buttons, never drag alone, so Switch
            // Control and VoiceOver users can reorder the same way.
            HStack(spacing: OTSpacing.sm) {
                Button {
                    options.swapAt(index, index - 1)
                } label: {
                    Label("choice.action.moveUp", systemImage: "arrow.up")
                        .labelStyle(.iconOnly)
                }
                .buttonStyle(.bordered)
                .disabled(!canMoveUp)
                .otMinimumInteractiveSize()
                .accessibilityLabel("choice.action.moveUp")
                .accessibilityIdentifier("choice.editor.option.moveUp.\(index)")

                Button {
                    options.swapAt(index, index + 1)
                } label: {
                    Label("choice.action.moveDown", systemImage: "arrow.down")
                        .labelStyle(.iconOnly)
                }
                .buttonStyle(.bordered)
                .disabled(!canMoveDown)
                .otMinimumInteractiveSize()
                .accessibilityLabel("choice.action.moveDown")
                .accessibilityIdentifier("choice.editor.option.moveDown.\(index)")

                Button(role: .destructive) {
                    options.remove(at: index)
                } label: {
                    Label("choice.action.removeOption", systemImage: "minus.circle")
                        .labelStyle(.iconOnly)
                }
                .buttonStyle(.bordered)
                .disabled(!canRemove)
                .otMinimumInteractiveSize()
                .accessibilityLabel("choice.action.removeOption")
                .accessibilityIdentifier("choice.editor.option.remove.\(index)")
            }
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
        .accessibilityElement(children: .contain)
        .accessibilityActions {
            if canMoveUp {
                Button("choice.action.moveUp") { options.swapAt(index, index - 1) }
            }
            if canMoveDown {
                Button("choice.action.moveDown") { options.swapAt(index, index + 1) }
            }
            if canRemove {
                Button("choice.action.removeOption") { options.remove(at: index) }
            }
        }
    }

    private var addOptionButton: some View {
        VStack(alignment: .leading, spacing: OTSpacing.xs) {
            Button {
                options.append(
                    ChoiceOptionDraftState(
                        label: "",
                        systemSymbolName: ChoiceSymbolOption.play.systemName
                    )
                )
            } label: {
                Label("choice.action.addOption", systemImage: "plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .disabled(options.count >= ChoiceBoardLimits.maximumOptionCount)
            .otMinimumInteractiveSize()
            .accessibilityIdentifier("choice.editor.addOption")

            if options.count >= ChoiceBoardLimits.maximumOptionCount {
                Text("choice.editor.maximum")
                    .font(OTTypography.body)
                    .foregroundStyle(OTColor.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("choice.editor.maximum")
            }
        }
    }

    private var editorTitle: LocalizedStringKey {
        switch route {
        case .create: "choice.editor.create.title"
        case .edit: "choice.editor.edit.title"
        }
    }

    private var hasRequiredContent: Bool {
        !trimmed(name).isEmpty
            && ChoiceBoardLimits.allows(optionCount: options.count)
            && options.allSatisfy { !trimmed($0.label).isEmpty }
    }

    private func save() {
        let draft = ChoiceBoardDraft(
            name: name,
            options: options.map {
                ChoiceOptionDraft(label: $0.label, systemSymbolName: $0.systemSymbolName)
            }
        )

        let didSave: Bool
        switch route {
        case .create:
            didSave = controller.create(draft)
        case let .edit(board):
            didSave = controller.update(id: board.id, with: draft)
        }

        if didSave {
            dismiss()
        }
    }

    private func trimmed(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Therapist use

private struct ChoiceBoardUseView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var editorRoute: ChoiceEditorRoute?
    @State private var isConfirmingDelete = false

    let controller: ChoiceBoardController
    let sessionController: ChoiceBoardSessionController
    let boardID: UUID
    let onPresentChildFacing: (UUID) -> Void

    var body: some View {
        Group {
            if let board = controller.board(id: boardID) {
                content(board)
            } else {
                unavailableState
            }
        }
        .background(OTColor.background.ignoresSafeArea())
        .navigationTitle(controller.board(id: boardID)?.name ?? "")
        .accessibilityIdentifier("choice.board.use")
        .onAppear {
            guard let board = controller.board(id: boardID) else { return }
            if sessionController.session(for: boardID) == nil {
                sessionController.start(board: board)
            } else {
                sessionController.synchronize(with: board)
            }
        }
        .toolbar {
            if let board = controller.board(id: boardID) {
                ToolbarItemGroup(placement: .primaryAction) {
                    Button {
                        editorRoute = .edit(board)
                    } label: {
                        Label("choice.action.edit", systemImage: "pencil")
                    }
                    .accessibilityIdentifier("choice.board.use.edit")

                    Button(role: .destructive) {
                        isConfirmingDelete = true
                    } label: {
                        Label("choice.action.delete", systemImage: "trash")
                    }
                    .accessibilityIdentifier("choice.board.use.delete")
                }
            }
        }
        .sheet(item: $editorRoute) { route in
            ChoiceBoardEditorView(controller: controller, route: route)
        }
        .alert("choice.delete.title", isPresented: $isConfirmingDelete) {
            Button("choice.delete.cancel", role: .cancel) {}
            Button("choice.delete.confirm", role: .destructive) {
                if controller.delete(id: boardID) {
                    sessionController.discardSession(boardID: boardID)
                    dismiss()
                }
            }
        } message: {
            Text("choice.delete.message")
        }
    }

    private func content(_ board: ChoiceBoardSnapshot) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: OTSpacing.lg) {
                Button {
                    onPresentChildFacing(boardID)
                } label: {
                    Label("choice.action.childFacing", systemImage: "rectangle.inset.filled")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(OTColor.accent)
                .controlSize(.large)
                .otMinimumInteractiveSize()
                .accessibilityIdentifier("choice.action.childFacing")

                if let session = sessionController.session(for: boardID) {
                    ChoiceBoardGridView(
                        session: session,
                        context: .therapist,
                        onSelect: { sessionController.select(optionID: $0, boardID: boardID) }
                    )

                    selectionSummary(session)
                    visibilityControls(session)
                }

                boardActions(board)
            }
            .frame(maxWidth: 720, alignment: .leading)
            .padding(OTSpacing.xl)
            .frame(maxWidth: .infinity)
        }
    }

    /// Duplicate lives in the content rather than the toolbar: a third primary
    /// toolbar item collapses into an overflow menu on a compact iPhone, which
    /// hides a board-management action behind an extra tap.
    private func boardActions(_ board: ChoiceBoardSnapshot) -> some View {
        VStack(alignment: .leading, spacing: OTSpacing.sm) {
            Text("choice.board.actions.title")
                .font(OTTypography.sectionHeading)
                .foregroundStyle(OTColor.primaryText)
                .accessibilityAddTraits(.isHeader)

            Button {
                controller.duplicate(
                    id: boardID,
                    named: String(
                        format: String(localized: "choice.duplicate.name"),
                        board.name
                    )
                )
            } label: {
                Label("choice.action.duplicate", systemImage: "plus.square.on.square")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .otMinimumInteractiveSize()
            .accessibilityIdentifier("choice.action.duplicate")
        }
        .padding(OTSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(OTColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: OTRadius.card, style: .continuous))
        .accessibilityElement(children: .contain)
    }

    private func selectionSummary(_ session: ChoiceBoardSession) -> some View {
        VStack(alignment: .leading, spacing: OTSpacing.sm) {
            Text("choice.selection.title")
                .font(OTTypography.sectionHeading)
                .foregroundStyle(OTColor.primaryText)
                .accessibilityAddTraits(.isHeader)

            Text(
                session.selectedOption.map {
                    LocalizedStringKey("choice.selection.made \($0.label)")
                }
                    ?? "choice.selection.none"
            )
            .font(OTTypography.body)
            .foregroundStyle(OTColor.secondaryText)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityIdentifier("choice.selection.summary")

            Button {
                sessionController.clearSelection(boardID: boardID)
            } label: {
                Label("choice.action.clearSelection", systemImage: "arrow.uturn.backward")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .disabled(!session.hasSelection)
            .otMinimumInteractiveSize()
            .accessibilityIdentifier("choice.action.clearSelection")
        }
        .padding(OTSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(OTColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: OTRadius.card, style: .continuous))
        .accessibilityElement(children: .contain)
    }

    private func visibilityControls(_ session: ChoiceBoardSession) -> some View {
        VStack(alignment: .leading, spacing: OTSpacing.sm) {
            Text("choice.visibility.title")
                .font(OTTypography.sectionHeading)
                .foregroundStyle(OTColor.primaryText)
                .accessibilityAddTraits(.isHeader)

            Text("choice.visibility.message")
                .font(OTTypography.body)
                .foregroundStyle(OTColor.secondaryText)
                .fixedSize(horizontal: false, vertical: true)

            ForEach(session.board.options) { option in
                let isHidden = session.isHidden(option.id)

                HStack(spacing: OTSpacing.sm) {
                    Text(option.label)
                        .font(OTTypography.controlLabel)
                        .foregroundStyle(OTColor.primaryText)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer(minLength: 0)

                    Text(isHidden ? "choice.visibility.hidden" : "choice.visibility.shown")
                        .font(OTTypography.body)
                        .foregroundStyle(OTColor.secondaryText)

                    Button {
                        if isHidden {
                            sessionController.show(optionID: option.id, boardID: boardID)
                        } else {
                            sessionController.hide(optionID: option.id, boardID: boardID)
                        }
                    } label: {
                        Text(isHidden ? "choice.action.show" : "choice.action.hide")
                    }
                    .buttonStyle(.bordered)
                    .disabled(!isHidden && !session.canHide(option.id))
                    .otMinimumInteractiveSize()
                    .accessibilityIdentifier("choice.visibility.toggle.\(option.id.uuidString)")
                }
                .padding(.vertical, OTSpacing.xs)
                .accessibilityElement(children: .contain)
            }

            Button {
                sessionController.showAllOptions(boardID: boardID)
            } label: {
                Label("choice.action.showAll", systemImage: "arrow.counterclockwise")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .disabled(session.hiddenOptions.isEmpty)
            .otMinimumInteractiveSize()
            .accessibilityIdentifier("choice.action.showAll")
        }
        .padding(OTSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(OTColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: OTRadius.card, style: .continuous))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("choice.visibility")
    }

    private var unavailableState: some View {
        VStack(spacing: OTSpacing.md) {
            Text("choice.unavailable.title")
                .font(OTTypography.sectionHeading)
                .foregroundStyle(OTColor.primaryText)
            Text("choice.unavailable.message")
                .font(OTTypography.body)
                .foregroundStyle(OTColor.secondaryText)
                .multilineTextAlignment(.center)
            Button("choice.unavailable.back") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(OTSpacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Child facing

struct ChoiceBoardChildView: View {
    let controller: ChoiceBoardController
    let sessionController: ChoiceBoardSessionController
    let boardID: UUID

    var body: some View {
        Group {
            if let board = controller.board(id: boardID),
                let session = sessionController.session(for: boardID)
            {
                VStack(spacing: OTSpacing.lg) {
                    Text(board.name)
                        .font(OTTypography.screenTitle)
                        .foregroundStyle(OTColor.primaryText)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityIdentifier("choice.child.content")

                    ChoiceBoardGridView(
                        session: session,
                        context: .child,
                        onSelect: { sessionController.select(optionID: $0, boardID: boardID) }
                    )
                }
                .frame(maxWidth: 720)
            } else {
                VStack(spacing: OTSpacing.md) {
                    Text("choice.unavailable.title")
                        .font(OTTypography.sectionHeading)
                        .foregroundStyle(OTColor.primaryText)
                        .accessibilityAddTraits(.isHeader)
                    Text("choice.unavailable.message")
                        .font(OTTypography.body)
                        .foregroundStyle(OTColor.secondaryText)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier("choice.child.unavailable")
            }
        }
    }
}

enum ChoiceBoardGridContext {
    case child
    case therapist

    var identifierPrefix: String {
        switch self {
        case .child: "choice.child.option"
        case .therapist: "choice.board.option"
        }
    }
}

/// The choice tiles. Selection is carried by a checkmark symbol, a heavier
/// border, and a spoken state value as well as color, so it never depends on
/// color alone.
struct ChoiceBoardGridView: View {
    let session: ChoiceBoardSession
    let context: ChoiceBoardGridContext
    let onSelect: (UUID) -> Void

    private var columns: [GridItem] {
        [GridItem(.adaptive(minimum: 160), spacing: OTSpacing.md)]
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: OTSpacing.md) {
            ForEach(session.visibleOptions) { option in
                let isSelected = session.isSelected(option.id)

                Button {
                    onSelect(option.id)
                } label: {
                    VStack(spacing: OTSpacing.sm) {
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .font(OTTypography.sectionHeading)
                            .foregroundStyle(isSelected ? OTColor.success : OTColor.secondaryText)
                            .accessibilityHidden(true)

                        Image(systemName: option.systemSymbolName)
                            .font(OTTypography.childFacingValue)
                            .foregroundStyle(isSelected ? OTColor.accent : OTColor.primaryText)
                            .frame(minHeight: 64)
                            .accessibilityHidden(true)

                        Text(option.label)
                            .font(OTTypography.childFacingValue)
                            .foregroundStyle(OTColor.primaryText)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(OTSpacing.lg)
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .otMinimumInteractiveSize()
                .background(isSelected ? OTColor.elevatedSurface : OTColor.surface)
                .clipShape(RoundedRectangle(cornerRadius: OTRadius.card, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: OTRadius.card, style: .continuous)
                        .stroke(
                            isSelected ? OTColor.accent : OTColor.separator,
                            lineWidth: isSelected ? 3 : 1
                        )
                        .accessibilityHidden(true)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(verbatim: option.label))
                .accessibilityValue(
                    isSelected ? "choice.state.selected" : "choice.state.notSelected"
                )
                .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
                .accessibilityIdentifier("\(context.identifierPrefix).\(option.id.uuidString)")
            }
        }
    }
}
