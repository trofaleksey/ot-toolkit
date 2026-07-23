import XCTest

final class TokenBoardUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testChildFacingTokenBoardFillsToGoalAndExitsThroughConfirmation() {
        let app = AccessibilityTestSupport.launchApplication(seedsTokenBoard: true)
        openSeededTemplate(in: app)

        AccessibilityTestSupport.element(
            in: app,
            identifier: "tokenBoard.action.childFacing"
        ).tap()

        let board = AccessibilityTestSupport.element(
            in: app,
            identifier: "tokenBoard.child.board"
        )
        XCTAssertTrue(board.waitForExistence(timeout: 5))
        XCTAssertTrue(
            AccessibilityTestSupport.element(
                in: app,
                identifier: "tokenBoard.child.content"
            ).exists
        )

        // The seeded fixture uses a goal of three.
        for _ in 1...3 {
            board.tap()
        }

        XCTAssertTrue(
            AccessibilityTestSupport.element(
                in: app,
                identifier: "tokenBoard.status.complete"
            ).waitForExistence(timeout: 5)
        )

        let exitButton = app.buttons["Exit child view"]
        XCTAssertTrue(exitButton.waitForExistence(timeout: 5))
        exitButton.tap()

        let confirmation = app.alerts["Return to therapist controls?"]
        XCTAssertTrue(confirmation.waitForExistence(timeout: 5))
        confirmation.buttons["Return to controls"].tap()

        XCTAssertTrue(
            AccessibilityTestSupport.element(
                in: app,
                identifier: "tokenBoard.template.use"
            ).waitForExistence(timeout: 5)
        )
    }

    @MainActor
    func testTherapistCanUndoAndResetCollectedTokens() {
        let app = AccessibilityTestSupport.launchApplication(seedsTokenBoard: true)
        openSeededTemplate(in: app)

        let board = AccessibilityTestSupport.element(in: app, identifier: "tokenBoard.board")
        XCTAssertTrue(board.waitForExistence(timeout: 5))

        board.tap()
        board.tap()

        let undo = AccessibilityTestSupport.element(
            in: app,
            identifier: "tokenBoard.action.remove"
        )
        XCTAssertTrue(undo.isEnabled)
        undo.tap()

        let reset = AccessibilityTestSupport.element(
            in: app,
            identifier: "tokenBoard.action.reset"
        )
        XCTAssertTrue(reset.isEnabled)
        reset.tap()

        XCTAssertFalse(reset.isEnabled)
    }

    @MainActor
    func testTokenBoardListRemainsReadableAtLargestAccessibilityTextSize() throws {
        // Unseeded so the empty state renders. This asserts that the list stays
        // readable — no clipped text — at the largest text size. It deliberately
        // does not assert hit targets or horizontal fit: this content scrolls,
        // so controls may legitimately sit below the fold and report as not
        // hittable. The 44pt contract is covered where it belongs, by
        // DesignTokenTests, AdultExitControlTests, and the pinned adult-exit
        // check in AdaptiveNavigationUITests.
        let app = AccessibilityTestSupport.launchApplication(
            usesLargestAccessibilityText: true,
            forcesCompactNavigation: true
        )
        openTokenBoardList(in: app)

        XCTAssertTrue(
            AccessibilityTestSupport.element(
                in: app,
                identifier: "tokenBoard.empty.title"
            ).waitForExistence(timeout: 5)
        )
        XCTAssertTrue(
            AccessibilityTestSupport.element(
                in: app,
                identifier: "tokenBoard.empty.create"
            ).waitForExistence(timeout: 5)
        )

        try app.performAccessibilityAudit(for: [.textClipped])
    }

    /// Matches the seeded fixture in AppSceneRootView.
    private static let seededTemplateIdentifier =
        "tokenBoard.template.40000000-0000-0000-0000-000000000001"

    @MainActor
    private func openTokenBoardList(in app: XCUIApplication) {
        AccessibilityTestSupport.showToolsContentIfNeeded(in: app)
        let tokenBoard = AccessibilityTestSupport.element(
            in: app,
            identifier: "home.tool.tokenBoard"
        )
        XCTAssertTrue(tokenBoard.waitForExistence(timeout: 5))
        tokenBoard.tap()

        XCTAssertTrue(
            AccessibilityTestSupport.element(
                in: app,
                identifier: "tokenBoard.destination"
            ).waitForExistence(timeout: 5)
        )
    }

    @MainActor
    private func openSeededTemplate(in app: XCUIApplication) {
        openTokenBoardList(in: app)

        let seededTemplate = AccessibilityTestSupport.element(
            in: app,
            identifier: Self.seededTemplateIdentifier
        )
        XCTAssertTrue(seededTemplate.waitForExistence(timeout: 5))
        seededTemplate.tap()

        XCTAssertTrue(
            AccessibilityTestSupport.element(
                in: app,
                identifier: "tokenBoard.template.use"
            ).waitForExistence(timeout: 5)
        )
    }
}
