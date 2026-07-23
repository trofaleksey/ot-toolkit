import Foundation
import XCTest
@testable import OTToolkit

final class PreferencesTests: XCTestCase {
    private var suiteName = ""
    private var defaults = UserDefaults.standard

    override func setUpWithError() throws {
        suiteName = "PreferencesTests-\(UUID().uuidString)"
        defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
    }

    override func tearDownWithError() throws {
        UserDefaults().removePersistentDomain(forName: suiteName)
    }

    /// Guards acceptance criterion 1: reset can only clear preferences it knows
    /// about, so every declared preference must appear in the reset inventory.
    func testEveryPreferenceIsRegisteredForReset() {
        for preference in OTPreference.allCases {
            XCTAssertTrue(
                OTAppStorageKeys.all.contains(preference.rawValue),
                "\(preference.rawValue) is missing from OTAppStorageKeys.all"
            )
        }
        XCTAssertEqual(OTAppStorageKeys.all.count, OTPreference.allCases.count)
    }

    func testPreferenceKeysAreUniqueAndNamespaced() {
        let keys = OTPreference.allCases.map(\.rawValue)

        XCTAssertEqual(Set(keys).count, keys.count)
        XCTAssertTrue(keys.allSatisfy { $0.hasPrefix("preference.") })
    }

    @MainActor
    func testSensoryFeedbackDefaultsToOff() {
        let preferences = OTPreferences(defaults: defaults)

        for preference in OTPreference.allCases {
            XCTAssertFalse(preferences.isEnabled(preference), preference.rawValue)
        }
    }

    @MainActor
    func testPreferenceRoundTripsAndPersistsAcrossInstances() {
        let preferences = OTPreferences(defaults: defaults)

        preferences.setEnabled(true, for: .visualTimerCompletionSound)

        XCTAssertTrue(preferences.isEnabled(.visualTimerCompletionSound))
        XCTAssertTrue(OTPreferences(defaults: defaults).isEnabled(.visualTimerCompletionSound))
    }

    @MainActor
    func testPreferencesAreIndependentOfOneAnother() {
        let preferences = OTPreferences(defaults: defaults)

        preferences.setEnabled(true, for: .tokenBoardCompletionHaptic)

        XCTAssertTrue(preferences.isEnabled(.tokenBoardCompletionHaptic))
        XCTAssertFalse(preferences.isEnabled(.visualTimerCompletionHaptic))
        XCTAssertFalse(preferences.isEnabled(.visualTimerCompletionSound))
    }

    @MainActor
    func testClearingAppOwnedPreferencesRestoresDefaults() {
        let preferences = OTPreferences(defaults: defaults)
        for preference in OTPreference.allCases {
            preferences.setEnabled(true, for: preference)
        }

        AppOwnedPreferences(defaults: defaults).clear()

        for preference in OTPreference.allCases {
            XCTAssertFalse(preferences.isEnabled(preference), preference.rawValue)
        }
    }

    @MainActor
    func testTimerControllerRestoresPersistedFeedbackPreferences() {
        let preferences = OTPreferences(defaults: defaults)
        preferences.setEnabled(true, for: .visualTimerCompletionSound)
        preferences.setEnabled(true, for: .visualTimerCompletionHaptic)

        let controller = VisualTimerController(
            clock: ContinuousClock(),
            preferences: preferences
        )

        XCTAssertTrue(controller.isCompletionSoundEnabled)
        XCTAssertTrue(controller.isCompletionHapticEnabled)
    }

    @MainActor
    func testTimerControllerWritesFeedbackChangesThrough() {
        let preferences = OTPreferences(defaults: defaults)
        let controller = VisualTimerController(
            clock: ContinuousClock(),
            preferences: preferences
        )

        controller.setCompletionHapticEnabled(true)

        XCTAssertTrue(preferences.isEnabled(.visualTimerCompletionHaptic))
        XCTAssertTrue(
            VisualTimerController(clock: ContinuousClock(), preferences: preferences)
                .isCompletionHapticEnabled
        )
    }

    /// Acceptance criterion 1 end to end: a confirmed reset clears app-owned
    /// preferences as well as the store, leaves a usable container, and can run
    /// again without failing.
    @MainActor
    func testConfirmedResetClearsPreferencesAndRemainsIdempotent() throws {
        let fileManager = FileManager.default
        let root = fileManager.temporaryDirectory.appendingPathComponent(
            "PreferencesResetTests-\(UUID().uuidString)",
            isDirectory: true
        )
        try fileManager.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? fileManager.removeItem(at: root) }

        let preferences = OTPreferences(defaults: defaults)
        for preference in OTPreference.allCases {
            preferences.setEnabled(true, for: preference)
        }
        let lifecycle = LocalStoreContainerLifecycle(
            layout: LocalStoreLayout(
                contentDirectory: root.appendingPathComponent("Content", isDirectory: true)
            ),
            fileSystem: LocalStoreFileSystem(fileManager: fileManager),
            preferences: AppOwnedPreferences(defaults: defaults),
            makeContainer: LocalModelContainerFactory.makeAppContainer
        )
        try lifecycle.start()

        try lifecycle.reset(authorization: .confirmed)

        for preference in OTPreference.allCases {
            XCTAssertFalse(preferences.isEnabled(preference), preference.rawValue)
        }
        XCTAssertEqual(lifecycle.state, .ready)
        XCTAssertNotNil(lifecycle.modelContainer)

        try lifecycle.reset(authorization: .confirmed)
        XCTAssertEqual(lifecycle.state, .ready)
        XCTAssertNotNil(lifecycle.modelContainer)
    }

    @MainActor
    func testTokenBoardSessionControllerPersistsHapticPreference() {
        let preferences = OTPreferences(defaults: defaults)
        let controller = TokenBoardSessionController(preferences: preferences)
        XCTAssertFalse(controller.isCompletionHapticEnabled)

        controller.setCompletionHapticEnabled(true)

        XCTAssertTrue(preferences.isEnabled(.tokenBoardCompletionHaptic))
        XCTAssertTrue(
            TokenBoardSessionController(preferences: preferences).isCompletionHapticEnabled
        )
    }
}
