import Foundation
import Observation
import UIKit

/// Delivers optional completion feedback. Injected so the domain and session
/// logic stay testable, mirroring `VisualTimerCompletionFeedbackDelivering`.
@MainActor
protocol TokenBoardCompletionFeedbackDelivering: AnyObject {
    func deliverCompletion(hapticEnabled: Bool)
}

@MainActor
final class SystemTokenBoardCompletionFeedback: TokenBoardCompletionFeedbackDelivering {
    func deliverCompletion(hapticEnabled: Bool) {
        guard hapticEnabled else {
            return
        }

        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
    }
}

/// Holds the live token count for each template. Progress is deliberately
/// transient: templates persist, an in-progress session does not.
@MainActor
@Observable
final class TokenBoardSessionController {
    private var boardsByTemplateID: [UUID: TokenBoardStateMachine] = [:]
    private let completionFeedback: any TokenBoardCompletionFeedbackDelivering
    private let preferences: OTPreferences

    private(set) var isCompletionHapticEnabled = false

    init(
        completionFeedback: any TokenBoardCompletionFeedbackDelivering =
            SystemTokenBoardCompletionFeedback(),
        preferences: OTPreferences = OTPreferences()
    ) {
        self.completionFeedback = completionFeedback
        self.preferences = preferences
        isCompletionHapticEnabled = preferences.isEnabled(.tokenBoardCompletionHaptic)
    }

    func start(template: TokenBoardTemplateSnapshot) {
        boardsByTemplateID[template.id] = makeBoard(for: template)
    }

    func snapshot(for template: TokenBoardTemplateSnapshot) -> TokenBoardSnapshot {
        board(for: template).snapshot
    }

    @discardableResult
    func addToken(for template: TokenBoardTemplateSnapshot) -> Bool {
        var board = board(for: template)
        defer { boardsByTemplateID[template.id] = board }

        do {
            try board.addToken()
        } catch {
            return false
        }

        if board.takePendingCompletion() != nil {
            completionFeedback.deliverCompletion(hapticEnabled: isCompletionHapticEnabled)
        }
        return true
    }

    @discardableResult
    func removeToken(for template: TokenBoardTemplateSnapshot) -> Bool {
        var board = board(for: template)
        defer { boardsByTemplateID[template.id] = board }

        do {
            try board.removeToken()
        } catch {
            return false
        }
        return true
    }

    func reset(template: TokenBoardTemplateSnapshot) {
        var board = board(for: template)
        board.reset()
        boardsByTemplateID[template.id] = board
    }

    func setCompletionHapticEnabled(_ isEnabled: Bool) {
        isCompletionHapticEnabled = isEnabled
        preferences.setEnabled(isEnabled, for: .tokenBoardCompletionHaptic)
    }

    func discardSession(templateID: UUID) {
        boardsByTemplateID[templateID] = nil
    }

    /// Rebuilds the board when the saved goal or reward no longer matches the
    /// running session, so editing a template cannot strand stale progress.
    private func board(for template: TokenBoardTemplateSnapshot) -> TokenBoardStateMachine {
        guard let existing = boardsByTemplateID[template.id],
            existing.snapshot.goal == template.goal,
            existing.snapshot.reward == template.reward
        else {
            let created = makeBoard(for: template)
            boardsByTemplateID[template.id] = created
            return created
        }
        return existing
    }

    private func makeBoard(for template: TokenBoardTemplateSnapshot) -> TokenBoardStateMachine {
        TokenBoardStateMachine(goal: template.goal, reward: template.reward)
    }
}
