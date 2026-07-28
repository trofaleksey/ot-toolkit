import XCTest

final class ChoiceBoardUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testTherapistCanCreateReorderAndDeleteAChoiceBoard() {
        let app = AccessibilityTestSupport.launchApplication()
        openChoiceBoards(in: app)

        XCTAssertTrue(element(app, "choice.empty.title").waitForExistence(timeout: 5))
        element(app, "choice.empty.create").tap()

        let save = app.buttons["choice.editor.save"]
        XCTAssertTrue(save.waitForExistence(timeout: 5))
        XCTAssertFalse(save.isEnabled, "A board needs a name and every choice named.")
        XCTAssertTrue(element(app, "choice.editor.validation").exists)

        AccessibilityTestSupport.type("Break Choices", into: "choice.editor.name", in: app)
        AccessibilityTestSupport.type("Swing", into: "choice.editor.option.label.0", in: app)
        AccessibilityTestSupport.type("Bubbles", into: "choice.editor.option.label.1", in: app)
        XCTAssertTrue(save.isEnabled)

        // A third choice, then reorder it to the front with the tap-accessible
        // control rather than a drag.
        AccessibilityTestSupport.tap(element(app, "choice.editor.addOption"), in: app)
        AccessibilityTestSupport.type("Drawing", into: "choice.editor.option.label.2", in: app)
        AccessibilityTestSupport.tap(element(app, "choice.editor.option.moveUp.2"), in: app)
        AccessibilityTestSupport.tap(element(app, "choice.editor.option.moveUp.1"), in: app)
        AccessibilityTestSupport.tap(save, in: app)

        let boardTitle = app.staticTexts["Break Choices"]
        XCTAssertTrue(boardTitle.waitForExistence(timeout: 5))
        boardTitle.tap()

        // Reordering in the editor determined presentation order.
        XCTAssertTrue(element(app, "choice.board.use").waitForExistence(timeout: 5))
        assertOptionOrder(["Drawing", "Swing", "Bubbles"], prefix: "choice.board.option", in: app)

        AccessibilityTestSupport.tap(element(app, "choice.board.use.delete"), in: app)
        let confirmation = app.alerts["Delete this board?"]
        XCTAssertTrue(confirmation.waitForExistence(timeout: 5))
        confirmation.buttons["Delete board"].tap()

        XCTAssertTrue(element(app, "choice.empty.title").waitForExistence(timeout: 5))
    }

    @MainActor
    func testSelectingHidingAndClearingAreSessionOnly() {
        let app = AccessibilityTestSupport.launchApplication(seedsChoiceBoard: true)
        openChoiceBoards(in: app)
        openSeededBoard(in: app)

        let swing = element(app, "choice.board.option.0")
        let bubbles = element(app, "choice.board.option.1")

        XCTAssertEqual(swing.value as? String, "Not picked")
        AccessibilityTestSupport.tap(swing, in: app)
        XCTAssertEqual(swing.value as? String, "Picked")
        XCTAssertEqual(bubbles.value as? String, "Not picked")
        XCTAssertEqual(
            element(app, "choice.selection.summary").label,
            "Picked: Swing"
        )

        // Selecting another choice moves the pick rather than adding one.
        AccessibilityTestSupport.tap(bubbles, in: app)
        XCTAssertEqual(swing.value as? String, "Not picked")
        XCTAssertEqual(bubbles.value as? String, "Picked")

        AccessibilityTestSupport.tap(element(app, "choice.action.clearSelection"), in: app)
        XCTAssertEqual(element(app, "choice.selection.summary").label, "Nothing picked yet")

        // Hiding removes a choice from the board for this session only.
        AccessibilityTestSupport.tap(element(app, "choice.visibility.toggle.2"), in: app)
        XCTAssertEqual(element(app, "choice.visibility.state.2").label, "Hidden")
        XCTAssertEqual(element(app, "choice.visibility.state.0").label, "Shown")

        // Two choices remain, so no further hiding is offered.
        XCTAssertFalse(element(app, "choice.visibility.toggle.0").isEnabled)

        // The grid itself drops the hidden tile.
        assertOptionOrder(["Swing", "Bubbles"], prefix: "choice.board.option", in: app)
        XCTAssertFalse(element(app, "choice.board.option.2").exists)

        AccessibilityTestSupport.tap(element(app, "choice.action.showAll"), in: app)
        assertOptionOrder(["Swing", "Bubbles", "Drawing"], prefix: "choice.board.option", in: app)
    }

    @MainActor
    func testChildFacingChoiceSurvivesAdultExitAndDuplicateLeavesTheOriginal() {
        let app = AccessibilityTestSupport.launchApplication(
            forcesCompactNavigation: true,
            seedsChoiceBoard: true
        )
        openChoiceBoards(in: app)
        openSeededBoard(in: app)

        AccessibilityTestSupport.tap(element(app, "choice.action.childFacing"), in: app)
        let childContent = element(app, "choice.child.content")
        XCTAssertTrue(childContent.waitForExistence(timeout: 5))
        XCTAssertTrue(childContent.label.contains("Break Choices"))

        // Therapist-only controls stay behind the adult exit.
        XCTAssertFalse(element(app, "choice.action.clearSelection").isHittable)
        XCTAssertFalse(element(app, "choice.visibility").isHittable)

        let childSwing = element(app, "choice.child.option.0")
        AccessibilityTestSupport.assertMinimumHitTarget(childSwing)
        AccessibilityTestSupport.tap(childSwing, in: app)
        XCTAssertEqual(childSwing.value as? String, "Picked")

        let exit = app.buttons["Exit child view"]
        AccessibilityTestSupport.assertMinimumHitTarget(exit)
        exit.tap()
        let confirmation = app.alerts["Return to therapist controls?"]
        XCTAssertTrue(confirmation.waitForExistence(timeout: 5))
        confirmation.buttons["Return to controls"].tap()

        XCTAssertTrue(element(app, "choice.board.use").waitForExistence(timeout: 5))
        XCTAssertEqual(element(app, "choice.selection.summary").label, "Picked: Swing")

        // Duplicating adds a copy and leaves the original in place.
        AccessibilityTestSupport.tap(element(app, "choice.action.duplicate"), in: app)
        navigateBack(in: app)

        XCTAssertTrue(element(app, "choice.destination").waitForExistence(timeout: 5))
        XCTAssertEqual(savedBoardNames(in: app), ["Break Choices", "Break Choices copy"])
    }

    @MainActor
    func testChoiceBoardRemainsReadableAtLargestAccessibilityTextSize() throws {
        let app = AccessibilityTestSupport.launchApplication(
            usesLargestAccessibilityText: true,
            forcesCompactNavigation: true,
            seedsChoiceBoard: true
        )
        openChoiceBoards(in: app)
        openSeededBoard(in: app)

        let present = element(app, "choice.action.childFacing")
        AccessibilityTestSupport.reveal(present, in: app)
        AccessibilityTestSupport.assertMinimumHitTarget(present)
        present.tap()

        XCTAssertTrue(element(app, "choice.child.content").waitForExistence(timeout: 5))

        // Any realized tile will do: at this text size the grid is taller than
        // the accessibility snapshot, so requiring a specific one would assert
        // on scroll position rather than on readability.
        let tile = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH %@", "choice.child.option."))
            .firstMatch
        AccessibilityTestSupport.reveal(tile, in: app)
        AccessibilityTestSupport.assertMinimumHitTarget(tile)
        XCTAssertEqual(tile.value as? String, "Not picked")
        try app.performAccessibilityAudit(for: [.textClipped])
    }

    // MARK: - Helpers

    @MainActor
    private func navigateBack(in app: XCUIApplication) {
        let back = app.buttons["BackButton"]
        if back.waitForExistence(timeout: 5) {
            back.tap()
        } else {
            app.navigationBars.buttons.element(boundBy: 0).tap()
        }
    }

    @MainActor
    private func savedBoardNames(in app: XCUIApplication) -> [String] {
        app.descendants(matching: .any)
            .matching(
                NSPredicate(
                    format: "identifier BEGINSWITH %@ AND NOT (identifier CONTAINS %@)",
                    "choice.board.",
                    ".edit."
                )
            )
            .allElementsBoundByIndex
            .map { $0.label.components(separatedBy: ",").first ?? $0.label }
    }

    /// Opens the only saved board through its row identifier. Matching the
    /// title text fails at the largest text size, where the row can sit
    /// outside the accessibility snapshot until it is scrolled into view.
    @MainActor
    private func openSeededBoard(in app: XCUIApplication) {
        let row = app.descendants(matching: .any)
            .matching(
                NSPredicate(
                    format: "identifier BEGINSWITH %@ AND NOT (identifier CONTAINS %@)",
                    "choice.board.",
                    ".edit."
                )
            )
            .firstMatch
        AccessibilityTestSupport.tap(row, in: app)
        XCTAssertTrue(element(app, "choice.board.use").waitForExistence(timeout: 5))
    }

    /// Asserts the visible tiles read in the given order.
    ///
    /// Reads each indexed tile individually and scrolls to it first. Scraping
    /// the whole hierarchy instead returns only tiles currently realized, which
    /// silently drops entries once an earlier tap has scrolled the grid away.
    @MainActor
    private func assertOptionOrder(
        _ labels: [String],
        prefix: String,
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        for (index, expected) in labels.enumerated() {
            let tile = element(app, "\(prefix).\(index)")
            AccessibilityTestSupport.revealForReading(tile, in: app)
            XCTAssertEqual(tile.label, expected, "tile \(index)", file: file, line: line)
        }
    }

    /// Scrolls up then down to bring an element into the hierarchy, without
    /// assuming which side of the viewport it is on.

    @MainActor
    private func element(_ app: XCUIApplication, _ identifier: String) -> XCUIElement {
        AccessibilityTestSupport.element(in: app, identifier: identifier)
    }

    @MainActor
    private func openChoiceBoards(in app: XCUIApplication) {
        AccessibilityTestSupport.showToolsContentIfNeeded(in: app)
        let choice = element(app, "home.tool.choiceBoard")
        AccessibilityTestSupport.reveal(choice, in: app)
        choice.tap()
        XCTAssertTrue(element(app, "choice.destination").waitForExistence(timeout: 5))
    }
}
