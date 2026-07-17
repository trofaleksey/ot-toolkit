import Foundation
import SwiftData
import XCTest
@testable import OTToolkit

@Model
private final class LocalStoreProbe {
    var value: String

    init(value: String) {
        self.value = value
    }
}

final class LocalStoreContainerLifecycleTests: XCTestCase {
    private enum ProbeError: Error {
        case expectedFailure
    }

    private struct Fixture {
        let fileManager: FileManager
        let testRoot: URL
        let layout: LocalStoreLayout
        let preferenceKey: String

        func cleanUp() {
            UserDefaults.standard.removeObject(forKey: preferenceKey)
            if fileManager.fileExists(atPath: testRoot.path) {
                try? fileManager.removeItem(at: testRoot)
            }
        }
    }

    @MainActor
    func testConfigurationExplicitlyDisablesCloudKit() {
        let fixture = makeFixture()
        defer { fixture.cleanUp() }
        let schema = probeSchema
        let configuration = LocalModelContainerFactory.configuration(
            schema: schema,
            storeURL: fixture.layout.storeURL
        )
        let expected = ModelConfiguration(
            "OTToolkit",
            schema: schema,
            url: fixture.layout.storeURL,
            cloudKitDatabase: .none
        )

        XCTAssertEqual(configuration, expected)
        XCTAssertTrue(configuration.debugDescription.contains("_automatic: false"))
        XCTAssertTrue(configuration.debugDescription.contains("_none: true"))
        XCTAssertNil(configuration.cloudKitContainerIdentifier)
    }

    @MainActor
    func testUnconfirmedResetDoesNotMutateStoreOrPreferences() throws {
        let fixture = makeFixture()
        defer { fixture.cleanUp() }
        let subject = makeLifecycle(fixture: fixture)
        try subject.start()
        try insertProbe(value: "preserved", into: subject)
        UserDefaults.standard.set("preserved", forKey: fixture.preferenceKey)

        XCTAssertThrowsError(
            try subject.reset(authorization: .notConfirmed)
        ) { error in
            guard case LocalStoreLifecycleError.confirmationRequired = error else {
                return XCTFail("Expected confirmationRequired, got \(error)")
            }
        }

        XCTAssertEqual(try probeValues(in: subject), ["preserved"])
        XCTAssertEqual(
            UserDefaults.standard.string(forKey: fixture.preferenceKey),
            "preserved"
        )
        XCTAssertEqual(subject.state, .ready)
    }

    @MainActor
    func testConfirmedResetSucceedsTwiceAgainstRealOnDiskStore() throws {
        let fixture = makeFixture()
        defer { fixture.cleanUp() }
        let subject = makeLifecycle(fixture: fixture)
        try subject.start()
        try insertProbe(value: "remove me", into: subject)
        UserDefaults.standard.set(true, forKey: fixture.preferenceKey)

        let appOwnedFile = fixture.layout.filesDirectory.appendingPathComponent(
            "synthetic-board.fixture"
        )
        let cacheFile = fixture.layout.cachesDirectory.appendingPathComponent(
            "synthetic-cache.fixture"
        )
        let temporaryFile = fixture.layout.temporaryDirectory.appendingPathComponent(
            "synthetic-temp.fixture"
        )
        for url in [appOwnedFile, cacheFile, temporaryFile] {
            XCTAssertTrue(
                fixture.fileManager.createFile(
                    atPath: url.path,
                    contents: Data("synthetic".utf8)
                )
            )
        }

        try subject.reset(authorization: .confirmed)

        XCTAssertEqual(try probeValues(in: subject), [])
        XCTAssertNil(UserDefaults.standard.object(forKey: fixture.preferenceKey))
        XCTAssertFalse(fixture.fileManager.fileExists(atPath: appOwnedFile.path))
        XCTAssertFalse(fixture.fileManager.fileExists(atPath: cacheFile.path))
        XCTAssertFalse(fixture.fileManager.fileExists(atPath: temporaryFile.path))
        XCTAssertEqual(subject.state, .ready)

        try subject.reset(authorization: .confirmed)

        XCTAssertEqual(try probeValues(in: subject), [])
        XCTAssertEqual(subject.state, .ready)
        XCTAssertFalse(
            fixture.fileManager.fileExists(atPath: fixture.layout.resetBackupDirectory.path)
        )
    }

    @MainActor
    func testFailedFreshContainerValidationRestoresOriginalStoreAndPreferences() throws {
        let fixture = makeFixture()
        defer { fixture.cleanUp() }
        let schema = probeSchema
        var factoryInvocation = 0
        let subject = makeLifecycle(fixture: fixture) { storeURL in
            factoryInvocation += 1
            if factoryInvocation == 2 {
                throw ProbeError.expectedFailure
            }
            return try LocalModelContainerFactory.makeContainer(
                schema: schema,
                storeURL: storeURL
            )
        }
        try subject.start()
        try insertProbe(value: "original", into: subject)
        UserDefaults.standard.set("original", forKey: fixture.preferenceKey)

        XCTAssertThrowsError(
            try subject.reset(authorization: .confirmed)
        ) { error in
            guard case let LocalStoreLifecycleError.resetFailed(originalStorePreserved, _) = error
            else {
                return XCTFail("Expected resetFailed, got \(error)")
            }
            XCTAssertTrue(originalStorePreserved)
        }

        XCTAssertEqual(factoryInvocation, 3)
        XCTAssertEqual(try probeValues(in: subject), ["original"])
        XCTAssertEqual(
            UserDefaults.standard.string(forKey: fixture.preferenceKey),
            "original"
        )
        XCTAssertEqual(subject.state, .ready)
        XCTAssertFalse(
            fixture.fileManager.fileExists(atPath: fixture.layout.resetBackupDirectory.path)
        )
    }

    @MainActor
    func testOpeningFailurePreservesStoreAndRecoveryResetStillRequiresConfirmation() throws {
        let fixture = makeFixture()
        defer { fixture.cleanUp() }

        var seedLifecycle: LocalStoreContainerLifecycle? = makeLifecycle(fixture: fixture)
        try seedLifecycle?.start()
        try insertProbe(value: "original", into: try XCTUnwrap(seedLifecycle))
        seedLifecycle = nil

        let failingLifecycle = makeLifecycle(fixture: fixture) { _ in
            throw ProbeError.expectedFailure
        }
        XCTAssertThrowsError(try failingLifecycle.start()) { error in
            guard case LocalStoreLifecycleError.openingFailed = error else {
                return XCTFail("Expected openingFailed, got \(error)")
            }
        }
        XCTAssertEqual(failingLifecycle.state, .recoveryRequired)

        XCTAssertThrowsError(
            try failingLifecycle.reset(authorization: .notConfirmed)
        ) { error in
            guard case LocalStoreLifecycleError.confirmationRequired = error else {
                return XCTFail("Expected confirmationRequired, got \(error)")
            }
        }

        let reopenedLifecycle = makeLifecycle(fixture: fixture)
        try reopenedLifecycle.start()
        XCTAssertEqual(try probeValues(in: reopenedLifecycle), ["original"])
    }

    @MainActor
    private var probeSchema: Schema {
        Schema([LocalStoreProbe.self])
    }

    @MainActor
    private func makeFixture() -> Fixture {
        let fileManager = FileManager.default
        let testRoot = fileManager.temporaryDirectory.appendingPathComponent(
            "LocalStoreContainerLifecycleTests-\(UUID().uuidString)",
            isDirectory: true
        )
        return Fixture(
            fileManager: fileManager,
            testRoot: testRoot,
            layout: LocalStoreLayout(
                contentDirectory: testRoot.appendingPathComponent("Content")
            ),
            preferenceKey: "local-store-test-\(UUID().uuidString)"
        )
    }

    @MainActor
    private func makeLifecycle(
        fixture: Fixture,
        factory: LocalStoreContainerLifecycle.ContainerFactory? = nil
    ) -> LocalStoreContainerLifecycle {
        let schema = probeSchema
        return LocalStoreContainerLifecycle(
            layout: fixture.layout,
            fileSystem: LocalStoreFileSystem(fileManager: fixture.fileManager),
            preferences: AppOwnedPreferences(
                defaults: .standard,
                keys: [fixture.preferenceKey]
            ),
            makeContainer: factory ?? { storeURL in
                try LocalModelContainerFactory.makeContainer(
                    schema: schema,
                    storeURL: storeURL
                )
            }
        )
    }

    @MainActor
    private func insertProbe(
        value: String,
        into lifecycle: LocalStoreContainerLifecycle
    ) throws {
        let container = try XCTUnwrap(lifecycle.modelContainer)
        container.mainContext.insert(LocalStoreProbe(value: value))
        try container.mainContext.save()
        try lifecycle.secureCurrentContent()
    }

    @MainActor
    private func probeValues(in lifecycle: LocalStoreContainerLifecycle) throws -> [String] {
        let container = try XCTUnwrap(lifecycle.modelContainer)
        return try container.mainContext
            .fetch(FetchDescriptor<LocalStoreProbe>())
            .map(\.value)
            .sorted()
    }
}
