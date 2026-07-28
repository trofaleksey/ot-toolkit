import SwiftUI

/// Therapist configuration for an ephemeral multi-board visual schedule.
struct FirstThenScheduleConfigureView: View {
    @Environment(\.dismiss) private var dismiss

    let controller: FirstThenBoardController
    let scheduleController: FirstThenScheduleController
    let onStart: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: OTSpacing.lg) {
                    guidance

                    if !scheduleController.selection.orderedBoardIDs.isEmpty {
                        selectedSection
                    }

                    availableSection

                    if !scheduleController.selection.canStart {
                        launchRequirement
                    }
                }
                .frame(maxWidth: 720, alignment: .leading)
                .padding(OTSpacing.xl)
                .frame(maxWidth: .infinity)
            }
            .background(OTColor.background.ignoresSafeArea())
            .navigationTitle("firstThen.schedule.configure.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("firstThen.action.cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("firstThen.schedule.action.start") {
                        onStart()
                    }
                    .disabled(!scheduleController.selection.canStart)
                    .accessibilityIdentifier("firstThen.schedule.action.start")
                }
            }
        }
        .accessibilityIdentifier("firstThen.schedule.configure")
        .onAppear {
            scheduleController.reconcileSelection(withAvailable: controller.boards)
        }
    }

    private var guidance: some View {
        VStack(alignment: .leading, spacing: OTSpacing.xs) {
            Text("firstThen.schedule.configure.guidance.title")
                .font(OTTypography.sectionHeading)
                .foregroundStyle(OTColor.primaryText)
                .accessibilityAddTraits(.isHeader)

            Text("firstThen.schedule.configure.guidance.message")
                .font(OTTypography.body)
                .foregroundStyle(OTColor.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(OTSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(OTColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: OTRadius.card, style: .continuous))
    }

    private var selectedSection: some View {
        VStack(alignment: .leading, spacing: OTSpacing.md) {
            Text("firstThen.schedule.configure.selected")
                .font(OTTypography.sectionHeading)
                .foregroundStyle(OTColor.primaryText)
                .accessibilityAddTraits(.isHeader)

            ForEach(selectedBoards) { board in
                selectedRow(board)
            }
        }
        .padding(OTSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(OTColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: OTRadius.card, style: .continuous))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("firstThen.schedule.configure.selected")
    }

    private func selectedRow(_ board: FirstThenBoardSnapshot) -> some View {
        let position = scheduleController.selection.position(of: board.id) ?? 0
        let canMoveUp = scheduleController.selection.canMoveUp(board.id)
        let canMoveDown = scheduleController.selection.canMoveDown(board.id)

        return HStack(alignment: .center, spacing: OTSpacing.sm) {
            VStack(alignment: .leading, spacing: OTSpacing.xs) {
                Text(
                    "firstThen.schedule.position \(position) \(scheduleController.selection.orderedBoardIDs.count)"
                )
                .font(OTTypography.controlLabel)
                .foregroundStyle(OTColor.secondaryText)

                Text(board.name)
                    .font(OTTypography.controlLabel.bold())
                    .foregroundStyle(OTColor.primaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)

            Button {
                scheduleController.moveSelectionUp(board.id)
            } label: {
                Label("firstThen.schedule.action.moveUp", systemImage: "arrow.up")
                    .labelStyle(.iconOnly)
            }
            .buttonStyle(.bordered)
            .disabled(!canMoveUp)
            .otMinimumInteractiveSize()
            .accessibilityLabel("firstThen.schedule.action.moveUp")
            .accessibilityIdentifier("firstThen.schedule.moveUp.\(board.id.uuidString)")

            Button {
                scheduleController.moveSelectionDown(board.id)
            } label: {
                Label("firstThen.schedule.action.moveDown", systemImage: "arrow.down")
                    .labelStyle(.iconOnly)
            }
            .buttonStyle(.bordered)
            .disabled(!canMoveDown)
            .otMinimumInteractiveSize()
            .accessibilityLabel("firstThen.schedule.action.moveDown")
            .accessibilityIdentifier("firstThen.schedule.moveDown.\(board.id.uuidString)")

            Button(role: .destructive) {
                scheduleController.toggleSelection(board.id)
            } label: {
                Label("firstThen.schedule.action.remove", systemImage: "minus.circle")
                    .labelStyle(.iconOnly)
            }
            .buttonStyle(.bordered)
            .otMinimumInteractiveSize()
            .accessibilityLabel("firstThen.schedule.action.remove")
            .accessibilityIdentifier("firstThen.schedule.remove.\(board.id.uuidString)")
        }
        .padding(OTSpacing.sm)
        .background(OTColor.elevatedSurface)
        .clipShape(RoundedRectangle(cornerRadius: OTRadius.card, style: .continuous))
        // Reordering must not depend on dragging, so the visible buttons are
        // mirrored as rotor actions for Switch Control and VoiceOver users.
        .accessibilityElement(children: .contain)
        .accessibilityActions {
            if canMoveUp {
                Button("firstThen.schedule.action.moveUp") {
                    scheduleController.moveSelectionUp(board.id)
                }
            }
            if canMoveDown {
                Button("firstThen.schedule.action.moveDown") {
                    scheduleController.moveSelectionDown(board.id)
                }
            }
            Button("firstThen.schedule.action.remove") {
                scheduleController.toggleSelection(board.id)
            }
        }
    }

    private var availableSection: some View {
        VStack(alignment: .leading, spacing: OTSpacing.md) {
            Text("firstThen.schedule.configure.available")
                .font(OTTypography.sectionHeading)
                .foregroundStyle(OTColor.primaryText)
                .accessibilityAddTraits(.isHeader)

            ForEach(controller.boards) { board in
                let isSelected = scheduleController.selection.isSelected(board.id)

                Button {
                    scheduleController.toggleSelection(board.id)
                } label: {
                    HStack(spacing: OTSpacing.sm) {
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(isSelected ? OTColor.accent : OTColor.secondaryText)
                            .accessibilityHidden(true)

                        VStack(alignment: .leading, spacing: OTSpacing.xs) {
                            Text(board.name)
                                .font(OTTypography.controlLabel.bold())
                                .foregroundStyle(OTColor.primaryText)
                                .fixedSize(horizontal: false, vertical: true)

                            Text(
                                isSelected
                                    ? "firstThen.schedule.state.selected"
                                    : "firstThen.schedule.state.notSelected"
                            )
                            .font(OTTypography.body)
                            .foregroundStyle(OTColor.secondaryText)
                        }

                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .otMinimumInteractiveSize()
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
                .accessibilityIdentifier("firstThen.schedule.select.\(board.id.uuidString)")
            }
        }
        .padding(OTSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(OTColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: OTRadius.card, style: .continuous))
        .accessibilityElement(children: .contain)
    }

    private var launchRequirement: some View {
        Label("firstThen.schedule.configure.requirement", systemImage: "exclamationmark.circle")
            .font(OTTypography.body)
            .foregroundStyle(OTColor.warning)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityIdentifier("firstThen.schedule.configure.requirement")
    }

    private var selectedBoards: [FirstThenBoardSnapshot] {
        scheduleController.selection.orderedBoardIDs.compactMap { controller.board(id: $0) }
    }
}

/// Therapist controls for a running schedule. Replaces the saved-board list
/// while a schedule is active so adult exit always returns here with progress
/// intact.
struct FirstThenScheduleTherapistView: View {
    @State private var isConfirmingStartOver = false
    @State private var isConfirmingEnd = false

    let scheduleController: FirstThenScheduleController
    let session: FirstThenScheduleSession
    let onPresentChildFacing: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: OTSpacing.lg) {
                header

                Button(action: onPresentChildFacing) {
                    Label("firstThen.action.childFacing", systemImage: "rectangle.inset.filled")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(OTColor.accent)
                .controlSize(.large)
                .otMinimumInteractiveSize()
                .accessibilityIdentifier("firstThen.schedule.action.childFacing")

                if let board = session.currentBoard {
                    FirstThenBoardSequenceView(
                        board: board,
                        isFirstComplete: session.isFirstComplete,
                        context: .scheduleTherapist
                    ) {
                        scheduleController.completeFirst()
                    }
                } else {
                    FirstThenScheduleCompletionView(
                        identifier: "firstThen.schedule.completed"
                    )
                }

                controls

                FirstThenScheduleOutlineView(
                    session: session,
                    identifier: "firstThen.schedule.outline"
                )
            }
            .frame(maxWidth: 720, alignment: .leading)
            .padding(OTSpacing.xl)
            .frame(maxWidth: .infinity)
        }
        .background(OTColor.background.ignoresSafeArea())
        .navigationTitle("firstThen.schedule.title")
        .accessibilityIdentifier("firstThen.schedule.therapist")
        .alert("firstThen.schedule.startOver.title", isPresented: $isConfirmingStartOver) {
            Button("firstThen.schedule.startOver.cancel", role: .cancel) {}
            Button("firstThen.schedule.startOver.confirm") {
                scheduleController.startOver()
            }
        } message: {
            Text("firstThen.schedule.startOver.message")
        }
        .alert("firstThen.schedule.end.title", isPresented: $isConfirmingEnd) {
            Button("firstThen.schedule.end.cancel", role: .cancel) {}
            Button("firstThen.schedule.end.confirm", role: .destructive) {
                scheduleController.endSchedule()
            }
        } message: {
            Text("firstThen.schedule.end.message")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: OTSpacing.xs) {
            Text("firstThen.schedule.title")
                .font(OTTypography.sectionHeading)
                .foregroundStyle(OTColor.primaryText)
                .accessibilityAddTraits(.isHeader)

            Text(FirstThenScheduleFormat.positionKey(for: session))
                .font(OTTypography.body)
                .foregroundStyle(OTColor.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("firstThen.schedule.position")
        }
        .padding(OTSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(OTColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: OTRadius.card, style: .continuous))
        .accessibilityElement(children: .contain)
    }

    private var controls: some View {
        VStack(alignment: .leading, spacing: OTSpacing.md) {
            Text("firstThen.schedule.controls.title")
                .font(OTTypography.sectionHeading)
                .foregroundStyle(OTColor.primaryText)
                .accessibilityAddTraits(.isHeader)

            if session.canAdvance {
                Button {
                    scheduleController.advance()
                } label: {
                    Label(
                        "firstThen.schedule.action.advance",
                        systemImage: "arrow.right.circle.fill"
                    )
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(OTColor.accent)
                .controlSize(.large)
                .otMinimumInteractiveSize()
                .accessibilityIdentifier("firstThen.schedule.action.advance")
            }

            Button {
                scheduleController.goBack()
            } label: {
                Label("firstThen.schedule.action.back", systemImage: "arrow.uturn.backward")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .disabled(!session.canGoBack)
            .otMinimumInteractiveSize()
            .accessibilityIdentifier("firstThen.schedule.action.back")

            Button {
                isConfirmingStartOver = true
            } label: {
                Label(
                    "firstThen.schedule.action.startOver",
                    systemImage: "arrow.counterclockwise"
                )
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .otMinimumInteractiveSize()
            .accessibilityIdentifier("firstThen.schedule.action.startOver")

            Button(role: .destructive) {
                isConfirmingEnd = true
            } label: {
                Label("firstThen.schedule.action.end", systemImage: "xmark.circle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .otMinimumInteractiveSize()
            .accessibilityIdentifier("firstThen.schedule.action.end")
        }
        .padding(OTSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(OTColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: OTRadius.card, style: .continuous))
        .accessibilityElement(children: .contain)
    }
}

/// Child-facing schedule. Carries only the controls a child interaction needs:
/// Back, Start Over, and End Schedule stay behind the adult exit.
struct FirstThenScheduleChildView: View {
    let scheduleController: FirstThenScheduleController
    let session: FirstThenScheduleSession

    var body: some View {
        VStack(spacing: OTSpacing.lg) {
            Text(FirstThenScheduleFormat.positionKey(for: session))
                .font(OTTypography.sectionHeading)
                .foregroundStyle(OTColor.secondaryText)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("firstThen.schedule.child.position")

            if let board = session.currentBoard {
                Text(board.name)
                    .font(OTTypography.screenTitle)
                    .foregroundStyle(OTColor.primaryText)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityIdentifier("firstThen.schedule.child.content")

                FirstThenBoardSequenceView(
                    board: board,
                    isFirstComplete: session.isFirstComplete,
                    context: .scheduleChild
                ) {
                    scheduleController.completeFirst()
                }

                if session.canAdvance {
                    Button {
                        scheduleController.advance()
                    } label: {
                        Label(
                            "firstThen.schedule.action.advance",
                            systemImage: "arrow.right.circle.fill"
                        )
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(OTColor.accent)
                    .controlSize(.large)
                    .otMinimumInteractiveSize()
                    .accessibilityIdentifier("firstThen.schedule.child.advance")
                }
            } else {
                FirstThenScheduleCompletionView(
                    identifier: "firstThen.schedule.child.completed"
                )
            }

            FirstThenScheduleOutlineView(
                session: session,
                identifier: "firstThen.schedule.child.outline"
            )
        }
        .frame(maxWidth: 720)
    }
}

/// Calm completed/current/upcoming summary of the whole schedule. State is
/// carried by text and symbol as well as emphasis, never by color alone.
private struct FirstThenScheduleOutlineView: View {
    let session: FirstThenScheduleSession
    let identifier: String

    var body: some View {
        VStack(alignment: .leading, spacing: OTSpacing.sm) {
            Text("firstThen.schedule.outline.title")
                .font(OTTypography.sectionHeading)
                .foregroundStyle(OTColor.primaryText)
                .accessibilityAddTraits(.isHeader)

            ForEach(Array(session.boards.enumerated()), id: \.element.id) { index, board in
                let status = session.status(at: index)

                HStack(alignment: .top, spacing: OTSpacing.sm) {
                    Image(systemName: status.symbolName)
                        .foregroundStyle(
                            status == .current ? OTColor.accent : OTColor.secondaryText
                        )
                        .accessibilityHidden(true)

                    Text(board.name)
                        .font(
                            status == .current
                                ? OTTypography.controlLabel.bold() : OTTypography.controlLabel
                        )
                        .foregroundStyle(
                            status == .upcoming ? OTColor.secondaryText : OTColor.primaryText
                        )
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer(minLength: 0)

                    Text(status.titleKey)
                        .font(OTTypography.body)
                        .foregroundStyle(OTColor.secondaryText)
                }
                .padding(.vertical, OTSpacing.xs)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(verbatim: board.name))
                .accessibilityValue(Text(status.titleKey))
                .accessibilityIdentifier("\(identifier).\(index)")
            }
        }
        .padding(OTSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(OTColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: OTRadius.card, style: .continuous))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(identifier)
    }
}

/// Shown if child-facing mode is somehow reached without an active schedule.
/// The adult exit in the surrounding container remains the way out.
struct FirstThenScheduleUnavailableView: View {
    var body: some View {
        VStack(spacing: OTSpacing.md) {
            Text("firstThen.schedule.unavailable.title")
                .font(OTTypography.sectionHeading)
                .foregroundStyle(OTColor.primaryText)
                .accessibilityAddTraits(.isHeader)

            Text("firstThen.schedule.unavailable.message")
                .font(OTTypography.body)
                .foregroundStyle(OTColor.secondaryText)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("firstThen.schedule.child.unavailable")
    }
}

private struct FirstThenScheduleCompletionView: View {
    let identifier: String

    var body: some View {
        VStack(spacing: OTSpacing.md) {
            Image(systemName: "checkmark.circle.fill")
                .font(OTTypography.childFacingValue)
                .foregroundStyle(OTColor.success)
                .accessibilityHidden(true)

            Text("firstThen.schedule.completed.title")
                .font(OTTypography.screenTitle)
                .foregroundStyle(OTColor.primaryText)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Text("firstThen.schedule.completed.message")
                .font(OTTypography.body)
                .foregroundStyle(OTColor.secondaryText)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(OTSpacing.lg)
        .frame(maxWidth: .infinity)
        .background(OTColor.elevatedSurface)
        .clipShape(RoundedRectangle(cornerRadius: OTRadius.card, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(identifier)
    }
}

enum FirstThenScheduleFormat {
    static func positionKey(for session: FirstThenScheduleSession) -> LocalizedStringKey {
        guard let position = session.currentPositionNumber else {
            return "firstThen.schedule.position.completed"
        }
        return "firstThen.schedule.position \(position) \(session.boardCount)"
    }
}

extension FirstThenScheduleBoardStatus {
    var titleKey: LocalizedStringKey {
        switch self {
        case .completed: "firstThen.schedule.status.completed"
        case .current: "firstThen.schedule.status.current"
        case .upcoming: "firstThen.schedule.status.upcoming"
        }
    }

    var symbolName: String {
        switch self {
        case .completed: "checkmark.circle.fill"
        case .current: "play.circle.fill"
        case .upcoming: "circle"
        }
    }
}
