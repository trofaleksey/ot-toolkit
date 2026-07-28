import Foundation
import XCTest

@testable import OTToolkit

final class ChoiceBoardSessionTests: XCTestCase {
    func testOptionCountLimitsMatchTheProductRange() {
        XCTAssertFalse(ChoiceBoardLimits.allows(optionCount: 1))
        XCTAssertTrue(ChoiceBoardLimits.allows(optionCount: 2))
        XCTAssertTrue(ChoiceBoardLimits.allows(optionCount: 6))
        XCTAssertFalse(ChoiceBoardLimits.allows(optionCount: 7))
    }

    func testSessionRefusesBoardsOutsideTheSupportedOptionRange() {
        XCTAssertNil(ChoiceBoardSession(board: makeBoard(optionCount: 1)))
        XCTAssertNil(ChoiceBoardSession(board: makeBoard(optionCount: 7)))
        XCTAssertNotNil(ChoiceBoardSession(board: makeBoard(optionCount: 2)))
        XCTAssertNotNil(ChoiceBoardSession(board: makeBoard(optionCount: 6)))
    }

    func testSessionStartsWithEverythingVisibleAndNothingSelected() throws {
        let session = try makeSession(optionCount: 4)

        XCTAssertEqual(session.visibleOptions.count, 4)
        XCTAssertTrue(session.hiddenOptions.isEmpty)
        XCTAssertNil(session.selectedOption)
        XCTAssertFalse(session.hasSelection)
    }

    func testSelectingMarksExactlyOneOption() throws {
        var session = try makeSession(optionCount: 3)
        let first = session.board.options[0].id
        let second = session.board.options[1].id

        XCTAssertTrue(session.select(first))
        XCTAssertTrue(session.isSelected(first))
        XCTAssertEqual(session.selectedOption?.id, first)

        XCTAssertTrue(session.select(second))
        XCTAssertFalse(session.isSelected(first))
        XCTAssertTrue(session.isSelected(second))
    }

    func testSelectingAnUnknownOptionIsRejected() throws {
        var session = try makeSession(optionCount: 3)
        let initial = session

        XCTAssertFalse(session.select(UUID()))
        XCTAssertEqual(session, initial)
    }

    func testClearingSelectionLeavesVisibilityUntouched() throws {
        var session = try makeSession(optionCount: 3)
        session.hide(session.board.options[2].id)
        session.select(session.board.options[0].id)

        session.clearSelection()

        XCTAssertFalse(session.hasSelection)
        XCTAssertEqual(session.visibleOptions.count, 2)
    }

    func testHidingRemovesAnOptionFromViewWithoutTouchingTheBoard() throws {
        var session = try makeSession(optionCount: 4)
        let hidden = session.board.options[1].id

        XCTAssertTrue(session.hide(hidden))

        XCTAssertTrue(session.isHidden(hidden))
        XCTAssertEqual(session.visibleOptions.count, 3)
        XCTAssertEqual(session.hiddenOptions.map(\.id), [hidden])
        XCTAssertEqual(
            session.board.options.count, 4,
            "Temporary hiding must not change the board itself."
        )
    }

    func testHidingIsRefusedWhenItWouldLeaveFewerThanTwoChoices() throws {
        var session = try makeSession(optionCount: 3)
        XCTAssertTrue(session.hide(session.board.options[0].id))

        // Two options remain; hiding another would stop this being a choice.
        let remaining = session.board.options[1].id
        XCTAssertFalse(session.canHide(remaining))
        XCTAssertFalse(session.hide(remaining))
        XCTAssertEqual(session.visibleOptions.count, 2)
    }

    func testHidingTheSelectedOptionClearsTheSelection() throws {
        var session = try makeSession(optionCount: 4)
        let selected = session.board.options[0].id
        session.select(selected)

        XCTAssertTrue(session.hide(selected))

        XCTAssertFalse(session.hasSelection)
        XCTAssertNil(session.selectedOption)
    }

    func testHidingAnOptionTwiceOrAnUnknownOptionIsRejected() throws {
        var session = try makeSession(optionCount: 4)
        let hidden = session.board.options[0].id
        XCTAssertTrue(session.hide(hidden))
        let afterHide = session

        XCTAssertFalse(session.hide(hidden))
        XCTAssertFalse(session.hide(UUID()))
        XCTAssertEqual(session, afterHide)
    }

    func testAHiddenOptionCannotBeSelected() throws {
        var session = try makeSession(optionCount: 4)
        let hidden = session.board.options[0].id
        session.hide(hidden)

        XCTAssertFalse(session.select(hidden))
        XCTAssertFalse(session.hasSelection)
    }

    func testShowingRestoresAnOptionAndRejectsVisibleOnes() throws {
        var session = try makeSession(optionCount: 4)
        let hidden = session.board.options[0].id
        session.hide(hidden)

        XCTAssertTrue(session.show(hidden))
        XCTAssertFalse(session.isHidden(hidden))
        XCTAssertEqual(session.visibleOptions.count, 4)

        XCTAssertFalse(session.show(hidden), "Showing a visible option is not a transition.")
    }

    func testShowAllRestoresEveryHiddenOptionAndKeepsSelection() throws {
        var session = try makeSession(optionCount: 5)
        session.hide(session.board.options[0].id)
        session.hide(session.board.options[1].id)
        let selected = session.board.options[4].id
        session.select(selected)

        session.showAllOptions()

        XCTAssertEqual(session.visibleOptions.count, 5)
        XCTAssertTrue(session.hiddenOptions.isEmpty)
        XCTAssertTrue(session.isSelected(selected))
    }

    func testVisibleOptionsPreserveBoardOrder() throws {
        var session = try makeSession(optionCount: 5)
        session.hide(session.board.options[2].id)

        XCTAssertEqual(
            session.visibleOptions.map(\.label),
            ["Option 1", "Option 2", "Option 4", "Option 5"]
        )
    }

    // MARK: - Fixtures

    private func makeSession(optionCount: Int) throws -> ChoiceBoardSession {
        try XCTUnwrap(ChoiceBoardSession(board: makeBoard(optionCount: optionCount)))
    }

    private func makeBoard(optionCount: Int) -> ChoiceBoardSnapshot {
        ChoiceBoardSnapshot(
            id: UUID(),
            name: "Break choices",
            options: (1...optionCount).map { index in
                ChoiceOptionSnapshot(
                    id: UUID(),
                    label: "Option \(index)",
                    systemSymbolName: "puzzlepiece"
                )
            }
        )
    }
}
