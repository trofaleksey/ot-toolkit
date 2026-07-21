import XCTest

final class FirstThenBoardUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testTherapistCanCreateUseEditAndDeleteBoard() {
        let app = AccessibilityTestSupport.launchApplication()
        openFirstThenBoards(in: app)

        XCTAssertTrue(
            AccessibilityTestSupport.element(in: app, identifier: "firstThen.empty.title")
                .waitForExistence(timeout: 5)
        )
        AccessibilityTestSupport.element(
            in: app,
            identifier: "firstThen.empty.create"
        ).tap()

        let saveButton = app.buttons["firstThen.editor.save"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 5))
        XCTAssertFalse(saveButton.isEnabled)
        XCTAssertTrue(
            AccessibilityTestSupport.element(
                in: app,
                identifier: "firstThen.editor.validation"
            ).exists
        )
        XCTAssertTrue(
            AccessibilityTestSupport.element(
                in: app,
                identifier: "firstThen.editor.first.symbol"
            ).exists
        )
        XCTAssertTrue(
            AccessibilityTestSupport.element(
                in: app,
                identifier: "firstThen.editor.then.symbol"
            ).exists
        )

        type("Morning Routine", into: "firstThen.editor.name", in: app)
        type("Get dressed", into: "firstThen.editor.first.label", in: app)
        type("Read together", into: "firstThen.editor.then.label", in: app)
        XCTAssertTrue(saveButton.isEnabled)
        saveButton.tap()

        let savedBoardTitle = app.staticTexts["Morning Routine"]
        XCTAssertTrue(savedBoardTitle.waitForExistence(timeout: 5))
        savedBoardTitle.tap()

        let firstCard = AccessibilityTestSupport.element(
            in: app,
            identifier: "firstThen.board.first"
        )
        let thenCard = AccessibilityTestSupport.element(
            in: app,
            identifier: "firstThen.board.then"
        )
        XCTAssertTrue(firstCard.waitForExistence(timeout: 5))
        XCTAssertEqual(firstCard.label, "First, Get dressed")
        XCTAssertEqual(firstCard.value as? String, "Now")
        XCTAssertEqual(thenCard.label, "Then, Read together")
        XCTAssertEqual(thenCard.value as? String, "Next")

        AccessibilityTestSupport.element(
            in: app,
            identifier: "firstThen.action.completeFirst"
        ).tap()

        XCTAssertEqual(firstCard.value as? String, "Completed")
        XCTAssertEqual(thenCard.value as? String, "Now")
        XCTAssertTrue(
            AccessibilityTestSupport.element(
                in: app,
                identifier: "firstThen.transition.then"
            ).waitForExistence(timeout: 5)
        )

        AccessibilityTestSupport.element(
            in: app,
            identifier: "firstThen.board.use.edit"
        ).tap()
        replaceText(with: "After School", in: "firstThen.editor.name", app: app)
        app.buttons["firstThen.editor.save"].tap()
        XCTAssertTrue(app.navigationBars["After School"].waitForExistence(timeout: 5))

        AccessibilityTestSupport.element(
            in: app,
            identifier: "firstThen.board.use.delete"
        ).tap()
        let confirmation = app.alerts["Delete this board?"]
        XCTAssertTrue(confirmation.waitForExistence(timeout: 5))
        confirmation.buttons["Delete board"].tap()

        XCTAssertTrue(
            AccessibilityTestSupport.element(in: app, identifier: "firstThen.empty.title")
                .waitForExistence(timeout: 5)
        )
    }

    @MainActor
    func testFirstThenEditorRemainsReadableAtLargestAccessibilityTextSize() throws {
        let app = AccessibilityTestSupport.launchApplication(usesLargestAccessibilityText: true)
        openFirstThenBoards(in: app)
        let create = AccessibilityTestSupport.element(
            in: app,
            identifier: "firstThen.empty.create"
        )
        let tabBar = app.tabBars.firstMatch
        let contentBottom =
            tabBar.exists
            ? tabBar.frame.minY
            : app.windows.firstMatch.frame.maxY
        for _ in 0..<3 where !create.isHittable || create.frame.maxY > contentBottom {
            app.swipeUp()
        }
        AccessibilityTestSupport.assertMinimumHitTarget(create)
        create.tap()

        let window = app.windows.firstMatch
        let boardName = AccessibilityTestSupport.element(
            in: app,
            identifier: "firstThen.editor.name"
        )
        AccessibilityTestSupport.assertFitsHorizontally(boardName, in: window)
        try app.performAccessibilityAudit(for: [.textClipped])
    }

    @MainActor
    func testChildFacingFlowCompletesAndReturnsToSameCompactBoardAtLargestText() throws {
        let app = AccessibilityTestSupport.launchApplication(
            usesLargestAccessibilityText: true,
            forcesCompactNavigation: true,
            seedsFirstThenBoard: true
        )
        openFirstThenBoards(in: app)

        let savedBoardTitle = app.staticTexts["Morning Routine"]
        XCTAssertTrue(savedBoardTitle.waitForExistence(timeout: 5))
        savedBoardTitle.tap()

        let present = AccessibilityTestSupport.element(
            in: app,
            identifier: "firstThen.action.childFacing"
        )
        reveal(present, in: app)
        AccessibilityTestSupport.assertMinimumHitTarget(present)
        present.tap()

        let childContent = AccessibilityTestSupport.element(
            in: app,
            identifier: "firstThen.child.content"
        )
        XCTAssertTrue(childContent.waitForExistence(timeout: 5))
        XCTAssertTrue(childContent.label.contains("Morning Routine"))

        let firstCard = AccessibilityTestSupport.element(
            in: app,
            identifier: "firstThen.child.first"
        )
        let thenCard = AccessibilityTestSupport.element(
            in: app,
            identifier: "firstThen.child.then"
        )
        XCTAssertEqual(firstCard.label, "First, Get dressed")
        XCTAssertEqual(firstCard.value as? String, "Now")
        XCTAssertEqual(thenCard.label, "Then, Read together")
        XCTAssertEqual(thenCard.value as? String, "Next")
        XCTAssertFalse(
            AccessibilityTestSupport.element(
                in: app,
                identifier: "firstThen.board.use.edit"
            ).isHittable
        )

        let complete = AccessibilityTestSupport.element(
            in: app,
            identifier: "firstThen.child.completeFirst"
        )
        reveal(complete, in: app)
        AccessibilityTestSupport.assertMinimumHitTarget(complete)
        complete.tap()

        XCTAssertEqual(firstCard.value as? String, "Completed")
        XCTAssertEqual(thenCard.value as? String, "Now")
        let transition = AccessibilityTestSupport.element(
            in: app,
            identifier: "firstThen.child.transition"
        )
        reveal(transition, in: app, requiresHittable: false)
        try app.performAccessibilityAudit(for: [.textClipped])

        let exit = app.buttons["Exit child view"]
        AccessibilityTestSupport.assertMinimumHitTarget(exit)
        exit.tap()
        let confirmation = app.alerts["Return to therapist controls?"]
        XCTAssertTrue(confirmation.waitForExistence(timeout: 5))
        confirmation.buttons["Return to controls"].tap()

        XCTAssertFalse(childContent.exists)
        XCTAssertTrue(
            AccessibilityTestSupport.element(
                in: app,
                identifier: "firstThen.board.use"
            ).waitForExistence(timeout: 5)
        )
        XCTAssertEqual(
            AccessibilityTestSupport.element(
                in: app,
                identifier: "firstThen.board.first"
            ).value as? String,
            "Completed"
        )
        XCTAssertEqual(
            AccessibilityTestSupport.element(
                in: app,
                identifier: "firstThen.board.then"
            ).value as? String,
            "Now"
        )
    }

    @MainActor
    private func openFirstThenBoards(in app: XCUIApplication) {
        AccessibilityTestSupport.showToolsContentIfNeeded(in: app)
        let firstThen = AccessibilityTestSupport.element(
            in: app,
            identifier: "home.tool.firstThen"
        )
        XCTAssertTrue(firstThen.waitForExistence(timeout: 5))
        firstThen.tap()
        XCTAssertTrue(
            AccessibilityTestSupport.element(
                in: app,
                identifier: "firstThen.destination"
            ).waitForExistence(timeout: 5)
        )
    }

    @MainActor
    private func type(_ text: String, into identifier: String, in app: XCUIApplication) {
        let field = AccessibilityTestSupport.element(in: app, identifier: identifier)
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        field.typeText(text)
    }

    @MainActor
    private func replaceText(
        with text: String,
        in identifier: String,
        app: XCUIApplication
    ) {
        let field = AccessibilityTestSupport.element(in: app, identifier: identifier)
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        field.press(forDuration: 1)
        app.menuItems["Select All"].tap()
        field.typeText(text)
    }

    @MainActor
    private func reveal(
        _ element: XCUIElement,
        in app: XCUIApplication,
        requiresHittable: Bool = true
    ) {
        XCTAssertTrue(element.waitForExistence(timeout: 5))
        for _ in 0..<8 {
            if !requiresHittable || element.isHittable {
                return
            }
            app.swipeUp()
        }

        if requiresHittable {
            XCTAssertTrue(element.isHittable)
        }
    }
}
