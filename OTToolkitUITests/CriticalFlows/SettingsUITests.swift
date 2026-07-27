import XCTest

final class SettingsUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testSettingsExposesFeedbackTogglesDisclosuresAndReset() {
        let app = AccessibilityTestSupport.launchApplication(forcesCompactNavigation: true)
        openSettings(in: app)

        for identifier in [
            "settings.feedback.timer.sound",
            "settings.feedback.timer.haptic",
            "settings.feedback.tokenBoard.haptic",
        ] {
            let toggle = AccessibilityTestSupport.element(in: app, identifier: identifier)
            XCTAssertTrue(toggle.waitForExistence(timeout: 5), identifier)
        }

        // Required beta disclosures must be present, not buried in support docs.
        for identifier in [
            "settings.disclosure.timer",
            "settings.disclosure.backup",
            "settings.disclosure.naming",
        ] {
            XCTAssertTrue(
                AccessibilityTestSupport.element(in: app, identifier: identifier).exists,
                identifier
            )
        }

        XCTAssertTrue(
            AccessibilityTestSupport.element(
                in: app,
                identifier: "settings.reset.action"
            ).exists
        )
    }

    @MainActor
    func testResetRequiresConfirmationAndReportsSuccess() {
        let app = AccessibilityTestSupport.launchApplication(forcesCompactNavigation: true)
        openSettings(in: app)

        let resetButton = AccessibilityTestSupport.element(
            in: app,
            identifier: "settings.reset.action"
        )
        XCTAssertTrue(resetButton.waitForExistence(timeout: 5))

        // Cancelling must leave data untouched — no silent destructive recovery.
        resetButton.tap()
        let confirmation = app.alerts["Reset all app data?"]
        XCTAssertTrue(confirmation.waitForExistence(timeout: 5))
        confirmation.buttons["Keep data"].tap()

        resetButton.tap()
        XCTAssertTrue(confirmation.waitForExistence(timeout: 5))
        confirmation.buttons["Reset"].tap()

        let success = app.alerts["App data reset"]
        XCTAssertTrue(success.waitForExistence(timeout: 5))
        success.buttons["Done"].tap()

        XCTAssertTrue(resetButton.waitForExistence(timeout: 5))
    }

    @MainActor
    func testPrivacyCoverHidesSettingsContent() {
        let app = AccessibilityTestSupport.launchApplication(
            forcesCompactNavigation: true,
            forcesPrivacyCover: true
        )

        XCTAssertTrue(
            AccessibilityTestSupport.element(
                in: app,
                identifier: "privacy.cover"
            ).waitForExistence(timeout: 5)
        )
        AccessibilityTestSupport.assertSuppressed(
            AccessibilityTestSupport.element(in: app, identifier: "settings.reset.action")
        )
    }

    @MainActor
    func testSettingsRemainsReadableAtLargestAccessibilityTextSize() throws {
        let app = AccessibilityTestSupport.launchApplication(
            usesLargestAccessibilityText: true,
            forcesCompactNavigation: true
        )
        openSettings(in: app)

        XCTAssertTrue(
            AccessibilityTestSupport.element(
                in: app,
                identifier: "settings.feedback.timer.sound"
            ).waitForExistence(timeout: 5)
        )

        try app.performAccessibilityAudit(for: [.textClipped])
    }

    @MainActor
    private func openSettings(in app: XCUIApplication) {
        let tab = app.tabBars.buttons["Settings"].firstMatch
        XCTAssertTrue(tab.waitForExistence(timeout: 5))
        tab.tap()

        XCTAssertTrue(
            AccessibilityTestSupport.element(
                in: app,
                identifier: "navigation.content.settings"
            ).waitForExistence(timeout: 5)
        )
    }
}
