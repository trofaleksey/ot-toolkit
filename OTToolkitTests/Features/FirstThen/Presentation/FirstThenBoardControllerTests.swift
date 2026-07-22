import Foundation
import SwiftData
import XCTest
@testable import OTToolkit

@MainActor
final class FirstThenBoardControllerTests: XCTestCase {
    func testSessionTransitionsFromFirstToThenAndRemainsCompleted() {
        var session = FirstThenBoardSession()

        XCTAssertEqual(session.phase, .first)
        XCTAssertFalse(session.isFirstComplete)

        session.completeFirst()
        session.completeFirst()

        XCTAssertEqual(session.phase, .then)
        XCTAssertTrue(session.isFirstComplete)
    }

    func testSessionControllerSharesCompletionAndCanResetOrDiscardIt() {
        let boardID = UUID()
        let controller = FirstThenBoardSessionController()

        controller.start(boardID: boardID)
        controller.completeFirst(boardID: boardID)
        XCTAssertTrue(controller.session(for: boardID).isFirstComplete)

        controller.start(boardID: boardID)
        XCTAssertFalse(controller.session(for: boardID).isFirstComplete)

        controller.completeFirst(boardID: boardID)
        controller.discardSession(boardID: boardID)
        XCTAssertEqual(controller.session(for: boardID), FirstThenBoardSession())
    }

    func testCreateUpdateAndDeleteRefreshValueSnapshots() throws {
        let container = try makeContainer()
        let controller = FirstThenBoardController(
            store: FirstThenBoardStore(modelContext: container.mainContext)
        )

        XCTAssertTrue(controller.boards.isEmpty)
        XCTAssertTrue(controller.create(morningDraft))

        let created = try XCTUnwrap(controller.boards.first)
        XCTAssertEqual(created.name, "Morning Routine")
        XCTAssertEqual(created.first.label, "Get dressed")
        XCTAssertEqual(created.first.systemSymbolName, "tshirt")
        XCTAssertEqual(created.then.label, "Read together")
        XCTAssertEqual(created.then.systemSymbolName, "book.closed")

        let updatedDraft = FirstThenBoardDraft(
            name: "After School",
            first: FirstThenItemDraft(label: "Hang backpack", systemSymbolName: "backpack"),
            then: FirstThenItemDraft(label: "Choose a game", systemSymbolName: "puzzlepiece")
        )
        XCTAssertTrue(controller.update(id: created.id, with: updatedDraft))
        XCTAssertEqual(controller.board(id: created.id)?.name, "After School")
        XCTAssertEqual(controller.board(id: created.id)?.then.label, "Choose a game")

        XCTAssertTrue(controller.delete(id: created.id))
        XCTAssertTrue(controller.boards.isEmpty)
        XCTAssertNil(controller.failure)
    }

    func testFailedCreatePreservesExistingSnapshotsAndExposesRecoveryState() {
        let existingBoard = makeBoard()
        let store = ControllableBoardStore(boards: [existingBoard])
        let controller = FirstThenBoardController(store: store)
        let initialSnapshots = controller.boards
        store.failure = .create

        XCTAssertFalse(controller.create(morningDraft))
        XCTAssertEqual(controller.boards, initialSnapshots)
        XCTAssertEqual(controller.failure, .create)

        controller.dismissFailure()
        XCTAssertNil(controller.failure)
    }

    func testFailedReloadPreservesLastKnownSnapshots() {
        let store = ControllableBoardStore(boards: [makeBoard()])
        let controller = FirstThenBoardController(store: store)
        let initialSnapshots = controller.boards
        store.failure = .fetch

        XCTAssertFalse(controller.reload())
        XCTAssertEqual(controller.boards, initialSnapshots)
        XCTAssertEqual(controller.failure, .load)
    }

    func testFailedUpdateAndDeletePreserveLastKnownSnapshots() throws {
        let store = ControllableBoardStore(boards: [makeBoard()])
        let controller = FirstThenBoardController(store: store)
        let initialSnapshots = controller.boards
        let boardID = try XCTUnwrap(initialSnapshots.first?.id)

        store.failure = .update
        XCTAssertFalse(controller.update(id: boardID, with: morningDraft))
        XCTAssertEqual(controller.boards, initialSnapshots)
        XCTAssertEqual(controller.failure, .update)

        store.failure = .delete
        XCTAssertFalse(controller.delete(id: boardID))
        XCTAssertEqual(controller.boards, initialSnapshots)
        XCTAssertEqual(controller.failure, .delete)
    }

    func testInvalidPersistedGraphFailsClosedWithoutPublishingPartialBoard() {
        let invalidBoard = makeBoard()
        invalidBoard.items.removeLast()

        let controller = FirstThenBoardController(
            store: ControllableBoardStore(boards: [invalidBoard])
        )

        XCTAssertTrue(controller.boards.isEmpty)
        XCTAssertEqual(controller.failure, .load)
    }

    private var morningDraft: FirstThenBoardDraft {
        FirstThenBoardDraft(
            name: "Morning Routine",
            first: FirstThenItemDraft(label: "Get dressed", systemSymbolName: "tshirt"),
            then: FirstThenItemDraft(label: "Read together", systemSymbolName: "book.closed")
        )
    }

    private func makeContainer() throws -> ModelContainer {
        let schema = Schema(versionedSchema: OTToolkitSchemaV1.self)
        let configuration = ModelConfiguration(
            "FirstThenBoardControllerTests",
            schema: schema,
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none
        )
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    private func makeBoard() -> FirstThenBoard {
        let timestamp = Date(timeIntervalSince1970: 1_700_000_000)
        return FirstThenBoard(
            id: UUID(uuidString: "10000000-0000-0000-0000-000000000001")
                ?? UUID(),
            name: "Morning Routine",
            sortIndex: 0,
            createdAt: timestamp,
            updatedAt: timestamp,
            items: [
                FirstThenItem(
                    id: UUID(uuidString: "20000000-0000-0000-0000-000000000001")
                        ?? UUID(),
                    role: .first,
                    label: "Get dressed",
                    systemSymbolName: "tshirt",
                    sortIndex: 0,
                    createdAt: timestamp,
                    updatedAt: timestamp
                ),
                FirstThenItem(
                    id: UUID(uuidString: "30000000-0000-0000-0000-000000000001")
                        ?? UUID(),
                    role: .then,
                    label: "Read together",
                    systemSymbolName: "book.closed",
                    sortIndex: 1,
                    createdAt: timestamp,
                    updatedAt: timestamp
                ),
            ]
        )
    }
}

@MainActor
private final class ControllableBoardStore: FirstThenBoardStoring {
    enum Failure {
        case create
        case fetch
        case update
        case delete
    }

    enum StoreError: Error {
        case expectedFailure
    }

    var boards: [FirstThenBoard]
    var failure: Failure?

    init(boards: [FirstThenBoard]) {
        self.boards = boards
    }

    func create(_ draft: FirstThenBoardDraft) throws -> FirstThenBoard {
        if failure == .create {
            throw StoreError.expectedFailure
        }
        return boards[0]
    }

    func fetchBoards() throws -> [FirstThenBoard] {
        if failure == .fetch {
            throw StoreError.expectedFailure
        }
        return boards
    }

    func update(_ board: FirstThenBoard, with draft: FirstThenBoardDraft) throws {
        if failure == .update {
            throw StoreError.expectedFailure
        }
    }

    func delete(_ board: FirstThenBoard) throws {
        if failure == .delete {
            throw StoreError.expectedFailure
        }
    }
}
