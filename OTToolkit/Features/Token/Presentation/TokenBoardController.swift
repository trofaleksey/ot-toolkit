import Foundation
import Observation

struct TokenBoardTemplateSnapshot: Equatable, Identifiable, Sendable {
    let id: UUID
    let name: String
    let goal: TokenBoardGoal
    let reward: TokenBoardReward

    var draft: TokenBoardTemplateDraft {
        TokenBoardTemplateDraft(name: name, goal: goal, reward: reward)
    }
}

enum TokenBoardTemplateOperation: Equatable, Identifiable, Sendable {
    case load
    case create
    case update
    case delete

    var id: Self { self }
}

@MainActor
@Observable
final class TokenBoardController {
    private let store: any TokenBoardTemplateStoring
    private var modelsByID: [UUID: TokenBoardTemplate] = [:]

    private(set) var templates: [TokenBoardTemplateSnapshot] = []
    private(set) var failure: TokenBoardTemplateOperation?

    init(store: any TokenBoardTemplateStoring) {
        self.store = store
        reload()
    }

    func template(id: UUID) -> TokenBoardTemplateSnapshot? {
        templates.first { $0.id == id }
    }

    @discardableResult
    func reload() -> Bool {
        do {
            let models = try store.fetchTemplates()
            let snapshots = try models.map(makeSnapshot)
            modelsByID = Dictionary(uniqueKeysWithValues: models.map { ($0.id, $0) })
            templates = snapshots
            failure = nil
            return true
        } catch {
            failure = .load
            return false
        }
    }

    @discardableResult
    func create(_ draft: TokenBoardTemplateDraft) -> Bool {
        do {
            _ = try store.create(draft)
            guard reload() else { return false }
            return true
        } catch {
            failure = .create
            return false
        }
    }

    @discardableResult
    func update(id: UUID, with draft: TokenBoardTemplateDraft) -> Bool {
        guard let template = modelsByID[id] else {
            failure = .update
            return false
        }

        do {
            try store.update(template, with: draft)
            guard reload() else { return false }
            return true
        } catch {
            failure = .update
            return false
        }
    }

    @discardableResult
    func delete(id: UUID) -> Bool {
        guard let template = modelsByID[id] else {
            failure = .delete
            return false
        }

        do {
            try store.delete(template)
            guard reload() else { return false }
            return true
        } catch {
            failure = .delete
            return false
        }
    }

    func dismissFailure() {
        failure = nil
    }

    private func makeSnapshot(
        from template: TokenBoardTemplate
    ) throws -> TokenBoardTemplateSnapshot {
        guard let goal = template.goal else {
            throw TokenBoardTemplateValidationError.invalidPersistedGoal
        }

        return TokenBoardTemplateSnapshot(
            id: template.id,
            name: template.name,
            goal: goal,
            reward: TokenBoardReward(
                label: template.rewardLabel,
                systemSymbolName: template.rewardSystemSymbolName
            )
        )
    }
}
