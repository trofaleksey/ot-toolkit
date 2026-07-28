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

        type("Break Choices", into: "choice.editor.name", in: app)
        type("Swing", into: "choice.editor.option.label.0", in: app)
        type("Bubbles", into: "choice.editor.option.label.1", in: app)
        XCTAssertTrue(save.isEnabled)

        // A third choice, then reorder it to the front with the tap-accessible
        // control rather than a drag.
        tap(element(app, "choice.editor.addOption"), in: app)
        type("Drawing", into: "choice.editor.option.label.2", in: app)
        tap(element(app, "choice.editor.option.moveUp.2"), in: app)
        tap(element(app, "choice.editor.option.moveUp.1"), in: app)
        tap(save, in: app)

        let boardTitle = app.staticTexts["Break Choices"]
        XCTAssertTrue(boardTitle.waitForExistence(timeout: 5))
        boardTitle.tap()

        // Reordering in the editor determined presentation order.
        XCTAssertTrue(element(app, "choice.board.use").waitForExistence(timeout: 5))
        XCTAssertEqual(
            optionLabels(in: app, prefix: "choice.board.option"), ["Drawing", "Swing", "Bubbles"])

        tap(element(app, "choice.board.use.delete"), in: app)
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

        let swing = optionElement(app, prefix: "choice.board.option", label: "Swing")
        let bubbles = optionElement(app, prefix: "choice.board.option", label: "Bubbles")

        XCTAssertEqual(swing.value as? String, "Not picked")
        tap(swing, in: app)
        XCTAssertEqual(swing.value as? String, "Picked")
        XCTAssertEqual(bubbles.value as? String, "Not picked")
        XCTAssertEqual(
            element(app, "choice.selection.summary").label,
            "Picked: Swing"
        )

        // Selecting another choice moves the pick rather than adding one.
        tap(bubbles, in: app)
        XCTAssertEqual(swing.value as? String, "Not picked")
        XCTAssertEqual(bubbles.value as? String, "Picked")

        tap(element(app, "choice.action.clearSelection"), in: app)
        XCTAssertEqual(element(app, "choice.selection.summary").label, "Nothing picked yet")

        // Hiding removes a choice from the board for this session only.
        let hideDrawing = hideToggle(app, forLabel: "Drawing")
        tap(hideDrawing, in: app)
        XCTAssertEqual(optionLabels(in: app, prefix: "choice.board.option"), ["Swing", "Bubbles"])

        // Two choices remain, so no further hiding is offered.
        XCTAssertFalse(hideToggle(app, forLabel: "Swing").isEnabled)

        tap(element(app, "choice.action.showAll"), in: app)
        XCTAssertEqual(
            optionLabels(in: app, prefix: "choice.board.option"),
            ["Swing", "Bubbles", "Drawing"]
        )
    }

    @MainActor
    func testChildFacingChoiceSurvivesAdultExitAndDuplicateLeavesTheOriginal() {
        let app = AccessibilityTestSupport.launchApplication(
            forcesCompactNavigation: true,
            seedsChoiceBoard: true
        )
        openChoiceBoards(in: app)
        openSeededBoard(in: app)

        tap(element(app, "choice.action.childFacing"), in: app)
        let childContent = element(app, "choice.child.content")
        XCTAssertTrue(childContent.waitForExistence(timeout: 5))
        XCTAssertTrue(childContent.label.contains("Break Choices"))

        // Therapist-only controls stay behind the adult exit.
        XCTAssertFalse(element(app, "choice.action.clearSelection").isHittable)
        XCTAssertFalse(element(app, "choice.visibility").isHittable)

        let childSwing = optionElement(app, prefix: "choice.child.option", label: "Swing")
        AccessibilityTestSupport.assertMinimumHitTarget(childSwing)
        tap(childSwing, in: app)
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
        tap(element(app, "choice.action.duplicate"), in: app)
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
        reveal(present, in: app)
        AccessibilityTestSupport.assertMinimumHitTarget(present)
        present.tap()

        XCTAssertTrue(element(app, "choice.child.content").waitForExistence(timeout: 5))

        // Any realized tile will do: at this text size the grid is taller than
        // the accessibility snapshot, so requiring a specific one would assert
        // on scroll position rather than on readability.
        let tile = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH %@", "choice.child.option."))
            .firstMatch
        reveal(tile, in: app)
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
        tap(row, in: app)
        XCTAssertTrue(element(app, "choice.board.use").waitForExistence(timeout: 5))
    }

    @MainActor
    private func optionLabels(in app: XCUIApplication, prefix: String) -> [String] {
        app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH %@", "\(prefix)."))
            .allElementsBoundByIndex
            .map(\.label)
    }

    @MainActor
    private func optionElement(
        _ app: XCUIApplication,
        prefix: String,
        label: String
    ) -> XCUIElement {
        app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH %@", "\(prefix)."))
            .matching(NSPredicate(format: "label == %@", label))
            .firstMatch
    }

    @MainActor
    private func hideToggle(_ app: XCUIApplication, forLabel label: String) -> XCUIElement {
        // The visibility row's toggle is identified by the option's id, which
        // the test does not know, so find it through the row that names it.
        let rows = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH %@", "choice.visibility.toggle."))
            .allElementsBoundByIndex
        let index = ["Swing", "Bubbles", "Drawing"].firstIndex(of: label) ?? 0
        return index < rows.count ? rows[index] : rows.first ?? app.buttons.firstMatch
    }

    @MainActor
    private func element(_ app: XCUIApplication, _ identifier: String) -> XCUIElement {
        AccessibilityTestSupport.element(in: app, identifier: identifier)
    }

    @MainActor
    private func openChoiceBoards(in app: XCUIApplication) {
        AccessibilityTestSupport.showToolsContentIfNeeded(in: app)
        let choice = element(app, "home.tool.choiceBoard")
        reveal(choice, in: app)
        choice.tap()
        XCTAssertTrue(element(app, "choice.destination").waitForExistence(timeout: 5))
    }

    @MainActor
    private func type(_ text: String, into identifier: String, in app: XCUIApplication) {
        let field = element(app, identifier)
        reveal(field, in: app)
        field.tap()
        field.typeText(text)
    }

    @MainActor
    private func tap(_ element: XCUIElement, in app: XCUIApplication) {
        reveal(element, in: app)
        element.tap()
    }

    /// Scrolls until the element's centre — the point `tap()` targets — clears
    /// the tab bar.
    ///
    /// Two traps this avoids. Existence is checked inside the loop rather than
    /// up front, because at the largest text size an element below the fold is
    /// not in the accessibility snapshot at all until it is scrolled toward.
    /// And `isHittable` alone is not enough: a tall control can peek above the
    /// tab bar and report hittable while its centre sits underneath it, so the
    /// tap silently goes to the tab bar instead.
    @MainActor
    private func reveal(_ element: XCUIElement, in app: XCUIApplication) {
        for _ in 0..<8 {
            if element.exists, element.isHittable, element.frame.midY < contentBottom(in: app) {
                return
            }
            app.swipeUp()
        }

        XCTAssertTrue(element.waitForExistence(timeout: 5))
        XCTAssertTrue(element.isHittable)
        XCTAssertLessThan(element.frame.midY, contentBottom(in: app))
    }

    @MainActor
    private func contentBottom(in app: XCUIApplication) -> CGFloat {
        let tabBar = app.tabBars.firstMatch
        return tabBar.exists ? tabBar.frame.minY : app.windows.firstMatch.frame.maxY
    }
}
