import XCTest

final class AppLaunchUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testAppLaunchesWithAccessibleHomeTitle() {
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(en)",
            "-AppleLocale", "en_US",
            "-disable-animations",
        ]
        app.launch()

        let homeTitle = app.staticTexts["home.title"]
        XCTAssertTrue(homeTitle.waitForExistence(timeout: 5))
        XCTAssertEqual(homeTitle.label, "OT Toolkit")
    }
}
