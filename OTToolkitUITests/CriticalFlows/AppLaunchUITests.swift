import XCTest

final class AppLaunchUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testAppLaunchesWithAccessibleHomeTitle() {
        let app = AccessibilityTestSupport.launchApplication()

        let homeTitle = app.staticTexts["home.title"]
        XCTAssertTrue(homeTitle.waitForExistence(timeout: 5))
        XCTAssertEqual(homeTitle.label, "OT Toolkit")

        let status = AccessibilityTestSupport.element(
            in: app,
            identifier: "home.foundation.status"
        )
        XCTAssertTrue(status.waitForExistence(timeout: 5))
        XCTAssertTrue(status.label.contains("Foundation ready"))
        XCTAssertTrue(status.label.contains("Therapy tools will appear here as they are added."))
    }

    @MainActor
    func testHomeRemainsReadableAtLargestAccessibilityTextSize() throws {
        let app = AccessibilityTestSupport.launchApplication(usesLargestAccessibilityText: true)
        let window = app.windows.firstMatch
        let homeTitle = app.staticTexts["home.title"]
        let status = AccessibilityTestSupport.element(
            in: app,
            identifier: "home.foundation.status"
        )

        AccessibilityTestSupport.assertFitsHorizontally(homeTitle, in: window)
        AccessibilityTestSupport.assertFitsHorizontally(status, in: window)
        try app.performAccessibilityAudit(for: [.textClipped])
    }

    @MainActor
    func testHomePassesFocusedAccessibilityAudit() throws {
        continueAfterFailure = true
        let app = AccessibilityTestSupport.launchApplication()

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
