import XCTest

@MainActor
enum AccessibilityTestSupport {
    static func launchApplication(
        usesLargestAccessibilityText: Bool = false,
        forcesCompactNavigation: Bool = false,
        enablesLayoutToggleFixture: Bool = false,
        forcesPrivacyCover: Bool = false,
        startsInChildFacingFixture: Bool = false
    ) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(en)",
            "-AppleLocale", "en_US",
            "-disable-animations",
        ]
        if usesLargestAccessibilityText {
            app.launchArguments.append("-ui-test-largest-accessibility-text")
        }
        if forcesCompactNavigation {
            app.launchArguments.append("-ui-test-force-compact-navigation")
        }
        if enablesLayoutToggleFixture {
            app.launchArguments.append("-ui-test-enable-layout-toggle-fixture")
        }
        if forcesPrivacyCover {
            app.launchArguments.append("-ui-test-force-privacy-cover")
        }
        if startsInChildFacingFixture {
            app.launchArguments.append("-ui-test-start-child-facing-fixture")
        }
        app.launch()
        return app
    }

    static func element(in app: XCUIApplication, identifier: String) -> XCUIElement {
        app.descendants(matching: .any)[identifier]
    }

    static func showToolsContentIfNeeded(in app: XCUIApplication) {
        let visualTimer = element(in: app, identifier: "home.tool.visualTimer")
        if visualTimer.waitForExistence(timeout: 1) {
            return
        }

        let showSidebarButton = app.buttons["Show Sidebar"]
        guard showSidebarButton.waitForExistence(timeout: 2) else {
            return
        }

        showSidebarButton.tap()
        let toolsSidebarItem = element(in: app, identifier: "navigation.sidebar.tools")
        if toolsSidebarItem.waitForExistence(timeout: 5) {
            toolsSidebarItem.tap()
        }
    }

    static func assertMinimumHitTarget(
        _ element: XCUIElement,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let minimumDimension: CGFloat = 44
        let roundingTolerance: CGFloat = 0.01

        XCTAssertTrue(element.waitForExistence(timeout: 5), file: file, line: line)
        XCTAssertTrue(element.isHittable, file: file, line: line)
        XCTAssertGreaterThanOrEqual(
            element.frame.width,
            minimumDimension - roundingTolerance,
            file: file,
            line: line
        )
        XCTAssertGreaterThanOrEqual(
            element.frame.height,
            minimumDimension - roundingTolerance,
            file: file,
            line: line
        )
    }

    static func assertSuppressed(
        _ element: XCUIElement,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertFalse(element.isHittable, file: file, line: line)
        if element.exists {
            XCTAssertFalse(element.isEnabled, file: file, line: line)
        }
    }

    static func assertFitsHorizontally(
        _ element: XCUIElement,
        in window: XCUIElement,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertTrue(element.waitForExistence(timeout: 5), file: file, line: line)
        XCTAssertTrue(window.waitForExistence(timeout: 5), file: file, line: line)
        XCTAssertGreaterThan(element.frame.width, 0, file: file, line: line)
        XCTAssertGreaterThanOrEqual(
            element.frame.minX,
            window.frame.minX - 0.5,
            file: file,
            line: line
        )
        XCTAssertLessThanOrEqual(
            element.frame.maxX,
            window.frame.maxX + 0.5,
            file: file,
            line: line
        )
    }
}
