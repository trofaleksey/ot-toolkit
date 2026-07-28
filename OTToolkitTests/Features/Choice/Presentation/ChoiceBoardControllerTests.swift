import Foundation
import SwiftData
import XCTest

@testable import OTToolkit

@MainActor
final class ChoiceBoardControllerTests: XCTestCase {
    private var retainedContainer: ModelContainer?

    func testControllerExposesBoardsAsOrderedValueSnapshots() throws {
        let controller = try makeController()

        XCTAssertTrue(controller.create(draft(name: "Break choices")))
        XCTAssertTrue(controller.create(draft(name: "Afternoon choices")))

        XCTAssertEqual(controller.boards.map(\.name), ["Break choices", "Afternoon choices"])
        XCTAssertEqual(controller.boards.first?.options.map(\.label), ["Swing", "Bubbles"])
        XCTAssertNil(controller.failure)
    }

    func testCreateReportsFailureForAnInvalidDraft() throws {
        let controller = try makeController()

        XCTAssertFalse(controller.create(draft(optionLabels: ["Only"])))

        XCTAssertEqual(controller.failure, .create)
        XCTAssertTrue(controller.boards.isEmpty)
    }

    func testUpdateAndDeleteReportFailureForAnUnknownBoard() throws {
        let controller = try makeController()

        XCTAssertFalse(controller.update(id: UUID(), with: draft()))
        XCTAssertEqual(controller.failure, .update)

        controller.dismissFailure()
        XCTAssertFalse(controller.delete(id: UUID()))
        XCTAssertEqual(controller.failure, .delete)

        controller.dismissFailure()
        XCTAssertFalse(controller.duplicate(id: UUID(), named: "Copy"))
        XCTAssertEqual(controller.failure, .duplicate)
    }

    func testDuplicateAddsACopyWithTheGivenName() throws {
        let controller = try makeController()
        XCTAssertTrue(controller.create(draft(name: "Break choices")))
        let original = try XCTUnwrap(controller.boards.first)

        XCTAssertTrue(controller.duplicate(id: original.id, named: "Break choices copy"))

        XCTAssertEqual(controller.boards.map(\.name), ["Break choices", "Break choices copy"])
        let copy = try XCTUnwrap(controller.boards.last)
        XCTAssertNotEqual(copy.id, original.id)
        XCTAssertEqual(copy.options.map(\.label), original.options.map(\.label))
    }

    func testSessionControllerRefusesBoardsOutsideTheSupportedRange() {
        let sessions = ChoiceBoardSessionController()
        let board = ChoiceBoardSnapshot(
            id: UUID(),
            name: "Too small",
            options: [ChoiceOptionSnapshot(id: UUID(), label: "Only", systemSymbolName: "circle")]
        )

        XCTAssertFalse(sessions.start(board: board))
        XCTAssertNil(sessions.session(for: board.id))
    }

    func testSessionControllerTracksSelectionAndHidingPerBoard() throws {
        let sessions = ChoiceBoardSessionController()
        let first = makeSnapshot(name: "First", optionCount: 3)
        let second = makeSnapshot(name: "Second", optionCount: 3)
        XCTAssertTrue(sessions.start(board: first))
        XCTAssertTrue(sessions.start(board: second))

        XCTAssertTrue(sessions.select(optionID: first.options[0].id, boardID: first.id))
        XCTAssertTrue(sessions.hide(optionID: first.options[2].id, boardID: first.id))

        let firstSession = try XCTUnwrap(sessions.session(for: first.id))
        XCTAssertTrue(firstSession.isSelected(first.options[0].id))
        XCTAssertEqual(firstSession.visibleOptions.count, 2)

        let secondSession = try XCTUnwrap(sessions.session(for: second.id))
        XCTAssertFalse(secondSession.hasSelection)
        XCTAssertEqual(secondSession.visibleOptions.count, 3)
    }

    func testSessionControllerRejectsChangesForAnUnknownBoard() {
        let sessions = ChoiceBoardSessionController()

        XCTAssertFalse(sessions.select(optionID: UUID(), boardID: UUID()))
        XCTAssertFalse(sessions.hide(optionID: UUID(), boardID: UUID()))
        XCTAssertFalse(sessions.show(optionID: UUID(), boardID: UUID()))
        XCTAssertFalse(sessions.clearSelection(boardID: UUID()))
        XCTAssertFalse(sessions.showAllOptions(boardID: UUID()))
    }

    func testSynchronizeRestartsTheSessionWhenTheSavedBoardChanged() throws {
        let sessions = ChoiceBoardSessionController()
        let board = makeSnapshot(name: "Break choices", optionCount: 3)
        XCTAssertTrue(sessions.start(board: board))
        XCTAssertTrue(sessions.select(optionID: board.options[0].id, boardID: board.id))

        let edited = ChoiceBoardSnapshot(
            id: board.id,
            name: "Break choices",
            options: [
                ChoiceOptionSnapshot(id: UUID(), label: "Reading", systemSymbolName: "book.closed"),
                ChoiceOptionSnapshot(id: UUID(), label: "Puzzle", systemSymbolName: "puzzlepiece"),
            ]
        )
        sessions.synchronize(with: edited)

        let session = try XCTUnwrap(sessions.session(for: board.id))
        XCTAssertEqual(session.board.options.map(\.label), ["Reading", "Puzzle"])
        XCTAssertFalse(
            session.hasSelection,
            "A stale pick must not survive the board changing underneath it."
        )
    }

    func testSynchronizeLeavesAnUnchangedSessionAlone() throws {
        let sessions = ChoiceBoardSessionController()
        let board = makeSnapshot(name: "Break choices", optionCount: 3)
        XCTAssertTrue(sessions.start(board: board))
        XCTAssertTrue(sessions.select(optionID: board.options[1].id, boardID: board.id))

        sessions.synchronize(with: board)

        let session = try XCTUnwrap(sessions.session(for: board.id))
        XCTAssertTrue(session.isSelected(board.options[1].id))
    }

    func testDiscardingASessionRemovesIt() {
        let sessions = ChoiceBoardSessionController()
        let board = makeSnapshot(name: "Break choices", optionCount: 2)
        XCTAssertTrue(sessions.start(board: board))

        sessions.discardSession(boardID: board.id)

        XCTAssertNil(sessions.session(for: board.id))
    }

    // MARK: - Fixtures

    private func makeController() throws -> ChoiceBoardController {
        let schema = LocalModelContainerFactory.appSchema
        let configuration = ModelConfiguration(
            "ChoiceBoardControllerTests",
            schema: schema,
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none
        )
        let container = try ModelContainer(
            for: schema,
            migrationPlan: OTToolkitSchemaMigrationPlan.self,
            configurations: [configuration]
        )
        retainedContainer = container
        return ChoiceBoardController(store: ChoiceBoardStore(modelContext: container.mainContext))
    }

    private func draft(
        name: String = "Break choices",
        optionLabels: [String] = ["Swing", "Bubbles"]
    ) -> ChoiceBoardDraft {
        ChoiceBoardDraft(
            name: name,
            options: optionLabels.map {
                ChoiceOptionDraft(label: $0, systemSymbolName: "puzzlepiece")
            }
        )
    }

    private func makeSnapshot(name: String, optionCount: Int) -> ChoiceBoardSnapshot {
        ChoiceBoardSnapshot(
            id: UUID(),
            name: name,
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
