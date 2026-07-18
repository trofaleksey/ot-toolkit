import SwiftUI

private enum FirstThenSymbolOption: CaseIterable, Identifiable, Sendable {
    case move
    case dress
    case read
    case create
    case eat
    case play

    var id: String { systemName }

    var systemName: String {
        switch self {
        case .move: "figure.walk"
        case .dress: "tshirt"
        case .read: "book.closed"
        case .create: "paintbrush"
        case .eat: "fork.knife"
        case .play: "puzzlepiece"
        }
    }

    var titleKey: LocalizedStringKey {
        switch self {
        case .move: "firstThen.symbol.move"
        case .dress: "firstThen.symbol.dress"
        case .read: "firstThen.symbol.read"
        case .create: "firstThen.symbol.create"
        case .eat: "firstThen.symbol.eat"
        case .play: "firstThen.symbol.play"
        }
    }
}

private enum FirstThenEditorRoute: Identifiable {
    case create
    case edit(FirstThenBoardSnapshot)

    var id: String {
        switch self {
        case .create:
            "create"
        case let .edit(board):
            board.id.uuidString
        }
    }
}

struct FirstThenBoardsView: View {
    @State private var editorRoute: FirstThenEditorRoute?

    let controller: FirstThenBoardController

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
        .navigationTitle("firstThen.title")
        .accessibilityIdentifier("firstThen.destination")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    editorRoute = .create
                } label: {
                    Label("firstThen.action.create", systemImage: "plus")
                }
                .accessibilityIdentifier("firstThen.action.create")
            }
        }
        .sheet(item: $editorRoute) { route in
            FirstThenBoardEditorView(controller: controller, route: route)
        }
        .alert(
            failureTitle,
            isPresented: failureBinding
        ) {
            if controller.failure == .load {
                Button("firstThen.error.retry") {
                    controller.reload()
                }
            }
            Button("firstThen.error.dismiss", role: .cancel) {
                controller.dismissFailure()
            }
        } message: {
            Text(failureMessage)
        }
    }

    private var guidance: some View {
        VStack(alignment: .leading, spacing: OTSpacing.xs) {
            Text("firstThen.guidance.title")
                .font(OTTypography.sectionHeading)
                .foregroundStyle(OTColor.primaryText)
                .accessibilityAddTraits(.isHeader)

            Text("firstThen.guidance.message")
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
            Image(systemName: "rectangle.split.2x1")
                .font(OTTypography.screenTitle)
                .foregroundStyle(OTColor.accent)
                .accessibilityHidden(true)

            Text("firstThen.empty.title")
                .font(OTTypography.sectionHeading)
                .foregroundStyle(OTColor.primaryText)
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier("firstThen.empty.title")

            Text("firstThen.empty.message")
                .font(OTTypography.body)
                .foregroundStyle(OTColor.secondaryText)
                .fixedSize(horizontal: false, vertical: true)

            Button("firstThen.action.create") {
                editorRoute = .create
            }
            .buttonStyle(.borderedProminent)
            .tint(OTColor.accent)
            .controlSize(.large)
            .otMinimumInteractiveSize()
            .accessibilityIdentifier("firstThen.empty.create")
        }
        .padding(OTSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(OTColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: OTRadius.card, style: .continuous))
    }

    private func boardRow(_ board: FirstThenBoardSnapshot) -> some View {
        HStack(alignment: .top, spacing: OTSpacing.sm) {
            NavigationLink {
                FirstThenBoardUseView(controller: controller, boardID: board.id)
            } label: {
                VStack(alignment: .leading, spacing: OTSpacing.sm) {
                    Text(board.name)
                        .font(OTTypography.sectionHeading)
                        .foregroundStyle(OTColor.primaryText)
                        .fixedSize(horizontal: false, vertical: true)

                    itemSummary(
                        roleKey: "firstThen.role.first",
                        item: board.first
                    )
                    itemSummary(
                        roleKey: "firstThen.role.then",
                        item: board.then
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("firstThen.board.\(board.id.uuidString)")

            Button {
                editorRoute = .edit(board)
            } label: {
                Label("firstThen.action.edit", systemImage: "pencil")
                    .labelStyle(.iconOnly)
            }
            .buttonStyle(.bordered)
            .otMinimumInteractiveSize()
            .accessibilityLabel("firstThen.action.edit")
            .accessibilityIdentifier("firstThen.board.edit.\(board.id.uuidString)")
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

    private func itemSummary(
        roleKey: LocalizedStringKey,
        item: FirstThenItemSnapshot
    ) -> some View {
        HStack(spacing: OTSpacing.sm) {
            Image(systemName: item.systemSymbolName)
                .frame(width: 28, height: 28)
                .foregroundStyle(OTColor.accent)
                .accessibilityHidden(true)

            Text(roleKey)
                .font(OTTypography.controlLabel.bold())
                .foregroundStyle(OTColor.primaryText)
            Text(item.label)
                .font(OTTypography.body)
                .foregroundStyle(OTColor.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
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
            "firstThen.error.load.title"
        case .create:
            "firstThen.error.create.title"
        case .update:
            "firstThen.error.update.title"
        case .delete:
            "firstThen.error.delete.title"
        case nil:
            "firstThen.error.title"
        }
    }

    private var failureMessage: LocalizedStringKey {
        switch controller.failure {
        case .load:
            "firstThen.error.load.message"
        case .create, .update, .delete:
            "firstThen.error.save.message"
        case nil:
            "firstThen.error.save.message"
        }
    }
}

private struct FirstThenBoardEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var firstLabel: String
    @State private var firstSymbolName: String
    @State private var thenLabel: String
    @State private var thenSymbolName: String

    let controller: FirstThenBoardController
    let route: FirstThenEditorRoute

    init(controller: FirstThenBoardController, route: FirstThenEditorRoute) {
        self.controller = controller
        self.route = route

        let board: FirstThenBoardSnapshot?
        switch route {
        case .create:
            board = nil
        case let .edit(existingBoard):
            board = existingBoard
        }

        _name = State(initialValue: board?.name ?? "")
        _firstLabel = State(initialValue: board?.first.label ?? "")
        _firstSymbolName = State(
            initialValue: board?.first.systemSymbolName ?? FirstThenSymbolOption.move.systemName
        )
        _thenLabel = State(initialValue: board?.then.label ?? "")
        _thenSymbolName = State(
            initialValue: board?.then.systemSymbolName ?? FirstThenSymbolOption.read.systemName
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: OTSpacing.lg) {
                    Text("firstThen.editor.guidance")
                        .font(OTTypography.body)
                        .foregroundStyle(OTColor.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)

                    VStack(alignment: .leading, spacing: OTSpacing.sm) {
                        Text("firstThen.editor.name")
                            .font(OTTypography.sectionHeading)
                            .foregroundStyle(OTColor.primaryText)
                        TextField("firstThen.editor.name.placeholder", text: $name)
                            .textFieldStyle(.roundedBorder)
                            .accessibilityIdentifier("firstThen.editor.name")
                    }

                    itemEditor(
                        roleKey: "firstThen.role.first",
                        label: $firstLabel,
                        symbolName: $firstSymbolName,
                        labelIdentifier: "firstThen.editor.first.label",
                        symbolIdentifier: "firstThen.editor.first.symbol"
                    )

                    itemEditor(
                        roleKey: "firstThen.role.then",
                        label: $thenLabel,
                        symbolName: $thenSymbolName,
                        labelIdentifier: "firstThen.editor.then.label",
                        symbolIdentifier: "firstThen.editor.then.symbol"
                    )

                    if !hasRequiredContent {
                        Label(
                            "firstThen.editor.validation",
                            systemImage: "exclamationmark.circle"
                        )
                        .font(OTTypography.body)
                        .foregroundStyle(OTColor.warning)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("firstThen.editor.validation")
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
                    Button("firstThen.action.cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("firstThen.action.save") {
                        save()
                    }
                    .disabled(!hasRequiredContent)
                    .accessibilityIdentifier("firstThen.editor.save")
                }
            }
        }
        .interactiveDismissDisabled(hasEnteredContent)
        .accessibilityIdentifier("firstThen.editor")
        .alert(editorFailureTitle, isPresented: editorFailureBinding) {
            Button("firstThen.error.dismiss", role: .cancel) {
                controller.dismissFailure()
            }
        } message: {
            Text("firstThen.error.save.message")
        }
    }

    private var editorTitle: LocalizedStringKey {
        switch route {
        case .create:
            "firstThen.editor.create.title"
        case .edit:
            "firstThen.editor.edit.title"
        }
    }

    private var hasRequiredContent: Bool {
        !trimmed(name).isEmpty
            && !trimmed(firstLabel).isEmpty
            && !trimmed(thenLabel).isEmpty
    }

    private var hasEnteredContent: Bool {
        !name.isEmpty || !firstLabel.isEmpty || !thenLabel.isEmpty
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
            "firstThen.error.create.title"
        case .update:
            "firstThen.error.update.title"
        case .load, .delete, nil:
            "firstThen.error.title"
        }
    }

    private func itemEditor(
        roleKey: LocalizedStringKey,
        label: Binding<String>,
        symbolName: Binding<String>,
        labelIdentifier: String,
        symbolIdentifier: String
    ) -> some View {
        VStack(alignment: .leading, spacing: OTSpacing.sm) {
            Text(roleKey)
                .font(OTTypography.sectionHeading)
                .foregroundStyle(OTColor.primaryText)
                .accessibilityAddTraits(.isHeader)

            TextField("firstThen.editor.label.placeholder", text: label)
                .textFieldStyle(.roundedBorder)
                .accessibilityIdentifier(labelIdentifier)

            Picker("firstThen.editor.symbol", selection: symbolName) {
                ForEach(FirstThenSymbolOption.allCases) { option in
                    Label(option.titleKey, systemImage: option.systemName)
                        .tag(option.systemName)
                }
            }
            .pickerStyle(.menu)
            .otMinimumInteractiveSize()
            .accessibilityIdentifier(symbolIdentifier)
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

    private func save() {
        let draft = FirstThenBoardDraft(
            name: name,
            first: FirstThenItemDraft(
                label: firstLabel,
                systemSymbolName: firstSymbolName
            ),
            then: FirstThenItemDraft(
                label: thenLabel,
                systemSymbolName: thenSymbolName
            )
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

private struct FirstThenBoardUseView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isFirstComplete = false
    @State private var editorRoute: FirstThenEditorRoute?
    @State private var isConfirmingDelete = false

    let controller: FirstThenBoardController
    let boardID: UUID

    var body: some View {
        Group {
            if let board = controller.board(id: boardID) {
                boardContent(board)
            } else {
                unavailableState
            }
        }
        .background(OTColor.background.ignoresSafeArea())
        .navigationTitle(controller.board(id: boardID)?.name ?? "")
        .accessibilityIdentifier("firstThen.board.use")
        .toolbar {
            if let board = controller.board(id: boardID) {
                ToolbarItemGroup(placement: .primaryAction) {
                    Button {
                        editorRoute = .edit(board)
                    } label: {
                        Label("firstThen.action.edit", systemImage: "pencil")
                    }
                    .accessibilityIdentifier("firstThen.board.use.edit")

                    Button(role: .destructive) {
                        isConfirmingDelete = true
                    } label: {
                        Label("firstThen.action.delete", systemImage: "trash")
                    }
                    .accessibilityIdentifier("firstThen.board.use.delete")
                }
            }
        }
        .sheet(item: $editorRoute) { route in
            FirstThenBoardEditorView(controller: controller, route: route)
        }
        .alert("firstThen.delete.title", isPresented: $isConfirmingDelete) {
            Button("firstThen.delete.cancel", role: .cancel) {}
            Button("firstThen.delete.confirm", role: .destructive) {
                if controller.delete(id: boardID) {
                    dismiss()
                }
            }
        } message: {
            Text("firstThen.delete.message")
        }
    }

    private func boardContent(_ board: FirstThenBoardSnapshot) -> some View {
        ScrollView {
            VStack(spacing: OTSpacing.lg) {
                boardItem(
                    roleKey: "firstThen.role.first",
                    item: board.first,
                    stateKey: isFirstComplete
                        ? "firstThen.state.completed" : "firstThen.state.current",
                    stateSymbol: isFirstComplete ? "checkmark.circle.fill" : "1.circle.fill",
                    isProminent: !isFirstComplete,
                    identifier: "firstThen.board.first"
                )

                Image(systemName: "arrow.down")
                    .font(OTTypography.sectionHeading)
                    .foregroundStyle(OTColor.secondaryText)
                    .accessibilityHidden(true)

                boardItem(
                    roleKey: "firstThen.role.then",
                    item: board.then,
                    stateKey: isFirstComplete ? "firstThen.state.current" : "firstThen.state.next",
                    stateSymbol: isFirstComplete ? "play.circle.fill" : "2.circle",
                    isProminent: isFirstComplete,
                    identifier: "firstThen.board.then"
                )

                if !isFirstComplete {
                    Button {
                        isFirstComplete = true
                    } label: {
                        Label(
                            "firstThen.action.completeFirst",
                            systemImage: "checkmark.circle"
                        )
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(OTColor.accent)
                    .controlSize(.large)
                    .otMinimumInteractiveSize()
                    .accessibilityIdentifier("firstThen.action.completeFirst")
                    .keyboardShortcut(.defaultAction)
                } else {
                    Label("firstThen.transition.then", systemImage: "arrow.right.circle.fill")
                        .font(OTTypography.sectionHeading)
                        .foregroundStyle(OTColor.primaryText)
                        .padding(OTSpacing.md)
                        .frame(maxWidth: .infinity)
                        .background(OTColor.elevatedSurface)
                        .clipShape(
                            RoundedRectangle(cornerRadius: OTRadius.card, style: .continuous)
                        )
                        .accessibilityIdentifier("firstThen.transition.then")
                }
            }
            .frame(maxWidth: 720)
            .padding(OTSpacing.xl)
            .frame(maxWidth: .infinity)
        }
    }

    private func boardItem(
        roleKey: LocalizedStringKey,
        item: FirstThenItemSnapshot,
        stateKey: LocalizedStringKey,
        stateSymbol: String,
        isProminent: Bool,
        identifier: String
    ) -> some View {
        VStack(spacing: OTSpacing.md) {
            HStack(spacing: OTSpacing.sm) {
                Image(systemName: stateSymbol)
                    .foregroundStyle(isProminent ? OTColor.accent : OTColor.secondaryText)
                    .accessibilityHidden(true)

                Text(roleKey)
                    .font(OTTypography.sectionHeading)
                    .foregroundStyle(OTColor.primaryText)

                Spacer(minLength: 0)

                Text(stateKey)
                    .font(OTTypography.controlLabel)
                    .foregroundStyle(OTColor.secondaryText)
            }

            Image(systemName: item.systemSymbolName)
                .font(OTTypography.childFacingValue)
                .foregroundStyle(isProminent ? OTColor.accent : OTColor.secondaryText)
                .frame(minHeight: 72)
                .accessibilityHidden(true)

            Text(item.label)
                .font(OTTypography.childFacingValue)
                .foregroundStyle(OTColor.primaryText)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(OTSpacing.lg)
        .frame(maxWidth: .infinity)
        .background(isProminent ? OTColor.elevatedSurface : OTColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: OTRadius.card, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: OTRadius.card, style: .continuous)
                .stroke(
                    isProminent ? OTColor.accent : OTColor.separator,
                    lineWidth: isProminent ? 2 : 1
                )
                .accessibilityHidden(true)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(roleKey) + Text(verbatim: ", \(item.label)"))
        .accessibilityValue(stateKey)
        .accessibilityIdentifier(identifier)
    }

    private var unavailableState: some View {
        VStack(spacing: OTSpacing.md) {
            Text("firstThen.unavailable.title")
                .font(OTTypography.sectionHeading)
                .foregroundStyle(OTColor.primaryText)
            Text("firstThen.unavailable.message")
                .font(OTTypography.body)
                .foregroundStyle(OTColor.secondaryText)
                .multilineTextAlignment(.center)
            Button("firstThen.unavailable.back") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(OTSpacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
