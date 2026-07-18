import Foundation
import SwiftData

struct FirstThenItemDraft: Equatable, Sendable {
    let label: String
    let systemSymbolName: String
}

struct FirstThenBoardDraft: Equatable, Sendable {
    let name: String
    let first: FirstThenItemDraft
    let then: FirstThenItemDraft
}

enum FirstThenBoardValidationError: Error, Equatable {
    case emptyBoardName
    case emptyLabel(FirstThenItemRole)
    case emptySystemSymbolName(FirstThenItemRole)
    case invalidPersistedItems
    case invalidBoardOrder
}

@MainActor
struct FirstThenBoardStore {
    typealias Now = @MainActor () -> Date

    private let modelContext: ModelContext
    private let now: Now

    init(
        modelContext: ModelContext,
        now: @escaping Now = { Date() }
    ) {
        self.modelContext = modelContext
        self.now = now
    }

    func create(
        _ draft: FirstThenBoardDraft,
        boardID: UUID = UUID(),
        firstItemID: UUID = UUID(),
        thenItemID: UUID = UUID()
    ) throws -> FirstThenBoard {
        let validated = try validate(draft)
        let timestamp = now()
        let board = FirstThenBoard(
            id: boardID,
            name: validated.name,
            sortIndex: try nextBoardSortIndex(),
            createdAt: timestamp,
            updatedAt: timestamp,
            items: [
                FirstThenItem(
                    id: firstItemID,
                    role: .first,
                    label: validated.first.label,
                    systemSymbolName: validated.first.systemSymbolName,
                    sortIndex: FirstThenItemRole.first.sortIndex,
                    createdAt: timestamp,
                    updatedAt: timestamp
                ),
                FirstThenItem(
                    id: thenItemID,
                    role: .then,
                    label: validated.then.label,
                    systemSymbolName: validated.then.systemSymbolName,
                    sortIndex: FirstThenItemRole.then.sortIndex,
                    createdAt: timestamp,
                    updatedAt: timestamp
                ),
            ]
        )

        modelContext.insert(board)
        try saveOrRollback()
        return board
    }

    func fetchBoards() throws -> [FirstThenBoard] {
        try modelContext.fetch(
            FetchDescriptor<FirstThenBoard>(
                sortBy: [
                    SortDescriptor(\FirstThenBoard.sortIndex),
                    SortDescriptor(\FirstThenBoard.createdAt),
                ]
            )
        )
    }

    func update(_ board: FirstThenBoard, with draft: FirstThenBoardDraft) throws {
        let validated = try validate(draft)
        let itemsByRole = try validatedItemsByRole(in: board)
        guard let firstItem = itemsByRole[.first],
            let thenItem = itemsByRole[.then]
        else {
            throw FirstThenBoardValidationError.invalidPersistedItems
        }
        let timestamp = now()

        board.name = validated.name
        board.updatedAt = timestamp
        update(
            firstItem,
            with: validated.first,
            role: .first,
            timestamp: timestamp
        )
        update(
            thenItem,
            with: validated.then,
            role: .then,
            timestamp: timestamp
        )

        try saveOrRollback()
    }

    func reorder(boardIDs: [UUID]) throws {
        let boards = try fetchBoards()
        guard boardIDs.count == boards.count,
            Set(boardIDs).count == boardIDs.count,
            Set(boardIDs) == Set(boards.map(\.id))
        else {
            throw FirstThenBoardValidationError.invalidBoardOrder
        }

        let timestamp = now()
        let boardsByID = Dictionary(uniqueKeysWithValues: boards.map { ($0.id, $0) })
        for (sortIndex, id) in boardIDs.enumerated() {
            guard let board = boardsByID[id] else {
                throw FirstThenBoardValidationError.invalidBoardOrder
            }
            board.sortIndex = sortIndex
            board.updatedAt = timestamp
        }

        try saveOrRollback()
    }

    func delete(_ board: FirstThenBoard) throws {
        modelContext.delete(board)
        try saveOrRollback()
    }

    private func validate(_ draft: FirstThenBoardDraft) throws -> FirstThenBoardDraft {
        let name = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            throw FirstThenBoardValidationError.emptyBoardName
        }

        return FirstThenBoardDraft(
            name: name,
            first: try validate(draft.first, role: .first),
            then: try validate(draft.then, role: .then)
        )
    }

    private func validate(
        _ draft: FirstThenItemDraft,
        role: FirstThenItemRole
    ) throws -> FirstThenItemDraft {
        let label = draft.label.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !label.isEmpty else {
            throw FirstThenBoardValidationError.emptyLabel(role)
        }

        let systemSymbolName = draft.systemSymbolName.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        guard !systemSymbolName.isEmpty else {
            throw FirstThenBoardValidationError.emptySystemSymbolName(role)
        }

        return FirstThenItemDraft(
            label: label,
            systemSymbolName: systemSymbolName
        )
    }

    private func validatedItemsByRole(
        in board: FirstThenBoard
    ) throws -> [FirstThenItemRole: FirstThenItem] {
        guard board.items.count == FirstThenItemRole.allCases.count else {
            throw FirstThenBoardValidationError.invalidPersistedItems
        }

        var itemsByRole: [FirstThenItemRole: FirstThenItem] = [:]
        for item in board.items {
            guard let role = item.role, itemsByRole[role] == nil else {
                throw FirstThenBoardValidationError.invalidPersistedItems
            }
            itemsByRole[role] = item
        }

        guard itemsByRole.count == FirstThenItemRole.allCases.count else {
            throw FirstThenBoardValidationError.invalidPersistedItems
        }
        return itemsByRole
    }

    private func update(
        _ item: FirstThenItem,
        with draft: FirstThenItemDraft,
        role: FirstThenItemRole,
        timestamp: Date
    ) {
        item.roleRawValue = role.rawValue
        item.label = draft.label
        item.systemSymbolName = draft.systemSymbolName
        item.sortIndex = role.sortIndex
        item.updatedAt = timestamp
    }

    private func nextBoardSortIndex() throws -> Int {
        var descriptor = FetchDescriptor<FirstThenBoard>(
            sortBy: [SortDescriptor(\FirstThenBoard.sortIndex, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        guard let highestSortIndex = try modelContext.fetch(descriptor).first?.sortIndex else {
            return 0
        }
        return highestSortIndex + 1
    }

    private func saveOrRollback() throws {
        do {
            try modelContext.save()
        } catch {
            modelContext.rollback()
            throw error
        }
    }
}
