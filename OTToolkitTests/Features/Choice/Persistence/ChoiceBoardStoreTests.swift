import Foundation
import SwiftData
import XCTest

@testable import OTToolkit

@MainActor
final class ChoiceBoardStoreTests: XCTestCase {
    func testSchemaV3AddsChoiceModelsAndKeepsEarlierOnes() {
        XCTAssertEqual(OTToolkitSchemaV3.versionIdentifier, Schema.Version(3, 0, 0))
        XCTAssertEqual(OTToolkitSchemaV3.models.count, 5)

        let schema = LocalModelContainerFactory.appSchema
        XCTAssertEqual(schema.version, OTToolkitSchemaV3.versionIdentifier)
        XCTAssertEqual(OTToolkitSchemaMigrationPlan.schemas.count, 3)
        XCTAssertEqual(OTToolkitSchemaMigrationPlan.stages.count, 2)
    }

    func testCreateStoresOptionsInDraftOrder() throws {
        let store = try makeStore()

        let board = try store.create(draft(optionLabels: ["Swing", "Bubbles", "Drawing"]))

        XCTAssertEqual(board.name, "Break choices")
        XCTAssertEqual(
            try store.sortedOptions(of: board).map(\.label),
            ["Swing", "Bubbles", "Drawing"]
        )
        XCTAssertEqual(try store.sortedOptions(of: board).map(\.sortIndex), [0, 1, 2])
    }

    func testCreateTrimsWhitespaceFromNameAndOptions() throws {
        let store = try makeStore()

        let board = try store.create(
            ChoiceBoardDraft(
                name: "  Break choices  ",
                options: [
                    ChoiceOptionDraft(label: "  Swing  ", systemSymbolName: "  figure.walk  "),
                    ChoiceOptionDraft(label: "Bubbles", systemSymbolName: "puzzlepiece"),
                ]
            )
        )

        XCTAssertEqual(board.name, "Break choices")
        let options = try store.sortedOptions(of: board)
        XCTAssertEqual(options.map(\.label), ["Swing", "Bubbles"])
        XCTAssertEqual(options.first?.systemSymbolName, "figure.walk")
    }

    func testCreateRejectsInvalidDrafts() throws {
        let store = try makeStore()

        XCTAssertThrowsError(try store.create(draft(name: "   "))) { error in
            XCTAssertEqual(error as? ChoiceBoardValidationError, .emptyBoardName)
        }
        XCTAssertThrowsError(try store.create(draft(optionLabels: ["Only"]))) { error in
            XCTAssertEqual(error as? ChoiceBoardValidationError, .invalidOptionCount)
        }
        XCTAssertThrowsError(
            try store.create(draft(optionLabels: ["1", "2", "3", "4", "5", "6", "7"]))
        ) { error in
            XCTAssertEqual(error as? ChoiceBoardValidationError, .invalidOptionCount)
        }
        XCTAssertThrowsError(try store.create(draft(optionLabels: ["Swing", "  "]))) { error in
            XCTAssertEqual(error as? ChoiceBoardValidationError, .emptyOptionLabel)
        }
        XCTAssertThrowsError(
            try store.create(
                ChoiceBoardDraft(
                    name: "Break choices",
                    options: [
                        ChoiceOptionDraft(label: "Swing", systemSymbolName: " "),
                        ChoiceOptionDraft(label: "Bubbles", systemSymbolName: "puzzlepiece"),
                    ]
                )
            )
        ) { error in
            XCTAssertEqual(error as? ChoiceBoardValidationError, .emptyOptionSymbolName)
        }

        XCTAssertEqual(try store.fetchBoards().count, 0)
    }

    func testUpdateReplacesOptionsAndDoesNotOrphanTheOldOnes() throws {
        let container = try makeContainer()
        let store = ChoiceBoardStore(modelContext: container.mainContext)
        let board = try store.create(draft(optionLabels: ["Swing", "Bubbles", "Drawing"]))

        try store.update(
            board,
            with: draft(name: "Afternoon choices", optionLabels: ["Reading", "Puzzle"])
        )

        XCTAssertEqual(board.name, "Afternoon choices")
        XCTAssertEqual(try store.sortedOptions(of: board).map(\.label), ["Reading", "Puzzle"])
        XCTAssertEqual(
            try container.mainContext.fetchCount(FetchDescriptor<ChoiceOption>()),
            2,
            "Replaced options must be deleted, not left orphaned in the store."
        )
    }

    func testUpdateRejectsAnInvalidOptionCountAndLeavesTheBoardIntact() throws {
        let store = try makeStore()
        let board = try store.create(draft(optionLabels: ["Swing", "Bubbles"]))

        XCTAssertThrowsError(try store.update(board, with: draft(optionLabels: ["Only"])))

        XCTAssertEqual(try store.sortedOptions(of: board).map(\.label), ["Swing", "Bubbles"])
    }

    func testDuplicateCopiesOptionsInOrderWithoutSharingIdentity() throws {
        let store = try makeStore()
        let board = try store.create(draft(optionLabels: ["Swing", "Bubbles", "Drawing"]))

        let copy = try store.duplicate(board, named: "Break choices copy")

        XCTAssertNotEqual(copy.id, board.id)
        XCTAssertEqual(copy.name, "Break choices copy")
        XCTAssertEqual(
            try store.sortedOptions(of: copy).map(\.label),
            ["Swing", "Bubbles", "Drawing"]
        )

        let originalOptionIDs = Set(try store.sortedOptions(of: board).map(\.id))
        let copyOptionIDs = Set(try store.sortedOptions(of: copy).map(\.id))
        XCTAssertTrue(originalOptionIDs.isDisjoint(with: copyOptionIDs))

        // Editing the copy must not reach back into the original.
        try store.update(copy, with: draft(name: "Changed", optionLabels: ["Reading", "Puzzle"]))
        XCTAssertEqual(
            try store.sortedOptions(of: board).map(\.label),
            ["Swing", "Bubbles", "Drawing"]
        )
    }

    func testDuplicateAppendsAfterExistingBoards() throws {
        let store = try makeStore()
        let first = try store.create(draft(name: "First"))
        _ = try store.create(draft(name: "Second"))

        _ = try store.duplicate(first, named: "First copy")

        XCTAssertEqual(try store.fetchBoards().map(\.name), ["First", "Second", "First copy"])
    }

    func testReorderRewritesBoardOrder() throws {
        let store = try makeStore()
        let first = try store.create(draft(name: "First"))
        let second = try store.create(draft(name: "Second"))
        let third = try store.create(draft(name: "Third"))

        try store.reorder(boardIDs: [third.id, first.id, second.id])

        XCTAssertEqual(try store.fetchBoards().map(\.name), ["Third", "First", "Second"])
    }

    func testReorderRejectsIncompleteOrDuplicatedIdentifiers() throws {
        let store = try makeStore()
        let first = try store.create(draft(name: "First"))
        let second = try store.create(draft(name: "Second"))

        XCTAssertThrowsError(try store.reorder(boardIDs: [first.id])) { error in
            XCTAssertEqual(error as? ChoiceBoardValidationError, .invalidBoardOrder)
        }
        XCTAssertThrowsError(try store.reorder(boardIDs: [first.id, first.id])) { error in
            XCTAssertEqual(error as? ChoiceBoardValidationError, .invalidBoardOrder)
        }

        XCTAssertEqual(try store.fetchBoards().map(\.id), [first.id, second.id])
    }

    func testReorderOptionsRewritesPresentationOrder() throws {
        let store = try makeStore()
        let board = try store.create(draft(optionLabels: ["Swing", "Bubbles", "Drawing"]))
        let options = try store.sortedOptions(of: board)

        try store.reorderOptions(
            of: board,
            to: [options[2].id, options[0].id, options[1].id]
        )

        XCTAssertEqual(
            try store.sortedOptions(of: board).map(\.label),
            ["Drawing", "Swing", "Bubbles"]
        )
    }

    func testReorderOptionsRejectsAForeignIdentifier() throws {
        let store = try makeStore()
        let board = try store.create(draft(optionLabels: ["Swing", "Bubbles"]))
        let options = try store.sortedOptions(of: board)

        XCTAssertThrowsError(
            try store.reorderOptions(of: board, to: [options[0].id, UUID()])
        ) { error in
            XCTAssertEqual(error as? ChoiceBoardValidationError, .invalidOptionOrder)
        }

        XCTAssertEqual(try store.sortedOptions(of: board).map(\.label), ["Swing", "Bubbles"])
    }

    func testDeletingABoardCascadesToItsOptions() throws {
        let container = try makeContainer()
        let store = ChoiceBoardStore(modelContext: container.mainContext)
        let board = try store.create(draft(optionLabels: ["Swing", "Bubbles", "Drawing"]))

        try store.delete(board)

        XCTAssertEqual(try store.fetchBoards().count, 0)
        XCTAssertEqual(
            try container.mainContext.fetchCount(FetchDescriptor<ChoiceOption>()),
            0,
            "Cascade delete must not leave orphaned options behind."
        )
    }

    func testV2OnDiskStoreMigratesToV3AndSupportsChoiceBoards() throws {
        let fixture = makeDiskFixture()
        defer { fixture.cleanUp() }
        let templateID = try XCTUnwrap(UUID(uuidString: "00000000-0000-0000-0000-0000000000C1"))
        let firstThenID = try XCTUnwrap(UUID(uuidString: "00000000-0000-0000-0000-0000000000C2"))

        do {
            let container = try LocalModelContainerFactory.makeContainer(
                schema: Schema(versionedSchema: OTToolkitSchemaV2.self),
                storeURL: fixture.storeURL
            )
            _ = try FirstThenBoardStore(modelContext: container.mainContext).create(
                FirstThenBoardDraft(
                    name: "Persisted Routine",
                    first: FirstThenItemDraft(label: "Finish task", systemSymbolName: "checklist"),
                    then: FirstThenItemDraft(label: "Break", systemSymbolName: "puzzlepiece")
                ),
                boardID: firstThenID
            )
            _ = try TokenBoardTemplateStore(modelContext: container.mainContext).create(
                TokenBoardTemplateDraft(
                    name: "Reward Chart",
                    goal: .five,
                    reward: TokenBoardReward(label: "Sticker", systemSymbolName: "star")
                ),
                templateID: templateID
            )
        }

        do {
            let container = try LocalModelContainerFactory.makeAppContainer(
                storeURL: fixture.storeURL
            )
            let context = container.mainContext

            XCTAssertEqual(
                try FirstThenBoardStore(modelContext: context).fetchBoards().map(\.id),
                [firstThenID]
            )
            XCTAssertEqual(
                try TokenBoardTemplateStore(modelContext: context).fetchTemplates().map(\.id),
                [templateID]
            )

            let choiceStore = ChoiceBoardStore(modelContext: context)
            XCTAssertEqual(try choiceStore.fetchBoards().count, 0)
            let board = try choiceStore.create(draft(optionLabels: ["Swing", "Bubbles"]))
            XCTAssertEqual(try choiceStore.fetchBoards().map(\.id), [board.id])
            XCTAssertEqual(
                try choiceStore.sortedOptions(of: board).map(\.label),
                ["Swing", "Bubbles"]
            )
        }
    }

    func testChoiceBoardsSurviveReopeningTheSameOnDiskStore() throws {
        let fixture = makeDiskFixture()
        defer { fixture.cleanUp() }
        let boardID = try XCTUnwrap(UUID(uuidString: "00000000-0000-0000-0000-0000000000C3"))

        do {
            let container = try LocalModelContainerFactory.makeAppContainer(
                storeURL: fixture.storeURL
            )
            _ = try ChoiceBoardStore(modelContext: container.mainContext).create(
                draft(optionLabels: ["Swing", "Bubbles", "Drawing"]),
                boardID: boardID
            )
        }

        do {
            let container = try LocalModelContainerFactory.makeAppContainer(
                storeURL: fixture.storeURL
            )
            let store = ChoiceBoardStore(modelContext: container.mainContext)
            let boards = try store.fetchBoards()
            XCTAssertEqual(boards.map(\.id), [boardID])
            XCTAssertEqual(
                try store.sortedOptions(of: XCTUnwrap(boards.first)).map(\.label),
                ["Swing", "Bubbles", "Drawing"]
            )
        }
    }

    func testConfirmedResetRemovesChoiceBoardsAndRemainsIdempotent() throws {
        let fixture = makeDiskFixture()
        defer { fixture.cleanUp() }
        let lifecycle = LocalStoreContainerLifecycle(
            layout: fixture.layout,
            fileSystem: LocalStoreFileSystem(fileManager: fixture.fileManager),
            makeContainer: LocalModelContainerFactory.makeAppContainer
        )
        try lifecycle.start()
        do {
            let container = try XCTUnwrap(lifecycle.modelContainer)
            _ = try ChoiceBoardStore(modelContext: container.mainContext).create(
                draft(optionLabels: ["Swing", "Bubbles"])
            )
        }
        try lifecycle.secureCurrentContent()

        try lifecycle.reset(authorization: .confirmed)

        do {
            let container = try XCTUnwrap(lifecycle.modelContainer)
            XCTAssertEqual(
                try container.mainContext.fetchCount(FetchDescriptor<ChoiceBoard>()),
                0
            )
            XCTAssertEqual(
                try container.mainContext.fetchCount(FetchDescriptor<ChoiceOption>()),
                0
            )
        }

        try lifecycle.reset(authorization: .confirmed)
        XCTAssertEqual(lifecycle.state, .ready)
    }

    // MARK: - Helpers

    /// Retains the container for the lifetime of the test. A `ModelContext`
    /// does not keep its container alive, so handing out `mainContext` from a
    /// temporary container crashes as soon as it deallocates.
    private var retainedContainer: ModelContainer?

    private func makeStore() throws -> ChoiceBoardStore {
        let container = try makeContainer()
        retainedContainer = container
        return ChoiceBoardStore(modelContext: container.mainContext)
    }

    private func makeContainer() throws -> ModelContainer {
        let schema = LocalModelContainerFactory.appSchema
        let configuration = ModelConfiguration(
            "ChoiceBoardStoreTests",
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

    private func makeDiskFixture() -> ChoiceDiskFixture {
        let fileManager = FileManager.default
        let root = fileManager.temporaryDirectory.appendingPathComponent(
            "ChoiceBoardStoreTests-\(UUID().uuidString)",
            isDirectory: true
        )
        try? fileManager.createDirectory(at: root, withIntermediateDirectories: true)
        return ChoiceDiskFixture(fileManager: fileManager, root: root)
    }
}

private struct ChoiceDiskFixture {
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
