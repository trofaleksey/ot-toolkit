import Foundation
import SwiftData
import XCTest
@testable import OTToolkit

final class TokenBoardTemplateStoreTests: XCTestCase {
    @MainActor
    func testSchemaV2ExposesFirstThenAndTokenModelsThroughLightweightMigration() {
        XCTAssertEqual(OTToolkitSchemaV2.versionIdentifier, Schema.Version(2, 0, 0))
        XCTAssertEqual(OTToolkitSchemaV2.models.count, 3)
        XCTAssertEqual(OTToolkitSchemaMigrationPlan.schemas.count, 2)
        XCTAssertEqual(OTToolkitSchemaMigrationPlan.stages.count, 1)

        let schema = LocalModelContainerFactory.appSchema
        XCTAssertEqual(schema.version, OTToolkitSchemaV2.versionIdentifier)
        XCTAssertNotNil(schema.entity(for: TokenBoardTemplate.self))
        XCTAssertNotNil(schema.entity(for: FirstThenBoard.self))
        XCTAssertNotNil(schema.entity(for: FirstThenItem.self))
    }

    @MainActor
    func testCreateTrimsContentAndAssignsGoalAndOrder() throws {
        let timestamp = Date(timeIntervalSince1970: 2_000)
        let templateID = try XCTUnwrap(
            UUID(uuidString: "00000000-0000-0000-0000-0000000000A1")
        )
        let container = try makeInMemoryContainer()
        let store = TokenBoardTemplateStore(
            modelContext: container.mainContext,
            now: { timestamp }
        )

        let template = try store.create(
            draft(
                name: "  Reward Chart  ",
                goal: .five,
                label: "  Sticker ",
                symbol: "  star.fill  "
            ),
            templateID: templateID
        )

        XCTAssertEqual(template.id, templateID)
        XCTAssertEqual(template.name, "Reward Chart")
        XCTAssertEqual(template.goalRawValue, 5)
        XCTAssertEqual(template.goal, .five)
        XCTAssertEqual(template.rewardLabel, "Sticker")
        XCTAssertEqual(template.rewardSystemSymbolName, "star.fill")
        XCTAssertEqual(template.sortIndex, 0)
        XCTAssertEqual(template.createdAt, timestamp)
        XCTAssertEqual(template.updatedAt, timestamp)
    }

    @MainActor
    func testCreateAssignsIncreasingSortIndexes() throws {
        let container = try makeInMemoryContainer()
        let store = TokenBoardTemplateStore(modelContext: container.mainContext)

        let first = try store.create(draft(name: "One"))
        let second = try store.create(draft(name: "Two"))

        XCTAssertEqual(first.sortIndex, 0)
        XCTAssertEqual(second.sortIndex, 1)
        XCTAssertEqual(try store.fetchTemplates().map(\.name), ["One", "Two"])
    }

    @MainActor
    func testEverySupportedGoalPersists() throws {
        let container = try makeInMemoryContainer()
        let store = TokenBoardTemplateStore(modelContext: container.mainContext)

        for goal in TokenBoardGoal.allCases {
            let template = try store.create(draft(name: "Goal \(goal.rawValue)", goal: goal))
            XCTAssertEqual(template.goal, goal)
        }
    }

    @MainActor
    func testValidationRejectsEmptyValuesWithoutSaving() throws {
        let container = try makeInMemoryContainer()
        let store = TokenBoardTemplateStore(modelContext: container.mainContext)
        let invalidCases: [(TokenBoardTemplateDraft, TokenBoardTemplateValidationError)] = [
            (draft(name: "   "), .emptyTemplateName),
            (draft(label: "   "), .emptyRewardLabel),
            (draft(symbol: "   "), .emptyRewardSymbolName),
        ]

        for (invalid, expected) in invalidCases {
            XCTAssertThrowsError(try store.create(invalid)) { error in
                XCTAssertEqual(error as? TokenBoardTemplateValidationError, expected)
            }
        }
        XCTAssertEqual(try store.fetchTemplates().count, 0)
    }

    @MainActor
    func testUpdateReplacesConfigurationAndTouchesTimestamp() throws {
        var clock = Date(timeIntervalSince1970: 1_000)
        let container = try makeInMemoryContainer()
        let store = TokenBoardTemplateStore(
            modelContext: container.mainContext,
            now: { clock }
        )
        let template = try store.create(draft(name: "Before", goal: .three))

        clock = Date(timeIntervalSince1970: 5_000)
        try store.update(
            template,
            with: draft(name: "After", goal: .ten, label: "Prize", symbol: "gift")
        )

        XCTAssertEqual(template.name, "After")
        XCTAssertEqual(template.goal, .ten)
        XCTAssertEqual(template.rewardLabel, "Prize")
        XCTAssertEqual(template.rewardSystemSymbolName, "gift")
        XCTAssertEqual(template.updatedAt, Date(timeIntervalSince1970: 5_000))
    }

    @MainActor
    func testReorderRewritesSortIndexes() throws {
        let container = try makeInMemoryContainer()
        let store = TokenBoardTemplateStore(modelContext: container.mainContext)
        let a = try store.create(draft(name: "A"))
        let b = try store.create(draft(name: "B"))
        let c = try store.create(draft(name: "C"))

        try store.reorder(templateIDs: [c.id, a.id, b.id])

        XCTAssertEqual(try store.fetchTemplates().map(\.name), ["C", "A", "B"])
    }

    @MainActor
    func testReorderRejectsMismatchedIdentifierSet() throws {
        let container = try makeInMemoryContainer()
        let store = TokenBoardTemplateStore(modelContext: container.mainContext)
        _ = try store.create(draft(name: "A"))
        let strayID = try XCTUnwrap(
            UUID(uuidString: "00000000-0000-0000-0000-0000000000FF")
        )

        XCTAssertThrowsError(try store.reorder(templateIDs: [strayID])) { error in
            XCTAssertEqual(
                error as? TokenBoardTemplateValidationError,
                .invalidTemplateOrder
            )
        }
    }

    @MainActor
    func testDeleteRemovesTemplate() throws {
        let container = try makeInMemoryContainer()
        let store = TokenBoardTemplateStore(modelContext: container.mainContext)
        let template = try store.create(draft())

        try store.delete(template)

        XCTAssertEqual(try store.fetchTemplates().count, 0)
    }

    @MainActor
    func testV1OnDiskStoreMigratesToV2AndSupportsTokenTemplates() throws {
        let fixture = makeDiskFixture()
        defer { fixture.cleanUp() }
        let boardID = try XCTUnwrap(
            UUID(uuidString: "00000000-0000-0000-0000-0000000000B1")
        )

        do {
            let container = try LocalModelContainerFactory.makeContainer(
                schema: Schema(versionedSchema: OTToolkitSchemaV1.self),
                storeURL: fixture.storeURL
            )
            let store = FirstThenBoardStore(modelContext: container.mainContext)
            _ = try store.create(firstThenDraft(name: "Persisted Routine"), boardID: boardID)
        }

        do {
            let container = try LocalModelContainerFactory.makeAppContainer(
                storeURL: fixture.storeURL
            )
            let boards = try FirstThenBoardStore(modelContext: container.mainContext).fetchBoards()
            XCTAssertEqual(boards.map(\.id), [boardID])
            XCTAssertEqual(boards.map(\.name), ["Persisted Routine"])

            let tokenStore = TokenBoardTemplateStore(modelContext: container.mainContext)
            XCTAssertEqual(try tokenStore.fetchTemplates().count, 0)
            _ = try tokenStore.create(draft(name: "Reward Chart"))
            XCTAssertEqual(try tokenStore.fetchTemplates().map(\.name), ["Reward Chart"])
        }
    }

    @MainActor
    func testConfirmedResetRemovesTemplatesAndRemainsIdempotent() throws {
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
            _ = try TokenBoardTemplateStore(modelContext: container.mainContext).create(draft())
        }
        try lifecycle.secureCurrentContent()

        try lifecycle.reset(authorization: .confirmed)

        do {
            let container = try XCTUnwrap(lifecycle.modelContainer)
            XCTAssertEqual(
                try container.mainContext.fetchCount(FetchDescriptor<TokenBoardTemplate>()),
                0
            )
        }

        try lifecycle.reset(authorization: .confirmed)
        XCTAssertEqual(lifecycle.state, .ready)
    }

    // MARK: - Helpers

    @MainActor
    private func makeInMemoryContainer() throws -> ModelContainer {
        let schema = LocalModelContainerFactory.appSchema
        let configuration = ModelConfiguration(
            "TokenBoardTemplateStoreTests",
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
        name: String = "Reward Chart",
        goal: TokenBoardGoal = .five,
        label: String = "Sticker",
        symbol: String = "star.fill"
    ) -> TokenBoardTemplateDraft {
        TokenBoardTemplateDraft(
            name: name,
            goal: goal,
            reward: TokenBoardReward(label: label, systemSymbolName: symbol)
        )
    }

    private func firstThenDraft(name: String) -> FirstThenBoardDraft {
        FirstThenBoardDraft(
            name: name,
            first: FirstThenItemDraft(label: "Finish task", systemSymbolName: "checklist"),
            then: FirstThenItemDraft(
                label: "Take a break",
                systemSymbolName: "figure.mind.and.body"
            )
        )
    }

    private func makeDiskFixture() -> TokenDiskFixture {
        let fileManager = FileManager.default
        let root = fileManager.temporaryDirectory.appendingPathComponent(
            "TokenBoardTemplateStoreTests-\(UUID().uuidString)",
            isDirectory: true
        )
        try? fileManager.createDirectory(at: root, withIntermediateDirectories: true)
        return TokenDiskFixture(fileManager: fileManager, root: root)
    }
}

private struct TokenDiskFixture {
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
