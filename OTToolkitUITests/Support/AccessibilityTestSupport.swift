import XCTest

@MainActor
enum AccessibilityTestSupport {
    static func launchApplication(usesLargestAccessibilityText: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(en)",
            "-AppleLocale", "en_US",
            "-disable-animations",
        ]
        if usesLargestAccessibilityText {
            app.launchArguments.append("-ui-test-largest-accessibility-text")
        }
        app.launch()
        return app
    }

    static func element(in app: XCUIApplication, identifier: String) -> XCUIElement {
        app.descendants(matching: .any)[identifier]
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
