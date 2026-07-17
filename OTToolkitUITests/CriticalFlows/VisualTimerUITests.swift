import XCTest

final class VisualTimerUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testDefaultTimerCanPauseResumeAndReset() {
        let app = AccessibilityTestSupport.launchApplication(forcesCompactNavigation: true)
        openVisualTimer(in: app)

        let start = element(in: app, identifier: "visualTimer.action.start")
        XCTAssertTrue(start.waitForExistence(timeout: 5))
        XCTAssertTrue(start.value as? String == "5 minutes")
        AccessibilityTestSupport.assertMinimumHitTarget(start)
        start.tap()

        XCTAssertTrue(
            element(in: app, identifier: "visualTimer.status.running")
                .waitForExistence(timeout: 5)
        )
        let pause = element(in: app, identifier: "visualTimer.action.pause")
        AccessibilityTestSupport.assertMinimumHitTarget(pause)
        pause.tap()

        XCTAssertTrue(
            element(in: app, identifier: "visualTimer.status.paused")
                .waitForExistence(timeout: 5)
        )
        let resume = element(in: app, identifier: "visualTimer.action.resume")
        AccessibilityTestSupport.assertMinimumHitTarget(resume)
        resume.tap()

        XCTAssertTrue(
            element(in: app, identifier: "visualTimer.status.running")
                .waitForExistence(timeout: 5)
        )
        element(in: app, identifier: "visualTimer.action.reset").tap()
        let confirmation = app.alerts["Reset this timer?"]
        XCTAssertTrue(confirmation.waitForExistence(timeout: 5))
        confirmation.buttons["Reset timer"].tap()

        XCTAssertTrue(start.waitForExistence(timeout: 5))
    }

    @MainActor
    func testTimerCompletesUsingDeterministicDuration() {
        let app = AccessibilityTestSupport.launchApplication(
            forcesCompactNavigation: true,
            timerDurationOverrideSeconds: 1
        )
        openVisualTimer(in: app)
        element(in: app, identifier: "visualTimer.action.start").tap()

        XCTAssertTrue(
            element(in: app, identifier: "visualTimer.status.completed")
                .waitForExistence(timeout: 5)
        )
        let remaining = element(in: app, identifier: "visualTimer.remaining")
        XCTAssertEqual(remaining.value as? String, "0 seconds")
        XCTAssertTrue(
            element(in: app, identifier: "visualTimer.action.another")
                .isHittable
        )
    }

    @MainActor
    func testSensoryFeedbackDefaultsOffAndLifecycleLimitsAreDisclosed() {
        let app = AccessibilityTestSupport.launchApplication(forcesCompactNavigation: true)
        openVisualTimer(in: app)

        let sound = element(in: app, identifier: "visualTimer.feedback.sound")
        let haptic = element(in: app, identifier: "visualTimer.feedback.haptic")
        XCTAssertTrue(sound.waitForExistence(timeout: 5))
        XCTAssertEqual(sound.value as? String, "0")
        XCTAssertEqual(haptic.value as? String, "0")

        for _ in 0..<3 where !sound.isHittable {
            app.swipeUp()
        }
        AccessibilityTestSupport.assertMinimumHitTarget(sound)
        sound.tap()

        for _ in 0..<2 where !haptic.isHittable {
            app.swipeUp()
        }
        AccessibilityTestSupport.assertMinimumHitTarget(haptic)
        haptic.tap()
        XCTAssertEqual(sound.value as? String, "1")
        XCTAssertEqual(haptic.value as? String, "1")

        XCTAssertTrue(
            element(in: app, identifier: "visualTimer.lifecycle.disclosure")
                .waitForExistence(timeout: 5)
        )
    }

    @MainActor
    func testChildFacingModeUsesSameRunningTimerAndConfirmedAdultExit() {
        let app = AccessibilityTestSupport.launchApplication(forcesCompactNavigation: true)
        openVisualTimer(in: app)
        element(in: app, identifier: "visualTimer.action.start").tap()
        element(in: app, identifier: "visualTimer.action.childFacing").tap()

        XCTAssertTrue(
            element(in: app, identifier: "visualTimer.child.content")
                .waitForExistence(timeout: 5)
        )
        let exit = app.buttons["Exit child view"]
        AccessibilityTestSupport.assertMinimumHitTarget(exit)
        exit.tap()

        let confirmation = app.alerts["Return to therapist controls?"]
        XCTAssertTrue(confirmation.waitForExistence(timeout: 5))
        confirmation.buttons["Return to controls"].tap()

        XCTAssertTrue(
            element(in: app, identifier: "visualTimer.status.running")
                .waitForExistence(timeout: 5)
        )
    }

    @MainActor
    func testSetupFitsAtLargestAccessibilityTextSize() throws {
        let app = AccessibilityTestSupport.launchApplication(
            usesLargestAccessibilityText: true,
            forcesCompactNavigation: true
        )
        openVisualTimer(in: app)

        let start = element(in: app, identifier: "visualTimer.action.start")
        for _ in 0..<4 where !start.isHittable {
            app.swipeUp()
        }
        AccessibilityTestSupport.assertMinimumHitTarget(start)
        AccessibilityTestSupport.assertFitsHorizontally(start, in: app.windows.firstMatch)
        try app.performAccessibilityAudit(for: [.textClipped])
    }

    @MainActor
    func testActiveTimerControlsAreVisibleInPhoneLandscape() throws {
        guard UIDevice.current.userInterfaceIdiom == .phone else {
            throw XCTSkip("This compact-height check requires an iPhone simulator.")
        }

        let app = AccessibilityTestSupport.launchApplication(forcesCompactNavigation: true)
        openVisualTimer(in: app)
        element(in: app, identifier: "visualTimer.action.start").tap()

        XCUIDevice.shared.orientation = .landscapeLeft
        defer { XCUIDevice.shared.orientation = .portrait }

        let pause = element(in: app, identifier: "visualTimer.action.pause")
        XCTAssertTrue(pause.waitForExistence(timeout: 5))
        XCTAssertTrue(pause.isHittable)
        XCTAssertTrue(element(in: app, identifier: "visualTimer.action.reset").isHittable)
        XCTAssertTrue(
            element(in: app, identifier: "visualTimer.action.childFacing").isHittable
        )
    }

    @MainActor
    private func openVisualTimer(in app: XCUIApplication) {
        let destination = element(in: app, identifier: "home.tool.visualTimer")
        XCTAssertTrue(destination.waitForExistence(timeout: 5))
        destination.tap()
        XCTAssertTrue(
            element(in: app, identifier: "tool.visualTimer.destination")
                .waitForExistence(timeout: 5)
        )
    }

    @MainActor
    private func element(in app: XCUIApplication, identifier: String) -> XCUIElement {
        AccessibilityTestSupport.element(in: app, identifier: identifier)
    }
}
