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
    func testBackShowsContinuingTimerBannerThatReopensAtLargestText() throws {
        let app = AccessibilityTestSupport.launchApplication(
            usesLargestAccessibilityText: true,
            forcesCompactNavigation: true,
            timerDurationOverrideSeconds: 30
        )
        openVisualTimer(in: app)

        let start = element(in: app, identifier: "visualTimer.action.start")
        reveal(start, in: app)
        start.tap()
        XCTAssertTrue(
            element(in: app, identifier: "visualTimer.status.running")
                .waitForExistence(timeout: 5)
        )

        let navigationBar = app.navigationBars["Visual Timer"]
        XCTAssertTrue(navigationBar.waitForExistence(timeout: 5))
        let back = navigationBar.buttons.firstMatch
        XCTAssertTrue(back.waitForExistence(timeout: 5))
        back.tap()

        let banner = element(in: app, identifier: "visualTimer.banner")
        XCTAssertTrue(banner.waitForExistence(timeout: 5))
        AccessibilityTestSupport.assertMinimumHitTarget(banner)
        AccessibilityTestSupport.assertFitsHorizontally(banner, in: app.windows.firstMatch)
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5))
        XCTAssertLessThanOrEqual(banner.frame.maxY, tabBar.frame.minY + 0.5)
        try app.performAccessibilityAudit(for: [.textClipped])

        let initialBannerValue = try XCTUnwrap(banner.value as? String)
        XCTAssertTrue(initialBannerValue.contains("Timer running"))
        let countdownContinues = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "value != %@", initialBannerValue),
            object: banner
        )
        XCTAssertEqual(XCTWaiter.wait(for: [countdownContinues], timeout: 5), .completed)
        XCTAssertTrue((banner.value as? String)?.contains("Timer running") == true)
        XCTAssertTrue(banner.isHittable)

        banner.tap()
        XCTAssertTrue(
            element(in: app, identifier: "tool.visualTimer.destination")
                .waitForExistence(timeout: 10),
            "Tapping the active timer banner did not reopen Visual Timer."
        )
        XCTAssertTrue(
            element(in: app, identifier: "visualTimer.status.running")
                .waitForExistence(timeout: 10),
            "Visual Timer reopened without showing the running state."
        )
        XCTAssertFalse(banner.exists)
    }

    @MainActor
    func testTimerCompletesUsingDeterministicDurationAtLargestAccessibilityTextSize() throws {
        let app = AccessibilityTestSupport.launchApplication(
            usesLargestAccessibilityText: true,
            forcesCompactNavigation: true,
            timerDurationOverrideSeconds: 1
        )
        openVisualTimer(in: app)

        let start = element(in: app, identifier: "visualTimer.action.start")
        reveal(start, in: app)
        start.tap()

        let window = app.windows.firstMatch
        let completed = element(in: app, identifier: "visualTimer.status.completed")
        XCTAssertTrue(completed.waitForExistence(timeout: 5))
        AccessibilityTestSupport.assertFitsHorizontally(completed, in: window)

        let remaining = element(in: app, identifier: "visualTimer.remaining")
        XCTAssertEqual(remaining.value as? String, "0 seconds")
        AccessibilityTestSupport.assertFitsHorizontally(remaining, in: window)
        try app.performAccessibilityAudit(for: [.textClipped])

        let anotherTimer = element(in: app, identifier: "visualTimer.action.another")
        reveal(anotherTimer, in: app)
        AccessibilityTestSupport.assertMinimumHitTarget(anotherTimer)
        AccessibilityTestSupport.assertFitsHorizontally(anotherTimer, in: window)
        try app.performAccessibilityAudit(for: [.textClipped])
    }

    @MainActor
    func testSensoryFeedbackFitsAtLargestAccessibilityTextSize() throws {
        let app = AccessibilityTestSupport.launchApplication(
            usesLargestAccessibilityText: true,
            forcesCompactNavigation: true
        )
        openVisualTimer(in: app)

        let window = app.windows.firstMatch
        let sound = element(in: app, identifier: "visualTimer.feedback.sound")
        let haptic = element(in: app, identifier: "visualTimer.feedback.haptic")
        XCTAssertTrue(sound.waitForExistence(timeout: 5))
        XCTAssertEqual(sound.value as? String, "0")
        XCTAssertEqual(haptic.value as? String, "0")

        reveal(sound, in: app)
        AccessibilityTestSupport.assertMinimumHitTarget(sound)
        AccessibilityTestSupport.assertFitsHorizontally(sound, in: window)
        try app.performAccessibilityAudit(for: [.textClipped])
        tapSwitch(sound)
        XCTAssertEqual(sound.value as? String, "1")

        reveal(haptic, in: app)
        AccessibilityTestSupport.assertMinimumHitTarget(haptic)
        AccessibilityTestSupport.assertFitsHorizontally(haptic, in: window)
        try app.performAccessibilityAudit(for: [.textClipped])
        tapSwitch(haptic)
        XCTAssertEqual(haptic.value as? String, "1")

        let disclosure = element(in: app, identifier: "visualTimer.lifecycle.disclosure")
        reveal(disclosure, in: app, requiresHittable: false)
        AccessibilityTestSupport.assertFitsHorizontally(disclosure, in: window)
        try app.performAccessibilityAudit(for: [.textClipped])

        let alertsDisclosure = element(
            in: app,
            identifier: "visualTimer.lifecycle.alertsDisclosure"
        )
        reveal(alertsDisclosure, in: app, requiresHittable: false)
        AccessibilityTestSupport.assertFitsHorizontally(alertsDisclosure, in: window)
        try app.performAccessibilityAudit(for: [.textClipped])
    }

    @MainActor
    func testCompletedTimerActionRemainsReachableInPhoneLandscapeAtLargestText() throws {
        guard UIDevice.current.userInterfaceIdiom == .phone else {
            throw XCTSkip("This compact-height check requires an iPhone simulator.")
        }

        let app = AccessibilityTestSupport.launchApplication(
            usesLargestAccessibilityText: true,
            forcesCompactNavigation: true,
            timerDurationOverrideSeconds: 1
        )
        openVisualTimer(in: app)

        let start = element(in: app, identifier: "visualTimer.action.start")
        reveal(start, in: app)
        start.tap()
        XCTAssertTrue(
            element(in: app, identifier: "visualTimer.status.completed")
                .waitForExistence(timeout: 5)
        )

        XCUIDevice.shared.orientation = .landscapeLeft
        defer { XCUIDevice.shared.orientation = .portrait }

        let anotherTimer = element(in: app, identifier: "visualTimer.action.another")
        reveal(anotherTimer, in: app)
        AccessibilityTestSupport.assertMinimumHitTarget(anotherTimer)
        AccessibilityTestSupport.assertFitsHorizontally(anotherTimer, in: app.windows.firstMatch)
        try app.performAccessibilityAudit(for: [.textClipped])
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

    @MainActor
    private func tapSwitch(_ element: XCUIElement) {
        element.coordinate(withNormalizedOffset: CGVector(dx: 1, dy: 0.5))
            .withOffset(CGVector(dx: -25, dy: 0))
            .tap()
    }

    @MainActor
    private func reveal(
        _ element: XCUIElement,
        in app: XCUIApplication,
        maximumSwipes: Int = 8,
        requiresHittable: Bool = true
    ) {
        XCTAssertTrue(element.waitForExistence(timeout: 5))
        for _ in 0..<maximumSwipes {
            if isFullyVisible(element, in: app, requiresHittable: requiresHittable) {
                break
            }

            let shouldScrollDown = element.frame.minY < app.windows.firstMatch.frame.minY
            let startY = shouldScrollDown ? 0.35 : 0.75
            let endY = shouldScrollDown ? 0.75 : 0.35
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: startY))
                .press(
                    forDuration: 0.05,
                    thenDragTo: app.coordinate(
                        withNormalizedOffset: CGVector(dx: 0.5, dy: endY)
                    )
                )
        }
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(
            isFullyVisible(element, in: app, requiresHittable: requiresHittable),
            "Element \(element.identifier) with frame \(element.frame) did not fit in "
                + "window \(app.windows.firstMatch.frame) above tab bar \(tabBar.frame)."
        )
    }

    @MainActor
    private func isFullyVisible(
        _ element: XCUIElement,
        in app: XCUIApplication,
        requiresHittable: Bool
    ) -> Bool {
        if requiresHittable, !element.isHittable {
            return false
        }

        let windowFrame = app.windows.firstMatch.frame
        let tabBar = app.tabBars.firstMatch
        let visibleBottom = tabBar.exists ? tabBar.frame.minY : windowFrame.maxY
        let tolerance: CGFloat = 0.5

        return element.frame.minY >= windowFrame.minY - tolerance
            && element.frame.maxY <= visibleBottom + tolerance
    }
}
