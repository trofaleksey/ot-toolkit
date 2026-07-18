import SwiftData
import XCTest
@testable import OTToolkit

@MainActor
final class AppDataControllerTests: XCTestCase {
    func testInMemoryStoreStartsReadyAndResetRemovesSavedBoards() throws {
        let controller = AppDataController(usesInMemoryStore: true)
        let initialContainer = try XCTUnwrap(controller.modelContainer)
        let store = FirstThenBoardStore(modelContext: initialContainer.mainContext)
        _ = try store.create(
            FirstThenBoardDraft(
                name: "Morning Routine",
                first: FirstThenItemDraft(label: "Get dressed", systemSymbolName: "tshirt"),
                then: FirstThenItemDraft(label: "Read", systemSymbolName: "book.closed")
            )
        )
        XCTAssertEqual(try store.fetchBoards().count, 1)

        XCTAssertTrue(controller.reset())

        let resetContainer = try XCTUnwrap(controller.modelContainer)
        let resetStore = FirstThenBoardStore(modelContext: resetContainer.mainContext)
        XCTAssertEqual(controller.state, .ready)
        XCTAssertTrue(try resetStore.fetchBoards().isEmpty)
    }

    func testRetryKeepsAReadyInMemoryStoreAvailable() {
        let controller = AppDataController(usesInMemoryStore: true)

        controller.retry()

        XCTAssertEqual(controller.state, .ready)
        XCTAssertNotNil(controller.modelContainer)
    }
}
