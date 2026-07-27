import Foundation
import XCTest

@testable import OTToolkit

@MainActor
final class FirstThenScheduleControllerTests: XCTestCase {
    func testStartingRequiresTwoSelectedBoards() {
        let controller = FirstThenScheduleController()
        let boards = makeBoards(count: 3)

        XCTAssertFalse(controller.start(availableBoards: boards))
        XCTAssertNil(controller.session)

        controller.toggleSelection(boards[0].id)
        XCTAssertFalse(controller.start(availableBoards: boards))
        XCTAssertNil(controller.session)

        controller.toggleSelection(boards[1].id)
        XCTAssertTrue(controller.start(availableBoards: boards))
        XCTAssertNotNil(controller.session)
        XCTAssertTrue(controller.isScheduleActive)
    }

    func testScheduleLaunchesInSelectionOrderNotSavedBoardOrder() throws {
        let controller = FirstThenScheduleController()
        let boards = makeBoards(count: 3)

        controller.toggleSelection(boards[2].id)
        controller.toggleSelection(boards[0].id)
        XCTAssertTrue(controller.start(availableBoards: boards))

        let session = try XCTUnwrap(controller.session)
        XCTAssertEqual(session.boards.map(\.id), [boards[2].id, boards[0].id])
    }

    func testReorderingBeforeLaunchDeterminesTheScheduleOrder() throws {
        let controller = FirstThenScheduleController()
        let boards = makeBoards(count: 3)

        controller.toggleSelection(boards[0].id)
        controller.toggleSelection(boards[1].id)
        controller.toggleSelection(boards[2].id)
        XCTAssertTrue(controller.moveSelectionDown(boards[0].id))
        XCTAssertTrue(controller.moveSelectionUp(boards[2].id))

        XCTAssertTrue(controller.start(availableBoards: boards))

        let session = try XCTUnwrap(controller.session)
        XCTAssertEqual(session.boards.map(\.id), [boards[1].id, boards[2].id, boards[0].id])
    }

    func testStartingDropsABoardDeletedAfterSelection() throws {
        let controller = FirstThenScheduleController()
        let boards = makeBoards(count: 3)

        controller.toggleSelection(boards[0].id)
        controller.toggleSelection(boards[1].id)
        controller.toggleSelection(boards[2].id)

        // The therapist deletes one board before launching.
        let remaining = [boards[0], boards[2]]
        XCTAssertTrue(controller.start(availableBoards: remaining))

        let session = try XCTUnwrap(controller.session)
        XCTAssertEqual(session.boards.map(\.id), [boards[0].id, boards[2].id])
    }

    func testStartingIsRefusedWhenDeletionsLeaveFewerThanTwoBoards() {
        let controller = FirstThenScheduleController()
        let boards = makeBoards(count: 3)

        controller.toggleSelection(boards[0].id)
        controller.toggleSelection(boards[1].id)

        XCTAssertFalse(controller.start(availableBoards: [boards[0]]))
        XCTAssertNil(controller.session, "A stale selection must not launch a partial schedule.")
        XCTAssertEqual(controller.selection.orderedBoardIDs, [boards[0].id])
    }

    func testReconcilingRemovesDeletedBoardsFromAPendingSelection() {
        let controller = FirstThenScheduleController()
        let boards = makeBoards(count: 3)

        controller.toggleSelection(boards[0].id)
        controller.toggleSelection(boards[1].id)
        controller.reconcileSelection(withAvailable: [boards[0], boards[2]])

        XCTAssertEqual(controller.selection.orderedBoardIDs, [boards[0].id])
        XCTAssertFalse(controller.selection.canStart)
    }

    func testEditingABoardAfterLaunchDoesNotMutateTheRunningSchedule() throws {
        let controller = FirstThenScheduleController()
        let boards = makeBoards(count: 2)
        controller.toggleSelection(boards[0].id)
        controller.toggleSelection(boards[1].id)
        XCTAssertTrue(controller.start(availableBoards: boards))

        let edited = FirstThenBoardSnapshot(
            id: boards[0].id,
            name: "Renamed",
            first: FirstThenItemSnapshot(label: "Changed", systemSymbolName: "paintbrush"),
            then: FirstThenItemSnapshot(label: "Changed", systemSymbolName: "carrot")
        )
        controller.reconcileSelection(withAvailable: [edited, boards[1]])

        let session = try XCTUnwrap(controller.session)
        XCTAssertEqual(session.boards[0].name, boards[0].name)
        XCTAssertEqual(session.boards[0].first.label, boards[0].first.label)
    }

    func testProgressSurvivesRepeatedReadsAsAdultExitWouldRequire() throws {
        let controller = makeStartedController(count: 3)

        XCTAssertTrue(controller.completeFirst())
        XCTAssertTrue(controller.advance())
        XCTAssertTrue(controller.completeFirst())

        // Entering and leaving child-facing mode only re-reads the controller;
        // nothing about the schedule is rebuilt.
        let session = try XCTUnwrap(controller.session)
        XCTAssertEqual(session.position, .board(index: 1, phase: .then))
        XCTAssertEqual(try XCTUnwrap(controller.session).position, session.position)
    }

    func testInvalidTransitionsAreRejectedWithoutChangingTheSession() throws {
        let controller = makeStartedController(count: 2)
        let initial = try XCTUnwrap(controller.session)

        XCTAssertFalse(controller.advance())
        XCTAssertFalse(controller.goBack())
        XCTAssertEqual(controller.session, initial)
    }

    func testTransitionsAreRejectedWhenNoScheduleIsRunning() {
        let controller = FirstThenScheduleController()

        XCTAssertFalse(controller.completeFirst())
        XCTAssertFalse(controller.advance())
        XCTAssertFalse(controller.goBack())
        XCTAssertFalse(controller.startOver())
        XCTAssertNil(controller.session)
    }

    func testStartOverResetsProgressButKeepsTheSchedule() throws {
        let controller = makeStartedController(count: 3)
        controller.completeFirst()
        controller.advance()

        XCTAssertTrue(controller.startOver())

        let session = try XCTUnwrap(controller.session)
        XCTAssertEqual(session.position, .board(index: 0, phase: .first))
        XCTAssertEqual(session.boardCount, 3)
    }

    func testEndingDiscardsTheScheduleAndItsSelection() {
        let controller = makeStartedController(count: 2)
        controller.completeFirst()

        controller.endSchedule()

        XCTAssertNil(controller.session)
        XCTAssertFalse(controller.isScheduleActive)
        XCTAssertTrue(controller.selection.orderedBoardIDs.isEmpty)
    }

    func testANewControllerHasNoScheduleAsAfterProcessLoss() {
        let controller = makeStartedController(count: 2)
        controller.completeFirst()
        XCTAssertNotNil(controller.session)

        // Relaunch is modeled by a fresh controller: nothing is restored.
        let relaunched = FirstThenScheduleController()

        XCTAssertNil(relaunched.session)
        XCTAssertTrue(relaunched.selection.orderedBoardIDs.isEmpty)
    }

    // MARK: - Fixtures

    private func makeStartedController(count: Int) -> FirstThenScheduleController {
        let controller = FirstThenScheduleController()
        let boards = makeBoards(count: count)
        for board in boards {
            controller.toggleSelection(board.id)
        }
        _ = controller.start(availableBoards: boards)
        return controller
    }

    private func makeBoards(count: Int) -> [FirstThenBoardSnapshot] {
        (1...count).map { index in
            FirstThenBoardSnapshot(
                id: UUID(),
                name: "Board \(index)",
                first: FirstThenItemSnapshot(label: "Sorting", systemSymbolName: "figure.walk"),
                then: FirstThenItemSnapshot(label: "Reading", systemSymbolName: "book.closed")
            )
        }
    }
}
