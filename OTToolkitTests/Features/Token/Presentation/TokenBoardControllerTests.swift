import Foundation
import SwiftData
import XCTest
@testable import OTToolkit

final class TokenBoardControllerTests: XCTestCase {
    @MainActor
    func testInitialLoadExposesTemplatesInSortOrder() throws {
        let container = try makeContainer()
        let store = TokenBoardTemplateStore(modelContext: container.mainContext)
        _ = try store.create(draft(name: "First"))
        _ = try store.create(draft(name: "Second"))

        let controller = TokenBoardController(store: store)

        XCTAssertEqual(controller.templates.map(\.name), ["First", "Second"])
        XCTAssertNil(controller.failure)
    }

    @MainActor
    func testCreateAddsSnapshotAndClearsFailure() throws {
        let container = try makeContainer()
        let store = TokenBoardTemplateStore(modelContext: container.mainContext)
        let controller = TokenBoardController(store: store)

        XCTAssertTrue(controller.create(draft(name: "Reward", goal: .eight)))

        let snapshot = try XCTUnwrap(controller.templates.first)
        XCTAssertEqual(snapshot.name, "Reward")
        XCTAssertEqual(snapshot.goal, .eight)
        XCTAssertEqual(
            snapshot.reward,
            TokenBoardReward(label: "Sticker", systemSymbolName: "star.fill")
        )
        XCTAssertNil(controller.failure)
    }

    @MainActor
    func testUpdateReplacesSnapshot() throws {
        let container = try makeContainer()
        let store = TokenBoardTemplateStore(modelContext: container.mainContext)
        let controller = TokenBoardController(store: store)
        XCTAssertTrue(controller.create(draft(name: "Before", goal: .three)))
        let id = try XCTUnwrap(controller.templates.first?.id)

        XCTAssertTrue(controller.update(id: id, with: draft(name: "After", goal: .ten)))

        XCTAssertEqual(controller.template(id: id)?.name, "After")
        XCTAssertEqual(controller.template(id: id)?.goal, .ten)
    }

    @MainActor
    func testDeleteRemovesSnapshot() throws {
        let container = try makeContainer()
        let store = TokenBoardTemplateStore(modelContext: container.mainContext)
        let controller = TokenBoardController(store: store)
        XCTAssertTrue(controller.create(draft()))
        let id = try XCTUnwrap(controller.templates.first?.id)

        XCTAssertTrue(controller.delete(id: id))

        XCTAssertTrue(controller.templates.isEmpty)
    }

    @MainActor
    func testUpdateUnknownIdentifierReportsFailure() throws {
        let container = try makeContainer()
        let store = TokenBoardTemplateStore(modelContext: container.mainContext)
        let controller = TokenBoardController(store: store)
        let strayID = try XCTUnwrap(
            UUID(uuidString: "00000000-0000-0000-0000-0000000000EE")
        )

        XCTAssertFalse(controller.update(id: strayID, with: draft()))
        XCTAssertEqual(controller.failure, .update)
    }

    @MainActor
    func testLoadFailureIsSurfacedAndDismissable() {
        let controller = TokenBoardController(store: FailingTokenBoardStore())

        XCTAssertEqual(controller.failure, .load)

        controller.dismissFailure()
        XCTAssertNil(controller.failure)
    }

    @MainActor
    func testCreateFailureReportsCreateOperation() {
        let controller = TokenBoardController(store: FailingTokenBoardStore())

        XCTAssertFalse(controller.create(draft()))
        XCTAssertEqual(controller.failure, .create)
    }

    // MARK: - Helpers

    /// Returns the container so the caller keeps it alive; a released container
    /// invalidates `mainContext` and crashes the test process.
    @MainActor
    private func makeContainer() throws -> ModelContainer {
        let schema = LocalModelContainerFactory.appSchema
        let configuration = ModelConfiguration(
            "TokenBoardControllerTests",
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
        goal: TokenBoardGoal = .five
    ) -> TokenBoardTemplateDraft {
        TokenBoardTemplateDraft(
            name: name,
            goal: goal,
            reward: TokenBoardReward(label: "Sticker", systemSymbolName: "star.fill")
        )
    }
}

@MainActor
private final class FailingTokenBoardStore: TokenBoardTemplateStoring {
    private enum Failure: Error {
        case always
    }

    func create(_ draft: TokenBoardTemplateDraft) throws -> TokenBoardTemplate {
        throw Failure.always
    }

    func fetchTemplates() throws -> [TokenBoardTemplate] {
        throw Failure.always
    }

    func update(_ template: TokenBoardTemplate, with draft: TokenBoardTemplateDraft) throws {
        throw Failure.always
    }

    func delete(_ template: TokenBoardTemplate) throws {
        throw Failure.always
    }
}
