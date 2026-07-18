import Observation
import SwiftData

enum AppDataState: Equatable, Sendable {
    case ready
    case recoveryRequired
}

@MainActor
@Observable
final class AppDataController {
    private let usesInMemoryStore: Bool
    private var lifecycle: LocalStoreContainerLifecycle?

    private(set) var state = AppDataState.recoveryRequired
    private(set) var modelContainer: ModelContainer?

    init(usesInMemoryStore: Bool = false) {
        self.usesInMemoryStore = usesInMemoryStore
        start()
    }

    func retry() {
        start()
    }

    @discardableResult
    func reset() -> Bool {
        if usesInMemoryStore {
            return startInMemory()
        }

        guard let lifecycle else {
            state = .recoveryRequired
            modelContainer = nil
            return false
        }

        do {
            try lifecycle.reset(authorization: .confirmed)
            modelContainer = lifecycle.modelContainer
            state = modelContainer == nil ? .recoveryRequired : .ready
            return state == .ready
        } catch {
            modelContainer = nil
            state = .recoveryRequired
            return false
        }
    }

    private func start() {
        if usesInMemoryStore {
            _ = startInMemory()
            return
        }

        do {
            let lifecycle = try lifecycle ?? makeLifecycle()
            self.lifecycle = lifecycle
            try lifecycle.start()
            modelContainer = lifecycle.modelContainer
            state = modelContainer == nil ? .recoveryRequired : .ready
        } catch {
            modelContainer = nil
            state = .recoveryRequired
        }
    }

    private func startInMemory() -> Bool {
        do {
            let schema = LocalModelContainerFactory.appSchema
            let configuration = ModelConfiguration(
                "OTToolkitUITests",
                schema: schema,
                isStoredInMemoryOnly: true,
                cloudKitDatabase: .none
            )
            modelContainer = try ModelContainer(
                for: schema,
                migrationPlan: OTToolkitSchemaMigrationPlan.self,
                configurations: [configuration]
            )
            state = .ready
            return true
        } catch {
            modelContainer = nil
            state = .recoveryRequired
            return false
        }
    }

    private func makeLifecycle() throws -> LocalStoreContainerLifecycle {
        LocalStoreContainerLifecycle(
            layout: try LocalStoreLayout.applicationSupport(),
            makeContainer: LocalModelContainerFactory.makeAppContainer(storeURL:)
        )
    }
}
