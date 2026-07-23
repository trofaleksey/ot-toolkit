import Foundation
import SwiftData
import XCTest
@testable import OTToolkit

final class FirstThenBoardStoreTests: XCTestCase {
    @MainActor
    func testSchemaV1RemainsUnchangedWhileTheAppTargetsV2() {
        XCTAssertEqual(OTToolkitSchemaV1.versionIdentifier, Schema.Version(1, 0, 0))
        XCTAssertEqual(OTToolkitSchemaV1.models.count, 2)

        let v1Schema = Schema(versionedSchema: OTToolkitSchemaV1.self)
        XCTAssertEqual(v1Schema.version, OTToolkitSchemaV1.versionIdentifier)
        XCTAssertNotNil(v1Schema.entity(for: FirstThenBoard.self))
        XCTAssertNotNil(v1Schema.entity(for: FirstThenItem.self))

        let appSchema = LocalModelContainerFactory.appSchema
        XCTAssertEqual(appSchema.version, OTToolkitSchemaV2.versionIdentifier)
        XCTAssertNotNil(appSchema.entity(for: FirstThenBoard.self))
        XCTAssertNotNil(appSchema.entity(for: FirstThenItem.self))
    }

    @MainActor
    func testCreateTrimsContentAndBuildsOrderedInverseRelationship() throws {
        let timestamp = Date(timeIntervalSince1970: 1_000)
        let boardID = try XCTUnwrap(
            UUID(uuidString: "00000000-0000-0000-0000-000000000001")
        )
        let firstID = try XCTUnwrap(
            UUID(uuidString: "00000000-0000-0000-0000-000000000002")
        )
        let thenID = try XCTUnwrap(
            UUID(uuidString: "00000000-0000-0000-0000-000000000003")
        )
        let container = try makeInMemoryContainer()
        let store = FirstThenBoardStore(
            modelContext: container.mainContext,
            now: { timestamp }
        )

        let board = try store.create(
            draft(
                name: "  Morning Routine  ",
                firstLabel: "  Put on shoes ",
                firstSymbol: "  shoe.2  ",
                thenLabel: " Choose a book  ",
                thenSymbol: " book  "
            ),
            boardID: boardID,
            firstItemID: firstID,
            thenItemID: thenID
        )

        XCTAssertEqual(board.id, boardID)
        XCTAssertEqual(board.name, "Morning Routine")
        XCTAssertEqual(board.sortIndex, 0)
        XCTAssertEqual(board.createdAt, timestamp)
        XCTAssertEqual(board.updatedAt, timestamp)

        let items = board.items.sorted { $0.sortIndex < $1.sortIndex }
        XCTAssertEqual(items.map(\.id), [firstID, thenID])
        XCTAssertEqual(items.map(\.role), [.first, .then])
        XCTAssertEqual(items.map(\.label), ["Put on shoes", "Choose a book"])
        XCTAssertEqual(items.map(\.systemSymbolName), ["shoe.2", "book"])
        XCTAssertEqual(items.map(\.sortIndex), [0, 1])
        XCTAssertTrue(items.allSatisfy { $0.board === board })
    }

    @MainActor
    func testValidationRejectsEveryRequiredEmptyValueWithoutSaving() throws {
        let container = try makeInMemoryContainer()
        let store = FirstThenBoardStore(modelContext: container.mainContext)
        let invalidCases: [(FirstThenBoardDraft, FirstThenBoardValidationError)] = [
            (
                draft(name: " \n "),
                .emptyBoardName
            ),
            (
                draft(firstLabel: "   "),
                .emptyLabel(.first)
            ),
            (
                draft(firstSymbol: "   "),
                .emptySystemSymbolName(.first)
            ),
            (
                draft(thenLabel: "   "),
                .emptyLabel(.then)
            ),
            (
                draft(thenSymbol: "   "),
                .emptySystemSymbolName(.then)
            ),
        ]

        for (invalidDraft, expectedError) in invalidCases {
            XCTAssertThrowsError(try store.create(invalidDraft)) { error in
                XCTAssertEqual(error as? FirstThenBoardValidationError, expectedError)
            }
        }

        XCTAssertTrue(try store.fetchBoards().isEmpty)
    }

    @MainActor
    func testUpdatePreservesIdentityAndCreationDate() throws {
        let createdAt = Date(timeIntervalSince1970: 1_000)
        let updatedAt = Date(timeIntervalSince1970: 2_000)
        var timestamp = createdAt
        let container = try makeInMemoryContainer()
        let store = FirstThenBoardStore(
            modelContext: container.mainContext,
            now: { timestamp }
        )
        let board = try store.create(draft())
        let originalBoardID = board.id
        let originalItemIDs = Set(board.items.map(\.id))

        timestamp = updatedAt
        try store.update(
            board,
            with: draft(
                name: "Updated Routine",
                firstLabel: "Pack bag",
                firstSymbol: "backpack",
                thenLabel: "Take a break",
                thenSymbol: "cup.and.saucer"
            )
        )

        XCTAssertEqual(board.id, originalBoardID)
        XCTAssertEqual(board.createdAt, createdAt)
        XCTAssertEqual(board.updatedAt, updatedAt)
        XCTAssertEqual(Set(board.items.map(\.id)), originalItemIDs)
        XCTAssertTrue(board.items.allSatisfy { $0.createdAt == createdAt })
        XCTAssertTrue(board.items.allSatisfy { $0.updatedAt == updatedAt })
        XCTAssertEqual(board.items.first(where: { $0.role == .first })?.label, "Pack bag")
        XCTAssertEqual(board.items.first(where: { $0.role == .then })?.label, "Take a break")
    }

    @MainActor
    func testReorderRequiresEveryBoardExactlyOnce() throws {
        var timestamp = Date(timeIntervalSince1970: 1_000)
        let container = try makeInMemoryContainer()
        let store = FirstThenBoardStore(
            modelContext: container.mainContext,
            now: { timestamp }
        )
        let first = try store.create(draft(name: "One"))
        let second = try store.create(draft(name: "Two"))
        let third = try store.create(draft(name: "Three"))
        timestamp = Date(timeIntervalSince1970: 2_000)

        try store.reorder(boardIDs: [third.id, first.id, second.id])

        XCTAssertEqual(try store.fetchBoards().map(\.id), [third.id, first.id, second.id])
        XCTAssertEqual(try store.fetchBoards().map(\.sortIndex), [0, 1, 2])
        XCTAssertTrue(try store.fetchBoards().allSatisfy { $0.updatedAt == timestamp })

        XCTAssertThrowsError(try store.reorder(boardIDs: [first.id, first.id, third.id])) {
            error in
            XCTAssertEqual(
                error as? FirstThenBoardValidationError,
                .invalidBoardOrder
            )
        }
        XCTAssertEqual(try store.fetchBoards().map(\.id), [third.id, first.id, second.id])
    }

    @MainActor
    func testDeletingBoardCascadesToItems() throws {
        let container = try makeInMemoryContainer()
        let store = FirstThenBoardStore(modelContext: container.mainContext)
        let board = try store.create(draft())
        XCTAssertEqual(try container.mainContext.fetchCount(FetchDescriptor<FirstThenItem>()), 2)

        try store.delete(board)

        XCTAssertEqual(try container.mainContext.fetchCount(FetchDescriptor<FirstThenBoard>()), 0)
        XCTAssertEqual(try container.mainContext.fetchCount(FetchDescriptor<FirstThenItem>()), 0)
    }

    @MainActor
    func testV1OnDiskFixtureReopensThroughMigrationPlan() throws {
        let fixture = makeDiskFixture()
        defer { fixture.cleanUp() }
        let boardID = try XCTUnwrap(
            UUID(uuidString: "00000000-0000-0000-0000-000000000010")
        )

        do {
            let container = try LocalModelContainerFactory.makeAppContainer(
                storeURL: fixture.storeURL
            )
            let store = FirstThenBoardStore(modelContext: container.mainContext)
            _ = try store.create(draft(name: "Persisted Routine"), boardID: boardID)
        }

        do {
            let reopenedContainer = try LocalModelContainerFactory.makeAppContainer(
                storeURL: fixture.storeURL
            )
            let reopenedStore = FirstThenBoardStore(
                modelContext: reopenedContainer.mainContext
            )
            let boards = try reopenedStore.fetchBoards()

            XCTAssertEqual(boards.map(\.id), [boardID])
            XCTAssertEqual(boards.map(\.name), ["Persisted Routine"])
            XCTAssertEqual(boards.first?.items.count, 2)
            XCTAssertEqual(
                Set(boards.first?.items.compactMap(\.role) ?? []),
                Set(FirstThenItemRole.allCases)
            )
        }
    }

    @MainActor
    func testConfirmedResetRemovesV1BoardGraphAndRemainsIdempotent() throws {
        let fixture = makeDiskFixture()
        defer { fixture.cleanUp() }
        let lifecycle = LocalStoreContainerLifecycle(
            layout: fixture.layout,
            fileSystem: LocalStoreFileSystem(fileManager: fixture.fileManager),
            makeContainer: LocalModelContainerFactory.makeAppContainer
        )
        try lifecycle.start()
        do {
            let initialContainer = try XCTUnwrap(lifecycle.modelContainer)
            let store = FirstThenBoardStore(modelContext: initialContainer.mainContext)
            _ = try store.create(draft())
        }
        try lifecycle.secureCurrentContent()

        try lifecycle.reset(authorization: .confirmed)

        do {
            let resetContainer = try XCTUnwrap(lifecycle.modelContainer)
            XCTAssertEqual(
                try resetContainer.mainContext.fetchCount(FetchDescriptor<FirstThenBoard>()),
                0
            )
            XCTAssertEqual(
                try resetContainer.mainContext.fetchCount(FetchDescriptor<FirstThenItem>()),
                0
            )
        }

        try lifecycle.reset(authorization: .confirmed)
        XCTAssertEqual(lifecycle.state, .ready)
    }

    @MainActor
    func testOpeningFailurePreservesV1StoreForExplicitRecovery() throws {
        let fixture = makeDiskFixture()
        defer { fixture.cleanUp() }
        let boardID = try XCTUnwrap(
            UUID(uuidString: "00000000-0000-0000-0000-000000000020")
        )
        try createPersistedBoard(boardID: boardID, fixture: fixture)

        let failingLifecycle = LocalStoreContainerLifecycle(
            layout: fixture.layout,
            fileSystem: LocalStoreFileSystem(fileManager: fixture.fileManager)
        ) { _ in
            throw DiskFixtureError.expectedOpeningFailure
        }

        XCTAssertThrowsError(try failingLifecycle.start()) { error in
            guard case LocalStoreLifecycleError.openingFailed = error else {
                return XCTFail("Expected openingFailed, got \(error)")
            }
        }
        XCTAssertEqual(failingLifecycle.state, .recoveryRequired)

        let reopenedLifecycle = LocalStoreContainerLifecycle(
            layout: fixture.layout,
            fileSystem: LocalStoreFileSystem(fileManager: fixture.fileManager),
            makeContainer: LocalModelContainerFactory.makeAppContainer
        )
        try reopenedLifecycle.start()
        let reopenedContainer = try XCTUnwrap(reopenedLifecycle.modelContainer)
        let reopenedStore = FirstThenBoardStore(
            modelContext: reopenedContainer.mainContext
        )
        XCTAssertEqual(try reopenedStore.fetchBoards().map(\.id), [boardID])
    }

    @MainActor
    private func makeInMemoryContainer() throws -> ModelContainer {
        let schema = LocalModelContainerFactory.appSchema
        let configuration = ModelConfiguration(
            "FirstThenBoardStoreTests",
            schema: schema,
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none
        )
        return try ModelContainer(
            for: schema,
            migrationPlan: OTToolkitSchemaMigrationPlan.self,
            configurations: [configuration]
        )
    }

    private func draft(
        name: String = "Routine",
        firstLabel: String = "Finish task",
        firstSymbol: String = "checklist",
        thenLabel: String = "Take a break",
        thenSymbol: String = "figure.mind.and.body"
    ) -> FirstThenBoardDraft {
        FirstThenBoardDraft(
            name: name,
            first: FirstThenItemDraft(
                label: firstLabel,
                systemSymbolName: firstSymbol
            ),
            then: FirstThenItemDraft(
                label: thenLabel,
                systemSymbolName: thenSymbol
            )
        )
    }

    private func makeDiskFixture() -> DiskFixture {
        let fileManager = FileManager.default
        let root = fileManager.temporaryDirectory.appendingPathComponent(
            "FirstThenBoardStoreTests-\(UUID().uuidString)",
            isDirectory: true
        )
        try? fileManager.createDirectory(
            at: root,
            withIntermediateDirectories: true
        )
        return DiskFixture(fileManager: fileManager, root: root)
    }

    @MainActor
    private func createPersistedBoard(
        boardID: UUID,
        fixture: DiskFixture
    ) throws {
        let lifecycle = LocalStoreContainerLifecycle(
            layout: fixture.layout,
            fileSystem: LocalStoreFileSystem(fileManager: fixture.fileManager),
            makeContainer: LocalModelContainerFactory.makeAppContainer
        )
        try lifecycle.start()
        let container = try XCTUnwrap(lifecycle.modelContainer)
        let store = FirstThenBoardStore(modelContext: container.mainContext)
        _ = try store.create(draft(name: "Preserved Routine"), boardID: boardID)
        try lifecycle.secureCurrentContent()
    }
}

private struct DiskFixture {
    let fileManager: FileManager
    let root: URL

    var storeURL: URL {
        root.appendingPathComponent("fixture.store", isDirectory: false)
    }

    var layout: LocalStoreLayout {
        LocalStoreLayout(
            contentDirectory: root.appendingPathComponent("Content", isDirectory: true)
        )
    }

    func cleanUp() {
        if fileManager.fileExists(atPath: root.path) {
            try? fileManager.removeItem(at: root)
        }
    }
}

private enum DiskFixtureError: Error {
    case expectedOpeningFailure
}
