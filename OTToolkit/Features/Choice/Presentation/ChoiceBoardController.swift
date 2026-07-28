import Foundation
import Observation

enum ChoiceBoardOperation: Equatable, Identifiable, Sendable {
    case load
    case create
    case update
    case duplicate
    case delete

    var id: Self { self }
}

extension ChoiceBoardSnapshot {
    var draft: ChoiceBoardDraft {
        ChoiceBoardDraft(
            name: name,
            options: options.map {
                ChoiceOptionDraft(label: $0.label, systemSymbolName: $0.systemSymbolName)
            }
        )
    }
}

@MainActor
@Observable
final class ChoiceBoardController {
    private let store: any ChoiceBoardStoring
    private var modelsByID: [UUID: ChoiceBoard] = [:]

    private(set) var boards: [ChoiceBoardSnapshot] = []
    private(set) var failure: ChoiceBoardOperation?

    init(store: any ChoiceBoardStoring) {
        self.store = store
        reload()
    }

    func board(id: UUID) -> ChoiceBoardSnapshot? {
        boards.first { $0.id == id }
    }

    @discardableResult
    func reload() -> Bool {
        do {
            let models = try store.fetchBoards()
            let snapshots = try models.map(makeSnapshot)
            modelsByID = Dictionary(uniqueKeysWithValues: models.map { ($0.id, $0) })
            boards = snapshots
            failure = nil
            return true
        } catch {
            failure = .load
            return false
        }
    }

    @discardableResult
    func create(_ draft: ChoiceBoardDraft) -> Bool {
        do {
            _ = try store.create(draft)
            return reload()
        } catch {
            failure = .create
            return false
        }
    }

    @discardableResult
    func update(id: UUID, with draft: ChoiceBoardDraft) -> Bool {
        guard let board = modelsByID[id] else {
            failure = .update
            return false
        }

        do {
            try store.update(board, with: draft)
            return reload()
        } catch {
            failure = .update
            return false
        }
    }

    /// The duplicate's name is supplied by the caller so the localized copy
    /// wording stays in the presentation layer rather than the store.
    @discardableResult
    func duplicate(id: UUID, named name: String) -> Bool {
        guard let board = modelsByID[id] else {
            failure = .duplicate
            return false
        }

        do {
            _ = try store.duplicate(board, named: name)
            return reload()
        } catch {
            failure = .duplicate
            return false
        }
    }

    @discardableResult
    func delete(id: UUID) -> Bool {
        guard let board = modelsByID[id] else {
            failure = .delete
            return false
        }

        do {
            try store.delete(board)
            return reload()
        } catch {
            failure = .delete
            return false
        }
    }

    func dismissFailure() {
        failure = nil
    }

    private func makeSnapshot(from board: ChoiceBoard) throws -> ChoiceBoardSnapshot {
        let options = board.options.sorted { lhs, rhs in
            if lhs.sortIndex == rhs.sortIndex {
                return lhs.createdAt < rhs.createdAt
            }
            return lhs.sortIndex < rhs.sortIndex
        }

        guard ChoiceBoardLimits.allows(optionCount: options.count),
            Set(options.map(\.id)).count == options.count
        else {
            throw ChoiceBoardValidationError.invalidPersistedOptions
        }

        return ChoiceBoardSnapshot(
            id: board.id,
            name: board.name,
            options: options.map {
                ChoiceOptionSnapshot(
                    id: $0.id,
                    label: $0.label,
                    systemSymbolName: $0.systemSymbolName
                )
            }
        )
    }
}

/// Holds the running session for each board. Sessions are memory-only, so
/// hiding and selection never reach the store and end with the process.
@MainActor
@Observable
final class ChoiceBoardSessionController {
    private var sessionsByBoardID: [UUID: ChoiceBoardSession] = [:]

    @discardableResult
    func start(board: ChoiceBoardSnapshot) -> Bool {
        guard let session = ChoiceBoardSession(board: board) else {
            return false
        }
        sessionsByBoardID[board.id] = session
        return true
    }

    func session(for boardID: UUID) -> ChoiceBoardSession? {
        sessionsByBoardID[boardID]
    }

    /// Restarts the session when the saved board changed underneath it, so a
    /// stale snapshot is never presented after an edit.
    func synchronize(with board: ChoiceBoardSnapshot) {
        guard let session = sessionsByBoardID[board.id] else { return }
        if session.board != board {
            start(board: board)
        }
    }

    @discardableResult
    func select(optionID: UUID, boardID: UUID) -> Bool {
        mutate(boardID) { $0.select(optionID) }
    }

    @discardableResult
    func clearSelection(boardID: UUID) -> Bool {
        mutate(boardID) {
            $0.clearSelection()
            return true
        }
    }

    @discardableResult
    func hide(optionID: UUID, boardID: UUID) -> Bool {
        mutate(boardID) { $0.hide(optionID) }
    }

    @discardableResult
    func show(optionID: UUID, boardID: UUID) -> Bool {
        mutate(boardID) { $0.show(optionID) }
    }

    @discardableResult
    func showAllOptions(boardID: UUID) -> Bool {
        mutate(boardID) {
            $0.showAllOptions()
            return true
        }
    }

    func discardSession(boardID: UUID) {
        sessionsByBoardID[boardID] = nil
    }

    private func mutate(
        _ boardID: UUID,
        _ change: (inout ChoiceBoardSession) -> Bool
    ) -> Bool {
        guard var session = sessionsByBoardID[boardID] else { return false }
        let didChange = change(&session)
        if didChange {
            sessionsByBoardID[boardID] = session
        }
        return didChange
    }
}
