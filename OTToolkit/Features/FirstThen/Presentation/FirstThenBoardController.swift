import Foundation
import Observation

enum FirstThenBoardSessionPhase: Equatable, Sendable {
    case first
    case then
}

struct FirstThenBoardSession: Equatable, Sendable {
    private(set) var phase = FirstThenBoardSessionPhase.first

    var isFirstComplete: Bool {
        phase == .then
    }

    mutating func completeFirst() {
        phase = .then
    }
}

@MainActor
@Observable
final class FirstThenBoardSessionController {
    private var sessionsByBoardID: [UUID: FirstThenBoardSession] = [:]

    func start(boardID: UUID) {
        sessionsByBoardID[boardID] = FirstThenBoardSession()
    }

    func session(for boardID: UUID) -> FirstThenBoardSession {
        sessionsByBoardID[boardID] ?? FirstThenBoardSession()
    }

    func completeFirst(boardID: UUID) {
        var session = session(for: boardID)
        session.completeFirst()
        sessionsByBoardID[boardID] = session
    }

    func discardSession(boardID: UUID) {
        sessionsByBoardID[boardID] = nil
    }
}

struct FirstThenItemSnapshot: Equatable, Sendable {
    let label: String
    let systemSymbolName: String
}

struct FirstThenBoardSnapshot: Equatable, Identifiable, Sendable {
    let id: UUID
    let name: String
    let first: FirstThenItemSnapshot
    let then: FirstThenItemSnapshot

    var draft: FirstThenBoardDraft {
        FirstThenBoardDraft(
            name: name,
            first: FirstThenItemDraft(
                label: first.label,
                systemSymbolName: first.systemSymbolName
            ),
            then: FirstThenItemDraft(
                label: then.label,
                systemSymbolName: then.systemSymbolName
            )
        )
    }
}

enum FirstThenBoardOperation: Equatable, Identifiable, Sendable {
    case load
    case create
    case update
    case delete

    var id: Self { self }
}

@MainActor
@Observable
final class FirstThenBoardController {
    private let store: any FirstThenBoardStoring
    private var modelsByID: [UUID: FirstThenBoard] = [:]

    private(set) var boards: [FirstThenBoardSnapshot] = []
    private(set) var failure: FirstThenBoardOperation?

    init(store: any FirstThenBoardStoring) {
        self.store = store
        reload()
    }

    func board(id: UUID) -> FirstThenBoardSnapshot? {
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
    func create(_ draft: FirstThenBoardDraft) -> Bool {
        do {
            _ = try store.create(draft)
            guard reload() else { return false }
            return true
        } catch {
            failure = .create
            return false
        }
    }

    @discardableResult
    func update(id: UUID, with draft: FirstThenBoardDraft) -> Bool {
        guard let board = modelsByID[id] else {
            failure = .update
            return false
        }

        do {
            try store.update(board, with: draft)
            guard reload() else { return false }
            return true
        } catch {
            failure = .update
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
            guard reload() else { return false }
            return true
        } catch {
            failure = .delete
            return false
        }
    }

    func dismissFailure() {
        failure = nil
    }

    private func makeSnapshot(from board: FirstThenBoard) throws -> FirstThenBoardSnapshot {
        var itemsByRole: [FirstThenItemRole: FirstThenItem] = [:]
        for item in board.items {
            guard let role = item.role, itemsByRole[role] == nil else {
                throw FirstThenBoardValidationError.invalidPersistedItems
            }
            itemsByRole[role] = item
        }

        guard let first = itemsByRole[.first],
            let then = itemsByRole[.then],
            itemsByRole.count == FirstThenItemRole.allCases.count
        else {
            throw FirstThenBoardValidationError.invalidPersistedItems
        }

        return FirstThenBoardSnapshot(
            id: board.id,
            name: board.name,
            first: FirstThenItemSnapshot(
                label: first.label,
                systemSymbolName: first.systemSymbolName
            ),
            then: FirstThenItemSnapshot(
                label: then.label,
                systemSymbolName: then.systemSymbolName
            )
        )
    }
}
