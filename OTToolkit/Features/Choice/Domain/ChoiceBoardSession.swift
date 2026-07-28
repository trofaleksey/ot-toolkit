import Foundation

struct ChoiceOptionSnapshot: Equatable, Identifiable, Sendable {
    let id: UUID
    let label: String
    let systemSymbolName: String
}

struct ChoiceBoardSnapshot: Equatable, Identifiable, Sendable {
    let id: UUID
    let name: String
    let options: [ChoiceOptionSnapshot]
}

/// Bounds a Choice Board's option count. Fewer than two is not a choice, and
/// more than six stops being scannable for a child.
enum ChoiceBoardLimits {
    static let minimumOptionCount = 2
    static let maximumOptionCount = 6

    static func allows(optionCount: Int) -> Bool {
        (minimumOptionCount...maximumOptionCount).contains(optionCount)
    }
}

/// A running Choice Board.
///
/// Holds immutable value snapshots taken when the session starts, so a
/// therapist edit cannot change what a child is currently looking at. Hiding
/// and selection are memory-only: "temporary hiding" means the saved board is
/// untouched, and process loss ends the session.
struct ChoiceBoardSession: Equatable, Sendable {
    let board: ChoiceBoardSnapshot
    private(set) var hiddenOptionIDs: Set<UUID> = []
    private(set) var selectedOptionID: UUID?

    /// Fails rather than starting a session that cannot present a real choice.
    init?(board: ChoiceBoardSnapshot) {
        guard ChoiceBoardLimits.allows(optionCount: board.options.count) else {
            return nil
        }
        self.board = board
    }

    var visibleOptions: [ChoiceOptionSnapshot] {
        board.options.filter { !hiddenOptionIDs.contains($0.id) }
    }

    var hiddenOptions: [ChoiceOptionSnapshot] {
        board.options.filter { hiddenOptionIDs.contains($0.id) }
    }

    var selectedOption: ChoiceOptionSnapshot? {
        selectedOptionID.flatMap { id in board.options.first { $0.id == id } }
    }

    var hasSelection: Bool {
        selectedOptionID != nil
    }

    func isHidden(_ optionID: UUID) -> Bool {
        hiddenOptionIDs.contains(optionID)
    }

    func isSelected(_ optionID: UUID) -> Bool {
        selectedOptionID == optionID
    }

    /// Hiding is refused when it would leave fewer than two visible options,
    /// because a board with one option no longer offers a choice.
    func canHide(_ optionID: UUID) -> Bool {
        guard board.options.contains(where: { $0.id == optionID }),
            !hiddenOptionIDs.contains(optionID)
        else {
            return false
        }
        return visibleOptions.count > ChoiceBoardLimits.minimumOptionCount
    }

    @discardableResult
    mutating func select(_ optionID: UUID) -> Bool {
        guard board.options.contains(where: { $0.id == optionID }),
            !hiddenOptionIDs.contains(optionID)
        else {
            return false
        }
        selectedOptionID = optionID
        return true
    }

    mutating func clearSelection() {
        selectedOptionID = nil
    }

    /// Hiding the selected option clears the selection: a hidden option must
    /// not stay presented as the child's choice.
    @discardableResult
    mutating func hide(_ optionID: UUID) -> Bool {
        guard canHide(optionID) else {
            return false
        }
        hiddenOptionIDs.insert(optionID)
        if selectedOptionID == optionID {
            selectedOptionID = nil
        }
        return true
    }

    @discardableResult
    mutating func show(_ optionID: UUID) -> Bool {
        guard hiddenOptionIDs.contains(optionID) else {
            return false
        }
        hiddenOptionIDs.remove(optionID)
        return true
    }

    mutating func showAllOptions() {
        hiddenOptionIDs.removeAll()
    }
}
