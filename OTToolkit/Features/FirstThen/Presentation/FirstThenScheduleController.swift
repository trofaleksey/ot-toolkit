import Foundation
import Observation

/// Owns the ephemeral visual-schedule selection and the active session.
///
/// Nothing here is persisted: the controller is created with the app scene, so
/// force-quit or process termination ends any schedule, and no saved board is
/// created, edited, reordered, or deleted by scheduling.
@MainActor
@Observable
final class FirstThenScheduleController {
    private(set) var selection = FirstThenScheduleSelection()
    private(set) var session: FirstThenScheduleSession?

    var isScheduleActive: Bool {
        session != nil
    }

    // MARK: - Configuring

    func toggleSelection(_ boardID: UUID) {
        selection.toggle(boardID)
    }

    @discardableResult
    func moveSelectionUp(_ boardID: UUID) -> Bool {
        selection.moveUp(boardID)
    }

    @discardableResult
    func moveSelectionDown(_ boardID: UUID) -> Bool {
        selection.moveDown(boardID)
    }

    func clearSelection() {
        selection.clear()
    }

    /// Drops any selected board that no longer exists. Called before showing or
    /// launching a selection so a board deleted mid-configuration cannot end up
    /// in a schedule.
    func reconcileSelection(withAvailable boards: [FirstThenBoardSnapshot]) {
        selection.reconcile(withAvailable: Set(boards.map(\.id)))
    }

    /// Launches in the selected order, taking value snapshots as they exist
    /// now, so later edits cannot mutate a running schedule.
    @discardableResult
    func start(availableBoards: [FirstThenBoardSnapshot]) -> Bool {
        reconcileSelection(withAvailable: availableBoards)

        let boardsByID = Dictionary(uniqueKeysWithValues: availableBoards.map { ($0.id, $0) })
        let orderedBoards = selection.orderedBoardIDs.compactMap { boardsByID[$0] }

        guard let session = FirstThenScheduleSession(boards: orderedBoards) else {
            return false
        }

        self.session = session
        return true
    }

    // MARK: - Running

    @discardableResult
    func completeFirst() -> Bool {
        mutateSession { $0.completeFirst() }
    }

    @discardableResult
    func advance() -> Bool {
        mutateSession { $0.advance() }
    }

    @discardableResult
    func goBack() -> Bool {
        mutateSession { $0.goBack() }
    }

    @discardableResult
    func startOver() -> Bool {
        mutateSession {
            $0.startOver()
            return true
        }
    }

    /// Discards the schedule and its selection. Saved boards are untouched.
    func endSchedule() {
        session = nil
        selection.clear()
    }

    private func mutateSession(
        _ mutate: (inout FirstThenScheduleSession) -> Bool
    ) -> Bool {
        guard var session else { return false }
        let didChange = mutate(&session)
        if didChange {
            self.session = session
        }
        return didChange
    }
}
