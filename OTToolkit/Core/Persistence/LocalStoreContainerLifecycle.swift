import Foundation
import SwiftData

enum OTAppStorageKeys {
    // Derived from OTPreference so reset always clears every app-owned key.
    // Declare new preferences there rather than adding raw keys here.
    static let all: Set<String> = Set(OTPreference.allCases.map(\.rawValue))
}

struct AppOwnedPreferences {
    struct Snapshot {
        fileprivate let values: [String: Any]
    }

    private let defaults: UserDefaults
    private let keys: Set<String>

    init(
        defaults: UserDefaults = .standard,
        keys: Set<String> = OTAppStorageKeys.all
    ) {
        self.defaults = defaults
        self.keys = keys
    }

    func snapshot() -> Snapshot {
        Snapshot(
            values: keys.reduce(into: [:]) { values, key in
                if let value = defaults.object(forKey: key) {
                    values[key] = value
                }
            }
        )
    }

    func clear() {
        for key in keys {
            defaults.removeObject(forKey: key)
        }
    }

    func restore(_ snapshot: Snapshot) {
        clear()
        for (key, value) in snapshot.values {
            defaults.set(value, forKey: key)
        }
    }
}

enum LocalStoreResetAuthorization: Equatable {
    case notConfirmed
    case confirmed
}

enum LocalStoreLifecycleState: Equatable {
    case idle
    case ready
    case recoveryRequired
}

enum LocalStoreLifecycleError: Error {
    case confirmationRequired
    case openingFailed(cause: any Error)
    case resetFailed(originalStorePreserved: Bool, cause: any Error)
}

extension LocalStoreLifecycleError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .confirmationRequired:
            String(localized: "persistence.error.resetConfirmationRequired")
        case .openingFailed:
            String(localized: "persistence.error.openingFailed")
        case let .resetFailed(originalStorePreserved, _):
            if originalStorePreserved {
                String(localized: "persistence.error.resetFailedDataPreserved")
            } else {
                String(localized: "persistence.error.resetFailedRestoreFailed")
            }
        }
    }
}

enum LocalModelContainerFactory {
    static func configuration(
        schema: Schema,
        storeURL: URL
    ) -> ModelConfiguration {
        ModelConfiguration(
            "OTToolkit",
            schema: schema,
            url: storeURL,
            cloudKitDatabase: .none
        )
    }

    static func makeContainer(
        schema: Schema,
        migrationPlan: (any SchemaMigrationPlan.Type)? = nil,
        storeURL: URL
    ) throws -> ModelContainer {
        let configuration = configuration(schema: schema, storeURL: storeURL)
        return try ModelContainer(
            for: schema,
            migrationPlan: migrationPlan,
            configurations: [configuration]
        )
    }
}

@MainActor
final class LocalStoreContainerLifecycle {
    typealias ContainerFactory = @MainActor (URL) throws -> ModelContainer

    private let layout: LocalStoreLayout
    private let fileSystem: LocalStoreFileSystem
    private let preferences: AppOwnedPreferences
    private let makeContainer: ContainerFactory

    private(set) var state = LocalStoreLifecycleState.idle
    private(set) var modelContainer: ModelContainer?

    init(
        layout: LocalStoreLayout,
        fileSystem: LocalStoreFileSystem = LocalStoreFileSystem(),
        preferences: AppOwnedPreferences = AppOwnedPreferences(),
        makeContainer: @escaping ContainerFactory
    ) {
        self.layout = layout
        self.fileSystem = fileSystem
        self.preferences = preferences
        self.makeContainer = makeContainer
    }

    func start() throws {
        guard state != .ready else {
            return
        }

        do {
            try fileSystem.prepareForLaunch(layout)
            let container = try makeContainer(layout.storeURL)
            try fileSystem.secureCurrentContent(layout)
            modelContainer = container
            state = .ready
        } catch {
            modelContainer = nil
            state = .recoveryRequired
            throw LocalStoreLifecycleError.openingFailed(cause: error)
        }
    }

    func secureCurrentContent() throws {
        try fileSystem.secureCurrentContent(layout)
    }

    func reset(authorization: LocalStoreResetAuthorization) throws {
        guard authorization == .confirmed else {
            throw LocalStoreLifecycleError.confirmationRequired
        }

        let preferenceSnapshot = preferences.snapshot()
        modelContainer = nil
        state = .idle

        var staging: LocalStoreResetStaging?
        var candidateContainer: ModelContainer?

        do {
            staging = try fileSystem.stageCurrentContent(layout)
            preferences.clear()
            try fileSystem.prepareFreshContent(layout)
            candidateContainer = try makeContainer(layout.storeURL)
            try fileSystem.secureCurrentContent(layout)
            try fileSystem.commitReset(layout)

            modelContainer = candidateContainer
            state = .ready
        } catch {
            candidateContainer = nil
            let recoveryError = restoreAfterFailedReset(
                staging: staging,
                preferenceSnapshot: preferenceSnapshot
            )
            let originalStorePreserved = fileSystem.originalContentIsPreserved(
                after: staging,
                layout: layout
            )

            throw LocalStoreLifecycleError.resetFailed(
                originalStorePreserved: originalStorePreserved,
                cause: recoveryError ?? error
            )
        }
    }

    private func restoreAfterFailedReset(
        staging: LocalStoreResetStaging?,
        preferenceSnapshot: AppOwnedPreferences.Snapshot
    ) -> (any Error)? {
        preferences.restore(preferenceSnapshot)

        do {
            if let staging {
                try fileSystem.rollBackReset(staging, layout: layout)
            } else {
                try fileSystem.secureCurrentContent(layout)
            }

            modelContainer = try makeContainer(layout.storeURL)
            state = .ready
            return nil
        } catch {
            modelContainer = nil
            state = .recoveryRequired
            return error
        }
    }
}
