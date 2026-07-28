import XCTest

final class FirstThenScheduleUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testTherapistSelectsReordersRunsAndEndsASchedule() {
        let app = AccessibilityTestSupport.launchApplication(seedsFirstThenSchedule: true)
        openFirstThenBoards(in: app)

        let configure = element(app, "firstThen.schedule.action.configure")
        XCTAssertTrue(configure.waitForExistence(timeout: 5))
        XCTAssertTrue(configure.isEnabled)
        AccessibilityTestSupport.reveal(configure, in: app)
        configure.tap()

        let start = app.buttons["firstThen.schedule.action.start"]
        XCTAssertTrue(start.waitForExistence(timeout: 5))
        XCTAssertFalse(start.isEnabled, "A schedule needs at least two boards.")
        XCTAssertTrue(
            element(app, "firstThen.schedule.configure.requirement").exists,
            "The reason launch is unavailable must be visible."
        )

        selectBoard(named: "Arrival", in: app)
        XCTAssertFalse(start.isEnabled)
        selectBoard(named: "Table Work", in: app)
        selectBoard(named: "Movement Break", in: app)
        XCTAssertTrue(start.isEnabled)
        XCTAssertFalse(element(app, "firstThen.schedule.configure.requirement").exists)

        // Reorder so the launch order differs from both the saved order and the
        // selection order.
        moveSelectedBoardUp(named: "Movement Break", in: app)
        start.tap()

        let position = element(app, "firstThen.schedule.position")
        XCTAssertTrue(position.waitForExistence(timeout: 5))
        XCTAssertEqual(position.label, "Board 1 of 3")
        XCTAssertEqual(scheduleOutlineNames(in: app), ["Arrival", "Movement Break", "Table Work"])

        let firstCard = element(app, "firstThen.schedule.first")
        let thenCard = element(app, "firstThen.schedule.then")
        XCTAssertEqual(firstCard.label, "First, Hang up coat")
        XCTAssertEqual(firstCard.value as? String, "Now")
        XCTAssertEqual(thenCard.value as? String, "Next")

        // Board 1: First -> Then -> next board.
        element(app, "firstThen.schedule.completeFirst").tap()
        XCTAssertEqual(firstCard.value as? String, "Completed")
        XCTAssertEqual(thenCard.value as? String, "Now")

        let advance = element(app, "firstThen.schedule.action.advance")
        AccessibilityTestSupport.reveal(advance, in: app)
        advance.tap()

        XCTAssertEqual(position.label, "Board 2 of 3")
        XCTAssertEqual(element(app, "firstThen.schedule.outline.0").value as? String, "Done")
        XCTAssertEqual(element(app, "firstThen.schedule.outline.1").value as? String, "Now")
        XCTAssertEqual(element(app, "firstThen.schedule.outline.2").value as? String, "Later")
        XCTAssertEqual(element(app, "firstThen.schedule.first").label, "First, Animal walks")

        // Back returns to the previous board with Then current and keeps the
        // rest of the schedule.
        let back = element(app, "firstThen.schedule.action.back")
        AccessibilityTestSupport.reveal(back, in: app)
        back.tap()
        XCTAssertEqual(position.label, "Board 1 of 3")
        XCTAssertEqual(element(app, "firstThen.schedule.then").value as? String, "Now")
        XCTAssertEqual(scheduleOutlineNames(in: app).count, 3)

        // Start over resets every board.
        let startOver = element(app, "firstThen.schedule.action.startOver")
        AccessibilityTestSupport.reveal(startOver, in: app)
        startOver.tap()
        let startOverAlert = app.alerts["Start the schedule over?"]
        XCTAssertTrue(startOverAlert.waitForExistence(timeout: 5))
        startOverAlert.buttons["Start over"].tap()
        XCTAssertEqual(position.label, "Board 1 of 3")
        XCTAssertEqual(element(app, "firstThen.schedule.first").value as? String, "Now")

        // End discards the schedule and returns to the saved boards, which are
        // still all present.
        let end = element(app, "firstThen.schedule.action.end")
        AccessibilityTestSupport.reveal(end, in: app)
        end.tap()
        let endAlert = app.alerts["End this schedule?"]
        XCTAssertTrue(endAlert.waitForExistence(timeout: 5))
        endAlert.buttons["End schedule"].tap()

        XCTAssertTrue(element(app, "firstThen.schedule.entry").waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Arrival"].exists)
        XCTAssertTrue(app.staticTexts["Table Work"].exists)
        XCTAssertTrue(app.staticTexts["Movement Break"].exists)
    }

    /// Child-facing progress, adult exit, and the explicit schedule-complete
    /// state, at the default text size where the journey needs little
    /// scrolling. The largest-text checks live in their own test: combining
    /// them made one long chain of swipe-then-tap steps whose failures moved
    /// around between runs.
    @MainActor
    func testScheduleCompletesThroughChildFacingModeAndSurvivesAdultExit() {
        let app = AccessibilityTestSupport.launchApplication(
            forcesCompactNavigation: true,
            seedsFirstThenSchedule: true
        )
        openFirstThenBoards(in: app)
        startSchedule(with: ["Arrival", "Table Work"], in: app)

        let present = element(app, "firstThen.schedule.action.childFacing")
        AccessibilityTestSupport.reveal(present, in: app)
        present.tap()

        let childContent = element(app, "firstThen.schedule.child.content")
        XCTAssertTrue(childContent.waitForExistence(timeout: 5))
        XCTAssertTrue(childContent.label.contains("Arrival"))
        XCTAssertEqual(element(app, "firstThen.schedule.child.position").label, "Board 1 of 2")

        // Therapist-only controls stay behind the adult exit.
        XCTAssertFalse(element(app, "firstThen.schedule.action.end").isHittable)
        XCTAssertFalse(element(app, "firstThen.schedule.action.startOver").isHittable)

        AccessibilityTestSupport.tap(
            element(app, "firstThen.schedule.child.completeFirst"), in: app)
        AccessibilityTestSupport.tap(element(app, "firstThen.schedule.child.advance"), in: app)
        XCTAssertEqual(element(app, "firstThen.schedule.child.position").label, "Board 2 of 2")

        // Adult exit preserves the schedule and its progress.
        let exit = app.buttons["Exit child view"]
        AccessibilityTestSupport.assertMinimumHitTarget(exit)
        exit.tap()
        let confirmation = app.alerts["Return to therapist controls?"]
        XCTAssertTrue(confirmation.waitForExistence(timeout: 5))
        confirmation.buttons["Return to controls"].tap()

        XCTAssertTrue(element(app, "firstThen.schedule.therapist").waitForExistence(timeout: 5))
        XCTAssertEqual(element(app, "firstThen.schedule.position").label, "Board 2 of 2")
        XCTAssertEqual(element(app, "firstThen.schedule.outline.0").value as? String, "Done")

        // Finish the last board and confirm the explicit completion state.
        AccessibilityTestSupport.tap(element(app, "firstThen.schedule.completeFirst"), in: app)
        AccessibilityTestSupport.tap(element(app, "firstThen.schedule.action.advance"), in: app)

        let completed = element(app, "firstThen.schedule.completed")
        AccessibilityTestSupport.revealForReading(completed, in: app)
        XCTAssertTrue(completed.exists)
        XCTAssertEqual(
            element(app, "firstThen.schedule.position").label,
            "All boards complete"
        )
    }

    /// Largest-text checks on the child-facing schedule, kept to a single
    /// screen's worth of interaction.
    @MainActor
    func testChildFacingScheduleRemainsUsableAtLargestText() throws {
        let app = AccessibilityTestSupport.launchApplication(
            usesLargestAccessibilityText: true,
            forcesCompactNavigation: true,
            seedsFirstThenSchedule: true
        )
        openFirstThenBoards(in: app)
        startSchedule(with: ["Arrival", "Table Work"], in: app)

        let present = element(app, "firstThen.schedule.action.childFacing")
        AccessibilityTestSupport.reveal(present, in: app)
        AccessibilityTestSupport.assertMinimumHitTarget(present)
        present.tap()

        let childContent = element(app, "firstThen.schedule.child.content")
        XCTAssertTrue(childContent.waitForExistence(timeout: 5))
        XCTAssertTrue(childContent.label.contains("Arrival"))
        XCTAssertEqual(element(app, "firstThen.schedule.child.position").label, "Board 1 of 2")
        XCTAssertEqual(
            element(app, "firstThen.schedule.child.first").value as? String,
            "Now"
        )
        XCTAssertEqual(
            element(app, "firstThen.schedule.child.then").value as? String,
            "Next"
        )

        let childComplete = element(app, "firstThen.schedule.child.completeFirst")
        AccessibilityTestSupport.reveal(childComplete, in: app)
        AccessibilityTestSupport.assertMinimumHitTarget(childComplete)
        try app.performAccessibilityAudit(for: [.textClipped])

        // Adult exit stays reachable at this text size and preserves progress.
        let exit = app.buttons["Exit child view"]
        AccessibilityTestSupport.assertMinimumHitTarget(exit)
        exit.tap()
        let confirmation = app.alerts["Return to therapist controls?"]
        XCTAssertTrue(confirmation.waitForExistence(timeout: 5))
        confirmation.buttons["Return to controls"].tap()

        XCTAssertTrue(element(app, "firstThen.schedule.therapist").waitForExistence(timeout: 5))
        XCTAssertEqual(element(app, "firstThen.schedule.position").label, "Board 1 of 2")
    }

    @MainActor
    func testScheduleEntryIsUnavailableWithFewerThanTwoSavedBoards() {
        let app = AccessibilityTestSupport.launchApplication(seedsFirstThenBoard: true)
        openFirstThenBoards(in: app)

        let configure = element(app, "firstThen.schedule.action.configure")
        XCTAssertTrue(configure.waitForExistence(timeout: 5))
        XCTAssertFalse(configure.isEnabled)
        XCTAssertEqual(
            element(app, "firstThen.schedule.entry.message").label,
            "Save at least two boards to start a visual schedule."
        )
    }

    @MainActor
    func testSingleBoardJourneyIsUnchangedWhileScheduleEntryIsAvailable() {
        let app = AccessibilityTestSupport.launchApplication(seedsFirstThenSchedule: true)
        openFirstThenBoards(in: app)

        app.staticTexts["Arrival"].tap()

        let firstCard = element(app, "firstThen.board.first")
        XCTAssertTrue(firstCard.waitForExistence(timeout: 5))
        XCTAssertEqual(firstCard.label, "First, Hang up coat")
        XCTAssertEqual(firstCard.value as? String, "Now")

        element(app, "firstThen.action.completeFirst").tap()
        XCTAssertEqual(firstCard.value as? String, "Completed")
        XCTAssertEqual(element(app, "firstThen.board.then").value as? String, "Now")
        XCTAssertTrue(element(app, "firstThen.transition.then").exists)
    }

    // MARK: - Helpers

    @MainActor
    private func startSchedule(with names: [String], in app: XCUIApplication) {
        let configure = element(app, "firstThen.schedule.action.configure")
        XCTAssertTrue(configure.waitForExistence(timeout: 5))
        AccessibilityTestSupport.reveal(configure, in: app)
        configure.tap()

        for name in names {
            selectBoard(named: name, in: app)
        }

        let start = app.buttons["firstThen.schedule.action.start"]
        XCTAssertTrue(start.isEnabled)
        start.tap()
        XCTAssertTrue(element(app, "firstThen.schedule.therapist").waitForExistence(timeout: 5))
    }

    @MainActor
    private func selectBoard(named name: String, in app: XCUIApplication) {
        let row = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label CONTAINS %@", name))
            .matching(NSPredicate(format: "identifier BEGINSWITH %@", "firstThen.schedule.select."))
            .firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5), "Missing selectable board \(name).")
        AccessibilityTestSupport.reveal(row, in: app)
        row.tap()
    }

    @MainActor
    private func moveSelectedBoardUp(named name: String, in app: XCUIApplication) {
        let boardID = selectedBoardIdentifier(named: name, in: app)
        let moveUp = element(app, "firstThen.schedule.moveUp.\(boardID)")
        XCTAssertTrue(moveUp.waitForExistence(timeout: 5))
        AccessibilityTestSupport.reveal(moveUp, in: app)
        moveUp.tap()
    }

    @MainActor
    private func selectedBoardIdentifier(named name: String, in app: XCUIApplication) -> String {
        let row = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH %@", "firstThen.schedule.select."))
            .matching(NSPredicate(format: "label CONTAINS %@", name))
            .firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        return String(row.identifier.dropFirst("firstThen.schedule.select.".count))
    }

    @MainActor
    private func scheduleOutlineNames(in app: XCUIApplication) -> [String] {
        (0..<3).compactMap { index in
            let row = element(app, "firstThen.schedule.outline.\(index)")
            return row.exists ? row.label : nil
        }
    }

    @MainActor
    private func element(_ app: XCUIApplication, _ identifier: String) -> XCUIElement {
        AccessibilityTestSupport.element(in: app, identifier: identifier)
    }

    @MainActor
    private func openFirstThenBoards(in app: XCUIApplication) {
        AccessibilityTestSupport.showToolsContentIfNeeded(in: app)
        let firstThen = element(app, "home.tool.firstThen")
        XCTAssertTrue(firstThen.waitForExistence(timeout: 5))
        firstThen.tap()
        XCTAssertTrue(element(app, "firstThen.destination").waitForExistence(timeout: 5))
    }

}
