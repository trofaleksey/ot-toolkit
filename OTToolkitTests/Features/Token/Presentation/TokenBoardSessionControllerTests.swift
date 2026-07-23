import Foundation
import XCTest
@testable import OTToolkit

final class TokenBoardSessionControllerTests: XCTestCase {
    @MainActor
    func testStartBeginsAnEmptySessionForTheTemplateGoal() {
        let controller = TokenBoardSessionController(completionFeedback: SpyFeedback())
        let template = template(goal: .five)

        controller.start(template: template)

        let snapshot = controller.snapshot(for: template)
        XCTAssertEqual(snapshot.filledCount, 0)
        XCTAssertEqual(snapshot.goal, .five)
        XCTAssertFalse(snapshot.isComplete)
    }

    @MainActor
    func testAddingTokensFillsTowardTheGoalAndStopsAtIt() {
        let controller = TokenBoardSessionController(completionFeedback: SpyFeedback())
        let template = template(goal: .three)

        for _ in 1...3 {
            XCTAssertTrue(controller.addToken(for: template))
        }

        XCTAssertTrue(controller.snapshot(for: template).isComplete)
        XCTAssertFalse(controller.addToken(for: template))
        XCTAssertEqual(controller.snapshot(for: template).filledCount, 3)
    }

    @MainActor
    func testRemovingBelowZeroFails() {
        let controller = TokenBoardSessionController(completionFeedback: SpyFeedback())
        let template = template(goal: .three)

        XCTAssertFalse(controller.removeToken(for: template))
        XCTAssertEqual(controller.snapshot(for: template).filledCount, 0)
    }

    @MainActor
    func testRemovingATokenReversesCompletion() {
        let controller = TokenBoardSessionController(completionFeedback: SpyFeedback())
        let template = template(goal: .three)
        for _ in 1...3 {
            controller.addToken(for: template)
        }

        XCTAssertTrue(controller.removeToken(for: template))

        let snapshot = controller.snapshot(for: template)
        XCTAssertFalse(snapshot.isComplete)
        XCTAssertEqual(snapshot.filledCount, 2)
    }

    @MainActor
    func testResetClearsProgress() {
        let controller = TokenBoardSessionController(completionFeedback: SpyFeedback())
        let template = template(goal: .five)
        controller.addToken(for: template)
        controller.addToken(for: template)

        controller.reset(template: template)

        XCTAssertEqual(controller.snapshot(for: template).filledCount, 0)
    }

    @MainActor
    func testCompletionFeedbackIsSuppressedByDefault() {
        let feedback = SpyFeedback()
        let controller = TokenBoardSessionController(completionFeedback: feedback)
        let template = template(goal: .three)

        for _ in 1...3 {
            controller.addToken(for: template)
        }

        XCTAssertFalse(controller.isCompletionHapticEnabled)
        XCTAssertEqual(feedback.deliveries, [false])
    }

    @MainActor
    func testCompletionFeedbackFiresOncePerCompletionWhenEnabled() {
        let feedback = SpyFeedback()
        let controller = TokenBoardSessionController(completionFeedback: feedback)
        let template = template(goal: .three)
        controller.setCompletionHapticEnabled(true)

        for _ in 1...3 {
            controller.addToken(for: template)
        }
        XCTAssertEqual(feedback.deliveries, [true])

        controller.removeToken(for: template)
        controller.addToken(for: template)

        XCTAssertEqual(feedback.deliveries, [true, true])
    }

    @MainActor
    func testEditingTheGoalRebuildsTheSession() {
        let controller = TokenBoardSessionController(completionFeedback: SpyFeedback())
        let original = template(goal: .three)
        controller.addToken(for: original)

        let edited = TokenBoardTemplateSnapshot(
            id: original.id,
            name: original.name,
            goal: .ten,
            reward: original.reward
        )

        let snapshot = controller.snapshot(for: edited)
        XCTAssertEqual(snapshot.goal, .ten)
        XCTAssertEqual(snapshot.filledCount, 0)
    }

    @MainActor
    func testDiscardSessionClearsProgress() {
        let controller = TokenBoardSessionController(completionFeedback: SpyFeedback())
        let template = template(goal: .five)
        controller.addToken(for: template)

        controller.discardSession(templateID: template.id)

        XCTAssertEqual(controller.snapshot(for: template).filledCount, 0)
    }

    private func template(goal: TokenBoardGoal) -> TokenBoardTemplateSnapshot {
        TokenBoardTemplateSnapshot(
            id: UUID(uuid: (0x50, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0x01)),
            name: "Table Time",
            goal: goal,
            reward: TokenBoardReward(label: "Bubbles", systemSymbolName: "star")
        )
    }
}

@MainActor
private final class SpyFeedback: TokenBoardCompletionFeedbackDelivering {
    private(set) var deliveries: [Bool] = []

    func deliverCompletion(hapticEnabled: Bool) {
        deliveries.append(hapticEnabled)
    }
}
