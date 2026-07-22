import XCTest
import UIKit

final class AdaptiveNavigationUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testNativeNavigationUsesExpectedLayoutAndPreservesToolWhenSwitchingSections() {
        let app = AccessibilityTestSupport.launchApplication()
        let compactNavigation = AccessibilityTestSupport.element(
            in: app,
            identifier: "navigation.compact"
        )
        let regularNavigation = AccessibilityTestSupport.element(
            in: app,
            identifier: "navigation.regular"
        )
        let usesCompactTabs: Bool

        switch UIDevice.current.userInterfaceIdiom {
        case .phone:
            XCTAssertTrue(compactNavigation.waitForExistence(timeout: 5))
            XCTAssertFalse(regularNavigation.exists)
            usesCompactTabs = true
        case .pad:
            XCTAssertTrue(regularNavigation.waitForExistence(timeout: 5))
            XCTAssertFalse(compactNavigation.exists)
            usesCompactTabs = false
        default:
            XCTFail("The native navigation test requires an iPhone or iPad simulator.")
            return
        }

        AccessibilityTestSupport.showToolsContentIfNeeded(in: app)
        openVisualTimer(in: app)

        if usesCompactTabs {
            app.tabBars.buttons["Saved"].tap()
            XCTAssertTrue(
                AccessibilityTestSupport.element(
                    in: app,
                    identifier: "navigation.content.saved"
                ).waitForExistence(timeout: 5)
            )

            app.tabBars.buttons["Settings"].tap()
            XCTAssertTrue(
                AccessibilityTestSupport.element(
                    in: app,
                    identifier: "navigation.content.settings"
                ).waitForExistence(timeout: 5)
            )

            app.tabBars.buttons["Tools"].tap()
        } else {
            revealSidebarIfNeeded(in: app)
            let savedSidebarItem = AccessibilityTestSupport.element(
                in: app,
                identifier: "navigation.sidebar.saved"
            )
            XCTAssertTrue(savedSidebarItem.waitForExistence(timeout: 5))
            savedSidebarItem.tap()
            XCTAssertTrue(
                AccessibilityTestSupport.element(
                    in: app,
                    identifier: "navigation.content.saved"
                ).waitForExistence(timeout: 5)
            )

            let settingsSidebarItem = AccessibilityTestSupport.element(
                in: app,
                identifier: "navigation.sidebar.settings"
            )
            XCTAssertTrue(settingsSidebarItem.waitForExistence(timeout: 5))
            settingsSidebarItem.tap()
            XCTAssertTrue(
                AccessibilityTestSupport.element(
                    in: app,
                    identifier: "navigation.content.settings"
                ).waitForExistence(timeout: 5)
            )

            let toolsSidebarItem = AccessibilityTestSupport.element(
                in: app,
                identifier: "navigation.sidebar.tools"
            )
            XCTAssertTrue(toolsSidebarItem.waitForExistence(timeout: 5))
            toolsSidebarItem.tap()
        }

        XCTAssertTrue(
            AccessibilityTestSupport.element(
                in: app,
                identifier: "tool.visualTimer.destination"
            ).waitForExistence(timeout: 5)
        )
    }

    @MainActor
    func testForcedCompactNavigationProvidesTabsAndTypedToolRoute() {
        let app = AccessibilityTestSupport.launchApplication(forcesCompactNavigation: true)

        XCTAssertTrue(
            AccessibilityTestSupport.element(
                in: app,
                identifier: "navigation.compact"
            ).waitForExistence(timeout: 5)
        )
        XCTAssertFalse(
            AccessibilityTestSupport.element(
                in: app,
                identifier: "navigation.regular"
            ).exists
        )
        XCTAssertTrue(app.tabBars.buttons["Tools"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.tabBars.buttons["Saved"].exists)
        XCTAssertTrue(app.tabBars.buttons["Settings"].exists)

        openVisualTimer(in: app)
    }

    @MainActor
    func testIPadPreservesTypedToolRouteAcrossRuntimeLayoutChanges() throws {
        guard UIDevice.current.userInterfaceIdiom == .pad else {
            throw XCTSkip("This transition requires a regular-width iPad simulator.")
        }

        let app = AccessibilityTestSupport.launchApplication(
            enablesLayoutToggleFixture: true
        )
        let compactNavigation = AccessibilityTestSupport.element(
            in: app,
            identifier: "navigation.compact"
        )
        let regularNavigation = AccessibilityTestSupport.element(
            in: app,
            identifier: "navigation.regular"
        )
        let toggle = AccessibilityTestSupport.element(
            in: app,
            identifier: "ui-test.navigation.layout.toggle"
        )

        XCTAssertTrue(regularNavigation.waitForExistence(timeout: 5))
        AccessibilityTestSupport.showToolsContentIfNeeded(in: app)
        openVisualTimer(in: app)
        AccessibilityTestSupport.element(
            in: app,
            identifier: "visualTimer.action.start"
        ).tap()
        XCTAssertTrue(
            AccessibilityTestSupport.element(
                in: app,
                identifier: "visualTimer.status.running"
            ).waitForExistence(timeout: 5)
        )
        AccessibilityTestSupport.assertMinimumHitTarget(toggle)

        toggle.tap()
        XCTAssertTrue(compactNavigation.waitForExistence(timeout: 5))
        assertVisualTimerDestinationExists(in: app)
        XCTAssertTrue(
            AccessibilityTestSupport.element(
                in: app,
                identifier: "visualTimer.status.running"
            ).exists
        )

        toggle.tap()
        XCTAssertTrue(regularNavigation.waitForExistence(timeout: 5))
        assertVisualTimerDestinationExists(in: app)
        XCTAssertTrue(
            AccessibilityTestSupport.element(
                in: app,
                identifier: "visualTimer.status.running"
            ).exists
        )
    }

    @MainActor
    func testPrivacyCoverMakesUnderlyingContentInert() {
        let app = AccessibilityTestSupport.launchApplication(
            forcesPrivacyCover: true,
            startsInChildFacingFixture: true
        )
        let privacyCover = AccessibilityTestSupport.element(
            in: app,
            identifier: "privacy.cover"
        )
        let underlyingChildContent = AccessibilityTestSupport.element(
            in: app,
            identifier: "child.fixture"
        )
        let underlyingVisualTimer = AccessibilityTestSupport.element(
            in: app,
            identifier: "home.tool.visualTimer"
        )

        XCTAssertTrue(privacyCover.waitForExistence(timeout: 5))
        XCTAssertTrue(privacyCover.label.contains("OT Toolkit"))
        XCTAssertTrue(privacyCover.label.contains("Content hidden for privacy."))
        AccessibilityTestSupport.assertSuppressed(underlyingChildContent)
        AccessibilityTestSupport.assertSuppressed(underlyingVisualTimer)
    }

    @MainActor
    func testAdultExitRequiresConfirmationAndPreservesToolRoute() {
        let app = AccessibilityTestSupport.launchApplication(
            forcesCompactNavigation: true,
            startsInChildFacingFixture: true
        )
        let childFixture = AccessibilityTestSupport.element(
            in: app,
            identifier: "child.fixture"
        )
        let exitButton = app.buttons["Exit child view"]
        let underlyingTimerDestination = AccessibilityTestSupport.element(
            in: app,
            identifier: "tool.visualTimer.destination"
        )
        let underlyingTabs = ["Tools", "Saved", "Settings"].map {
            app.tabBars.buttons[$0].firstMatch
        }

        XCTAssertTrue(childFixture.waitForExistence(timeout: 5))
        XCTAssertFalse(underlyingTimerDestination.isHittable)
        // System TabView can retain enabled backing nodes even when the shell is accessibility-hidden.
        for tab in underlyingTabs {
            XCTAssertFalse(tab.isHittable)
        }
        AccessibilityTestSupport.assertMinimumHitTarget(exitButton)

        exitButton.tap()
        let confirmation = app.alerts["Return to therapist controls?"]
        XCTAssertTrue(confirmation.waitForExistence(timeout: 5))
        confirmation.buttons["Stay in child view"].tap()
        XCTAssertTrue(childFixture.waitForExistence(timeout: 5))

        exitButton.tap()
        XCTAssertTrue(confirmation.waitForExistence(timeout: 5))
        confirmation.buttons["Return to controls"].tap()

        XCTAssertFalse(childFixture.exists)
        assertVisualTimerDestinationExists(in: app)
        let toolsTabAfterExit = app.tabBars.buttons["Tools"].firstMatch
        XCTAssertTrue(toolsTabAfterExit.isEnabled)
        XCTAssertTrue(toolsTabAfterExit.isHittable)
    }

    @MainActor
    func testAdultExitRemainsReadableAtLargestAccessibilityTextSize() throws {
        let app = AccessibilityTestSupport.launchApplication(
            usesLargestAccessibilityText: true,
            forcesCompactNavigation: true,
            startsInChildFacingFixture: true
        )
        let window = app.windows.firstMatch
        let exitButton = app.buttons["Exit child view"]

        AccessibilityTestSupport.assertMinimumHitTarget(exitButton)
        AccessibilityTestSupport.assertFitsHorizontally(exitButton, in: window)
        try app.performAccessibilityAudit(for: [.textClipped])
    }

    @MainActor
    private func openVisualTimer(in app: XCUIApplication) {
        let visualTimer = AccessibilityTestSupport.element(
            in: app,
            identifier: "home.tool.visualTimer"
        )

        XCTAssertTrue(visualTimer.waitForExistence(timeout: 5))
        visualTimer.tap()
        assertVisualTimerDestinationExists(in: app)
    }

    @MainActor
    private func assertVisualTimerDestinationExists(in app: XCUIApplication) {
        XCTAssertTrue(
            AccessibilityTestSupport.element(
                in: app,
                identifier: "tool.visualTimer.destination"
            ).waitForExistence(timeout: 5)
        )
    }

    @MainActor
    private func revealSidebarIfNeeded(in app: XCUIApplication) {
        let showSidebarButton = app.buttons["Show Sidebar"]
        if showSidebarButton.waitForExistence(timeout: 2) {
            showSidebarButton.tap()
        }
    }
}
