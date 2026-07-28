import Foundation

/// Ordering and validity of the boards a therapist is choosing for a schedule.
///
/// Selection is ephemeral: it is never persisted and never rewrites the saved
/// `sortIndex` of any board.
struct FirstThenScheduleSelection: Equatable, Sendable {
    static let minimumBoardCount = 2

    private(set) var orderedBoardIDs: [UUID] = []

    var canStart: Bool {
        orderedBoardIDs.count >= Self.minimumBoardCount
    }

    func isSelected(_ boardID: UUID) -> Bool {
        orderedBoardIDs.contains(boardID)
    }

    /// Selection order is the launch order, so a newly selected board is
    /// appended rather than taking the saved-board position.
    mutating func toggle(_ boardID: UUID) {
        if let index = orderedBoardIDs.firstIndex(of: boardID) {
            orderedBoardIDs.remove(at: index)
        } else {
            orderedBoardIDs.append(boardID)
        }
    }

    @discardableResult
    mutating func moveUp(_ boardID: UUID) -> Bool {
        guard let index = orderedBoardIDs.firstIndex(of: boardID), index > 0 else {
            return false
        }
        orderedBoardIDs.swapAt(index, index - 1)
        return true
    }

    @discardableResult
    mutating func moveDown(_ boardID: UUID) -> Bool {
        guard let index = orderedBoardIDs.firstIndex(of: boardID),
            index < orderedBoardIDs.count - 1
        else {
            return false
        }
        orderedBoardIDs.swapAt(index, index + 1)
        return true
    }

    func canMoveUp(_ boardID: UUID) -> Bool {
        guard let index = orderedBoardIDs.firstIndex(of: boardID) else { return false }
        return index > 0
    }

    func canMoveDown(_ boardID: UUID) -> Bool {
        guard let index = orderedBoardIDs.firstIndex(of: boardID) else { return false }
        return index < orderedBoardIDs.count - 1
    }

    func position(of boardID: UUID) -> Int? {
        orderedBoardIDs.firstIndex(of: boardID).map { $0 + 1 }
    }

    /// Drops boards that no longer exist, preserving the order of the rest.
    ///
    /// A board can be deleted between selecting it and launching. Reconciling
    /// keeps the pending selection usable instead of launching a schedule that
    /// references a board that is gone.
    mutating func reconcile(withAvailable availableBoardIDs: some Collection<UUID>) {
        orderedBoardIDs.removeAll { !availableBoardIDs.contains($0) }
    }

    mutating func clear() {
        orderedBoardIDs.removeAll()
    }
}

enum FirstThenSchedulePhase: Equatable, Sendable {
    case first
    case then
}

enum FirstThenScheduleBoardStatus: Equatable, Sendable {
    case completed
    case current
    case upcoming
}

/// An in-progress visual schedule.
///
/// The session holds immutable value snapshots taken at launch, so it is not
/// coupled to the live SwiftData models and cannot be mutated underneath the
/// child by a therapist edit. It is memory-only: process loss ends it.
struct FirstThenScheduleSession: Equatable, Sendable {
    enum Position: Equatable, Sendable {
        case board(index: Int, phase: FirstThenSchedulePhase)
        case scheduleCompleted
    }

    let boards: [FirstThenBoardSnapshot]
    private(set) var position: Position

    /// Fails rather than starting a one-board schedule, which is what the
    /// single-board journey is already for.
    init?(boards: [FirstThenBoardSnapshot]) {
        guard boards.count >= FirstThenScheduleSelection.minimumBoardCount else {
            return nil
        }
        self.boards = boards
        position = .board(index: 0, phase: .first)
    }

    var boardCount: Int {
        boards.count
    }

    var isScheduleComplete: Bool {
        position == .scheduleCompleted
    }

    var currentIndex: Int? {
        switch position {
        case let .board(index, _):
            index
        case .scheduleCompleted:
            nil
        }
    }

    var currentPhase: FirstThenSchedulePhase? {
        switch position {
        case let .board(_, phase):
            phase
        case .scheduleCompleted:
            nil
        }
    }

    var currentBoard: FirstThenBoardSnapshot? {
        currentIndex.map { boards[$0] }
    }

    /// One-based position for display; nil once the schedule is complete.
    var currentPositionNumber: Int? {
        currentIndex.map { $0 + 1 }
    }

    var isFirstComplete: Bool {
        currentPhase == .then
    }

    /// Completion is derived from `position` rather than stored per board, so
    /// the two cannot disagree after Back or Start Over.
    func status(at index: Int) -> FirstThenScheduleBoardStatus {
        switch position {
        case let .board(currentIndex, _):
            if index < currentIndex {
                .completed
            } else if index == currentIndex {
                .current
            } else {
                .upcoming
            }
        case .scheduleCompleted:
            .completed
        }
    }

    var canCompleteFirst: Bool {
        currentPhase == .first
    }

    var canAdvance: Bool {
        currentPhase == .then
    }

    var canGoBack: Bool {
        switch position {
        case let .board(index, _):
            index > 0
        case .scheduleCompleted:
            true
        }
    }

    /// Marks the current board's First item complete so Then becomes current.
    /// Invalid in any other phase and leaves the session untouched.
    @discardableResult
    mutating func completeFirst() -> Bool {
        guard case let .board(index, .first) = position else {
            return false
        }
        position = .board(index: index, phase: .then)
        return true
    }

    /// Completes the current board and moves to the next one, or to the
    /// schedule-complete state after the last board.
    @discardableResult
    mutating func advance() -> Bool {
        guard case let .board(index, .then) = position else {
            return false
        }

        let nextIndex = index + 1
        position =
            nextIndex < boards.count
            ? .board(index: nextIndex, phase: .first)
            : .scheduleCompleted
        return true
    }

    /// Returns to the previous board with its Then item current. The rest of
    /// the schedule is kept; only the current position moves.
    @discardableResult
    mutating func goBack() -> Bool {
        switch position {
        case let .board(index, _):
            guard index > 0 else { return false }
            position = .board(index: index - 1, phase: .then)
            return true
        case .scheduleCompleted:
            position = .board(index: boards.count - 1, phase: .then)
            return true
        }
    }

    mutating func startOver() {
        position = .board(index: 0, phase: .first)
    }
}
