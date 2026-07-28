import XCTest

@MainActor
enum AccessibilityTestSupport {
    static func launchApplication(
        usesLargestAccessibilityText: Bool = false,
        forcesCompactNavigation: Bool = false,
        enablesLayoutToggleFixture: Bool = false,
        forcesPrivacyCover: Bool = false,
        seedsFirstThenBoard: Bool = false,
        seedsFirstThenSchedule: Bool = false,
        seedsTokenBoard: Bool = false,
        seedsChoiceBoard: Bool = false,
        startsInChildFacingFixture: Bool = false,
        timerDurationOverrideSeconds: Int? = nil
    ) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(en)",
            "-AppleLocale", "en_US",
            "-disable-animations",
            "-ui-test-in-memory-store",
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
        if seedsFirstThenBoard {
            app.launchArguments.append("-ui-test-seed-first-then-board")
        }
        if seedsFirstThenSchedule {
            app.launchArguments.append("-ui-test-seed-first-then-schedule")
        }
        if seedsTokenBoard {
            app.launchArguments.append("-ui-test-seed-token-board")
        }
        if seedsChoiceBoard {
            app.launchArguments.append("-ui-test-seed-choice-board")
        }
        if startsInChildFacingFixture {
            app.launchArguments.append("-ui-test-start-child-facing-fixture")
        }
        if let timerDurationOverrideSeconds {
            app.launchArguments.append(contentsOf: [
                "-ui-test-timer-duration-seconds",
                String(timerDurationOverrideSeconds),
            ])
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

    // MARK: - Scrolling and interaction
    //
    // These live here because three suites had drifted into three different
    // versions of the same helper, each fixing a bug the others still had.
    // The bugs were all the same shape: a control can report `isHittable`
    // while the point `tap()` actually targets — its centre — is underneath
    // the tab bar or the software keyboard, so the tap silently goes to the
    // chrome instead.

    /// Lowest y coordinate a tap can safely land on.
    static func contentBottom(in app: XCUIApplication) -> CGFloat {
        var bottom = app.windows.firstMatch.frame.maxY

        let keyboard = app.keyboards.firstMatch
        if keyboard.exists, keyboard.frame.height > 0 {
            bottom = min(bottom, keyboard.frame.minY)
        }

        let tabBar = app.tabBars.firstMatch
        if tabBar.exists {
            bottom = min(bottom, tabBar.frame.minY)
        }

        return bottom
    }

    /// True when the element's tap point is on screen and not covered.
    ///
    /// Deliberately tests the centre rather than the whole frame: a control
    /// taller than the remaining scroll travel can never get its bottom edge
    /// above the bar, and requiring that would reject a control that taps
    /// perfectly well.
    static func isTapPointClear(_ element: XCUIElement, in app: XCUIApplication) -> Bool {
        guard element.exists, element.isHittable else { return false }
        let frame = element.frame
        return frame.midY > app.windows.firstMatch.frame.minY
            && frame.midY < contentBottom(in: app)
    }

    /// Scrolls until the element's tap point is clear, in whichever direction
    /// is needed.
    static func reveal(
        _ element: XCUIElement,
        in app: XCUIApplication,
        maximumSwipes: Int = 12,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        // Existence is checked inside the loop, not up front: at the largest
        // text size an element below the fold is not in the accessibility
        // snapshot at all until the view is scrolled toward it, so waiting for
        // it first would fail before any scrolling happened.
        for _ in 0..<maximumSwipes {
            if isTapPointClear(element, in: app) {
                return
            }
            // Only scroll back up for an element known to sit above the
            // viewport. A missing element reports a zero frame, which would
            // otherwise be read as "above" and send us the wrong way forever.
            if element.exists, element.frame.midY <= app.windows.firstMatch.frame.minY {
                app.swipeDown()
            } else {
                app.swipeUp()
            }
        }

        XCTAssertTrue(
            isTapPointClear(element, in: app),
            "\(element.identifier) tap point \(element.frame.midY) is not clear of "
                + "\(contentBottom(in: app)).",
            file: file,
            line: line
        )
    }

    /// Scrolls in both directions until the element is in the accessibility
    /// hierarchy. Use when reading an element rather than tapping it: content
    /// far outside the viewport is not in the snapshot at all.
    static func revealForReading(
        _ element: XCUIElement,
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        for _ in 0..<6 where !element.exists {
            app.swipeDown()
        }
        for _ in 0..<6 where !element.exists {
            app.swipeUp()
        }
        XCTAssertTrue(element.waitForExistence(timeout: 5), file: file, line: line)
    }

    static func tap(
        _ element: XCUIElement,
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        reveal(element, in: app, file: file, line: line)
        element.tap()
    }

    /// Types into a field and leaves the keyboard dismissed, so the next field
    /// is not left underneath it.
    static func type(
        _ text: String,
        into identifier: String,
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let field = element(in: app, identifier: identifier)
        reveal(field, in: app, file: file, line: line)
        field.tap()
        field.typeText(text)
        dismissKeyboard(in: app)
    }

    static func dismissKeyboard(in app: XCUIApplication) {
        guard app.keyboards.firstMatch.exists else { return }
        let returnKey = app.buttons["Return"]
        if returnKey.exists {
            returnKey.tap()
        } else {
            app.typeText("\n")
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
