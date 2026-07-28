import Foundation
import XCTest

@testable import OTToolkit

final class FirstThenScheduleSelectionTests: XCTestCase {
    func testSelectionRequiresTwoBoardsBeforeItCanStart() {
        var selection = FirstThenScheduleSelection()
        let first = UUID()
        let second = UUID()

        XCTAssertFalse(selection.canStart)

        selection.toggle(first)
        XCTAssertFalse(selection.canStart)

        selection.toggle(second)
        XCTAssertTrue(selection.canStart)
    }

    func testTogglingAppendsInSelectionOrderAndRemovesWithoutDisturbingTheRest() {
        var selection = FirstThenScheduleSelection()
        let first = UUID()
        let second = UUID()
        let third = UUID()

        selection.toggle(first)
        selection.toggle(second)
        selection.toggle(third)
        XCTAssertEqual(selection.orderedBoardIDs, [first, second, third])

        selection.toggle(second)
        XCTAssertEqual(selection.orderedBoardIDs, [first, third])
        XCTAssertFalse(selection.isSelected(second))

        // Reselecting appends rather than restoring the original position.
        selection.toggle(second)
        XCTAssertEqual(selection.orderedBoardIDs, [first, third, second])
    }

    func testMovingRespectsBoundariesAndReportsWhetherItChangedAnything() {
        var selection = FirstThenScheduleSelection()
        let first = UUID()
        let second = UUID()
        let third = UUID()
        selection.toggle(first)
        selection.toggle(second)
        selection.toggle(third)

        XCTAssertFalse(selection.canMoveUp(first))
        XCTAssertFalse(selection.moveUp(first))
        XCTAssertEqual(selection.orderedBoardIDs, [first, second, third])

        XCTAssertFalse(selection.canMoveDown(third))
        XCTAssertFalse(selection.moveDown(third))
        XCTAssertEqual(selection.orderedBoardIDs, [first, second, third])

        XCTAssertTrue(selection.moveUp(third))
        XCTAssertEqual(selection.orderedBoardIDs, [first, third, second])

        XCTAssertTrue(selection.moveDown(first))
        XCTAssertEqual(selection.orderedBoardIDs, [third, first, second])
    }

    func testMovingAnUnselectedBoardIsRejected() {
        var selection = FirstThenScheduleSelection()
        let selected = UUID()
        let unselected = UUID()
        selection.toggle(selected)

        XCTAssertFalse(selection.canMoveUp(unselected))
        XCTAssertFalse(selection.canMoveDown(unselected))
        XCTAssertFalse(selection.moveUp(unselected))
        XCTAssertFalse(selection.moveDown(unselected))
        XCTAssertEqual(selection.orderedBoardIDs, [selected])
    }

    func testPositionIsOneBasedAndOnlyReportedForSelectedBoards() {
        var selection = FirstThenScheduleSelection()
        let first = UUID()
        let second = UUID()
        selection.toggle(first)
        selection.toggle(second)

        XCTAssertEqual(selection.position(of: first), 1)
        XCTAssertEqual(selection.position(of: second), 2)
        XCTAssertNil(selection.position(of: UUID()))
    }

    func testReconcilingDropsDeletedBoardsAndKeepsTheRemainingOrder() {
        var selection = FirstThenScheduleSelection()
        let first = UUID()
        let deleted = UUID()
        let third = UUID()
        selection.toggle(first)
        selection.toggle(deleted)
        selection.toggle(third)

        selection.reconcile(withAvailable: Set([first, third]))

        XCTAssertEqual(selection.orderedBoardIDs, [first, third])
        XCTAssertTrue(selection.canStart)
    }

    func testReconcilingCanLeaveTheSelectionUnableToStart() {
        var selection = FirstThenScheduleSelection()
        let kept = UUID()
        let deleted = UUID()
        selection.toggle(kept)
        selection.toggle(deleted)

        selection.reconcile(withAvailable: Set([kept]))

        XCTAssertEqual(selection.orderedBoardIDs, [kept])
        XCTAssertFalse(selection.canStart)
    }
}

final class FirstThenScheduleSessionTests: XCTestCase {
    func testSessionCannotStartWithFewerThanTwoBoards() {
        XCTAssertNil(FirstThenScheduleSession(boards: []))
        XCTAssertNil(FirstThenScheduleSession(boards: [makeBoard(name: "Only")]))
        XCTAssertNotNil(FirstThenScheduleSession(boards: makeBoards(count: 2)))
    }

    func testSessionStartsOnTheFirstBoardsFirstItem() throws {
        let session = try makeSession(count: 3)

        XCTAssertEqual(session.position, .board(index: 0, phase: .first))
        XCTAssertEqual(session.currentBoard, session.boards[0])
        XCTAssertEqual(session.currentPositionNumber, 1)
        XCTAssertEqual(session.boardCount, 3)
        XCTAssertFalse(session.isFirstComplete)
        XCTAssertFalse(session.isScheduleComplete)
    }

    func testCompletingFirstMakesThenCurrentOnTheSameBoard() throws {
        var session = try makeSession(count: 2)

        XCTAssertTrue(session.completeFirst())

        XCTAssertEqual(session.position, .board(index: 0, phase: .then))
        XCTAssertTrue(session.isFirstComplete)
        XCTAssertEqual(session.currentBoard, session.boards[0])
    }

    func testAdvancingMovesToTheNextBoardAndThenToScheduleCompletion() throws {
        var session = try makeSession(count: 2)

        session.completeFirst()
        XCTAssertTrue(session.advance())
        XCTAssertEqual(session.position, .board(index: 1, phase: .first))
        XCTAssertEqual(session.status(at: 0), .completed)
        XCTAssertEqual(session.status(at: 1), .current)

        session.completeFirst()
        XCTAssertTrue(session.advance())
        XCTAssertEqual(session.position, .scheduleCompleted)
        XCTAssertTrue(session.isScheduleComplete)
        XCTAssertNil(session.currentBoard)
        XCTAssertNil(session.currentPositionNumber)
        XCTAssertEqual(session.status(at: 0), .completed)
        XCTAssertEqual(session.status(at: 1), .completed)
    }

    func testInvalidTransitionsLeaveTheSessionUnchanged() throws {
        var session = try makeSession(count: 2)
        let initial = session

        // Advancing before First is complete is not a valid transition.
        XCTAssertFalse(session.advance())
        XCTAssertEqual(session, initial)

        // Back from the very first board is not a valid transition.
        XCTAssertFalse(session.goBack())
        XCTAssertEqual(session, initial)

        session.completeFirst()
        let afterFirst = session

        // Completing First twice must not advance the board.
        XCTAssertFalse(session.completeFirst())
        XCTAssertEqual(session, afterFirst)

        session.advance()
        session.completeFirst()
        session.advance()
        let completed = session

        XCTAssertFalse(session.completeFirst())
        XCTAssertFalse(session.advance())
        XCTAssertEqual(session, completed)
    }

    func testBackReturnsToThePreviousBoardWithThenCurrentAndKeepsTheRest() throws {
        var session = try makeSession(count: 3)

        session.completeFirst()
        session.advance()
        XCTAssertEqual(session.position, .board(index: 1, phase: .first))

        XCTAssertTrue(session.goBack())

        XCTAssertEqual(session.position, .board(index: 0, phase: .then))
        XCTAssertEqual(session.boardCount, 3, "Back must not discard the rest of the schedule.")
        XCTAssertEqual(session.status(at: 2), .upcoming)
    }

    func testBackFromScheduleCompletionReturnsToTheLastBoard() throws {
        var session = try makeSession(count: 2)
        session.completeFirst()
        session.advance()
        session.completeFirst()
        session.advance()
        XCTAssertTrue(session.isScheduleComplete)

        XCTAssertTrue(session.goBack())

        XCTAssertEqual(session.position, .board(index: 1, phase: .then))
        XCTAssertEqual(session.status(at: 1), .current)
    }

    func testStartOverReturnsEveryBoardToItsInitialPhase() throws {
        var session = try makeSession(count: 3)
        session.completeFirst()
        session.advance()
        session.completeFirst()

        session.startOver()

        XCTAssertEqual(session.position, .board(index: 0, phase: .first))
        XCTAssertFalse(session.isFirstComplete)
        XCTAssertEqual(session.status(at: 0), .current)
        XCTAssertEqual(session.status(at: 1), .upcoming)
        XCTAssertEqual(session.status(at: 2), .upcoming)
    }

    func testCapabilityFlagsMatchTheAllowedTransitions() throws {
        var session = try makeSession(count: 2)

        XCTAssertTrue(session.canCompleteFirst)
        XCTAssertFalse(session.canAdvance)
        XCTAssertFalse(session.canGoBack)

        session.completeFirst()
        XCTAssertFalse(session.canCompleteFirst)
        XCTAssertTrue(session.canAdvance)

        session.advance()
        XCTAssertTrue(session.canGoBack)
    }

    func testSessionKeepsValueSnapshotsTakenAtLaunch() throws {
        var boards = makeBoards(count: 2)
        let session = try XCTUnwrap(FirstThenScheduleSession(boards: boards))

        // Mutating the source array cannot reach the running schedule.
        boards[0] = makeBoard(name: "Renamed after launch")

        XCTAssertNotEqual(session.boards[0], boards[0])
        XCTAssertEqual(session.boards[0].name, "Board 1")
    }

    // MARK: - Fixtures

    private func makeSession(count: Int) throws -> FirstThenScheduleSession {
        try XCTUnwrap(FirstThenScheduleSession(boards: makeBoards(count: count)))
    }

    private func makeBoards(count: Int) -> [FirstThenBoardSnapshot] {
        (1...count).map { makeBoard(name: "Board \($0)") }
    }

    private func makeBoard(name: String) -> FirstThenBoardSnapshot {
        FirstThenBoardSnapshot(
            id: UUID(),
            name: name,
            first: FirstThenItemSnapshot(label: "Sorting", systemSymbolName: "figure.walk"),
            then: FirstThenItemSnapshot(label: "Reading", systemSymbolName: "book.closed")
        )
    }
}
