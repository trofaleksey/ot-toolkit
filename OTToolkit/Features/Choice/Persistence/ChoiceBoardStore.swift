import Foundation
import SwiftData

struct ChoiceOptionDraft: Equatable, Sendable {
    let label: String
    let systemSymbolName: String
}

struct ChoiceBoardDraft: Equatable, Sendable {
    let name: String
    let options: [ChoiceOptionDraft]
}

enum ChoiceBoardValidationError: Error, Equatable {
    case emptyBoardName
    case emptyOptionLabel
    case emptyOptionSymbolName
    case invalidOptionCount
    case invalidBoardOrder
    case invalidOptionOrder
    case invalidPersistedOptions
}

@MainActor
protocol ChoiceBoardStoring {
    func create(_ draft: ChoiceBoardDraft) throws -> ChoiceBoard
    func fetchBoards() throws -> [ChoiceBoard]
    func update(_ board: ChoiceBoard, with draft: ChoiceBoardDraft) throws
    func duplicate(_ board: ChoiceBoard, named name: String) throws -> ChoiceBoard
    func delete(_ board: ChoiceBoard) throws
}

@MainActor
struct ChoiceBoardStore {
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
        _ draft: ChoiceBoardDraft,
        boardID: UUID = UUID(),
        optionIDs: [UUID]? = nil
    ) throws -> ChoiceBoard {
        let validated = try validate(draft)
        if let optionIDs, optionIDs.count != validated.options.count {
            throw ChoiceBoardValidationError.invalidOptionCount
        }

        let timestamp = now()
        let board = ChoiceBoard(
            id: boardID,
            name: validated.name,
            sortIndex: try nextBoardSortIndex(),
            createdAt: timestamp,
            updatedAt: timestamp,
            options: makeOptions(
                from: validated.options,
                optionIDs: optionIDs,
                timestamp: timestamp
            )
        )

        modelContext.insert(board)
        try saveOrRollback()
        return board
    }

    func fetchBoards() throws -> [ChoiceBoard] {
        try modelContext.fetch(
            FetchDescriptor<ChoiceBoard>(
                sortBy: [
                    SortDescriptor(\ChoiceBoard.sortIndex),
                    SortDescriptor(\ChoiceBoard.createdAt),
                ]
            )
        )
    }

    /// Replaces the board's options wholesale. Option identity is not stable
    /// across an edit, which is intentional: nothing references an option by
    /// id except the in-memory session, and a session snapshots its options at
    /// launch rather than tracking the live models.
    func update(_ board: ChoiceBoard, with draft: ChoiceBoardDraft) throws {
        let validated = try validate(draft)
        let timestamp = now()

        for option in board.options {
            modelContext.delete(option)
        }
        board.options = makeOptions(
            from: validated.options,
            optionIDs: nil,
            timestamp: timestamp
        )
        for option in board.options {
            option.board = board
        }
        board.name = validated.name
        board.updatedAt = timestamp

        try saveOrRollback()
    }

    func duplicate(
        _ board: ChoiceBoard,
        named name: String,
        boardID: UUID = UUID()
    ) throws -> ChoiceBoard {
        let draft = ChoiceBoardDraft(
            name: name,
            options: try sortedOptions(of: board).map {
                ChoiceOptionDraft(label: $0.label, systemSymbolName: $0.systemSymbolName)
            }
        )
        return try create(draft, boardID: boardID)
    }

    func reorder(boardIDs: [UUID]) throws {
        let boards = try fetchBoards()
        guard boardIDs.count == boards.count,
            Set(boardIDs).count == boardIDs.count,
            Set(boardIDs) == Set(boards.map(\.id))
        else {
            throw ChoiceBoardValidationError.invalidBoardOrder
        }

        let timestamp = now()
        let boardsByID = Dictionary(uniqueKeysWithValues: boards.map { ($0.id, $0) })
        for (sortIndex, id) in boardIDs.enumerated() {
            guard let board = boardsByID[id] else {
                throw ChoiceBoardValidationError.invalidBoardOrder
            }
            board.sortIndex = sortIndex
            board.updatedAt = timestamp
        }

        try saveOrRollback()
    }

    func reorderOptions(of board: ChoiceBoard, to optionIDs: [UUID]) throws {
        let options = try sortedOptions(of: board)
        guard optionIDs.count == options.count,
            Set(optionIDs).count == optionIDs.count,
            Set(optionIDs) == Set(options.map(\.id))
        else {
            throw ChoiceBoardValidationError.invalidOptionOrder
        }

        let timestamp = now()
        let optionsByID = Dictionary(uniqueKeysWithValues: options.map { ($0.id, $0) })
        for (sortIndex, id) in optionIDs.enumerated() {
            guard let option = optionsByID[id] else {
                throw ChoiceBoardValidationError.invalidOptionOrder
            }
            option.sortIndex = sortIndex
            option.updatedAt = timestamp
        }
        board.updatedAt = timestamp

        try saveOrRollback()
    }

    func delete(_ board: ChoiceBoard) throws {
        modelContext.delete(board)
        try saveOrRollback()
    }

    /// Options in presentation order. Throws rather than silently presenting a
    /// board whose stored options fall outside the supported range.
    func sortedOptions(of board: ChoiceBoard) throws -> [ChoiceOption] {
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

        return options
    }

    private func makeOptions(
        from drafts: [ChoiceOptionDraft],
        optionIDs: [UUID]?,
        timestamp: Date
    ) -> [ChoiceOption] {
        drafts.enumerated().map { index, draft in
            ChoiceOption(
                id: optionIDs?[index] ?? UUID(),
                label: draft.label,
                systemSymbolName: draft.systemSymbolName,
                sortIndex: index,
                createdAt: timestamp,
                updatedAt: timestamp
            )
        }
    }

    private func validate(_ draft: ChoiceBoardDraft) throws -> ChoiceBoardDraft {
        let name = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            throw ChoiceBoardValidationError.emptyBoardName
        }

        guard ChoiceBoardLimits.allows(optionCount: draft.options.count) else {
            throw ChoiceBoardValidationError.invalidOptionCount
        }

        let options = try draft.options.map { option in
            let label = option.label.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !label.isEmpty else {
                throw ChoiceBoardValidationError.emptyOptionLabel
            }

            let symbolName = option.systemSymbolName.trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            guard !symbolName.isEmpty else {
                throw ChoiceBoardValidationError.emptyOptionSymbolName
            }

            return ChoiceOptionDraft(label: label, systemSymbolName: symbolName)
        }

        return ChoiceBoardDraft(name: name, options: options)
    }

    private func nextBoardSortIndex() throws -> Int {
        var descriptor = FetchDescriptor<ChoiceBoard>(
            sortBy: [SortDescriptor(\ChoiceBoard.sortIndex, order: .reverse)]
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

extension ChoiceBoardStore: ChoiceBoardStoring {
    func create(_ draft: ChoiceBoardDraft) throws -> ChoiceBoard {
        try create(draft, boardID: UUID(), optionIDs: nil)
    }

    func duplicate(_ board: ChoiceBoard, named name: String) throws -> ChoiceBoard {
        try duplicate(board, named: name, boardID: UUID())
    }
}
