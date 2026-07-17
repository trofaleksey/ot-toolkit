import XCTest

final class AppLaunchUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testAppLaunchesWithAccessibleHomeTitle() {
        let app = AccessibilityTestSupport.launchApplication()
        AccessibilityTestSupport.showToolsContentIfNeeded(in: app)

        let homeTitle = app.staticTexts["home.title"]
        XCTAssertTrue(homeTitle.waitForExistence(timeout: 5))
        XCTAssertEqual(homeTitle.label, "OT Toolkit")

        let visualTimer = AccessibilityTestSupport.element(
            in: app,
            identifier: "home.tool.visualTimer"
        )
        XCTAssertTrue(visualTimer.waitForExistence(timeout: 5))
        XCTAssertTrue(visualTimer.label.contains("Visual Timer"))
        XCTAssertTrue(visualTimer.label.contains("Start a calm visual countdown."))
    }

    @MainActor
    func testHomeRemainsReadableAtLargestAccessibilityTextSize() throws {
        let app = AccessibilityTestSupport.launchApplication(usesLargestAccessibilityText: true)
        AccessibilityTestSupport.showToolsContentIfNeeded(in: app)
        let window = app.windows.firstMatch
        let homeTitle = app.staticTexts["home.title"]
        let visualTimer = AccessibilityTestSupport.element(
            in: app,
            identifier: "home.tool.visualTimer"
        )

        AccessibilityTestSupport.assertFitsHorizontally(homeTitle, in: window)
        AccessibilityTestSupport.assertFitsHorizontally(visualTimer, in: window)
        try app.performAccessibilityAudit(for: [.textClipped])
    }

    @MainActor
    func testHomePassesFocusedAccessibilityAudit() throws {
        continueAfterFailure = true
        let app = AccessibilityTestSupport.launchApplication()
        AccessibilityTestSupport.showToolsContentIfNeeded(in: app)

        try app.performAccessibilityAudit(
            for: [
                .contrast,
                .dynamicType,
                .hitRegion,
                .sufficientElementDescription,
                .textClipped,
                .trait,
            ]
        )
    }
}
