import Foundation
import SwiftData

struct TokenBoardTemplateDraft: Equatable, Sendable {
    let name: String
    let goal: TokenBoardGoal
    let reward: TokenBoardReward
}

enum TokenBoardTemplateValidationError: Error, Equatable {
    case emptyTemplateName
    case emptyRewardLabel
    case emptyRewardSymbolName
    case invalidTemplateOrder
    case invalidPersistedGoal
}

@MainActor
protocol TokenBoardTemplateStoring {
    func create(_ draft: TokenBoardTemplateDraft) throws -> TokenBoardTemplate
    func fetchTemplates() throws -> [TokenBoardTemplate]
    func update(_ template: TokenBoardTemplate, with draft: TokenBoardTemplateDraft) throws
    func delete(_ template: TokenBoardTemplate) throws
}

@MainActor
struct TokenBoardTemplateStore {
    typealias Now = @MainActor () -> Date

    private let modelContext: ModelContext
    private let now: Now

    init(
        modelContext: ModelContext,
        now: @escaping Now = { Date() }
    ) {
        self.modelContext = modelContext
        self.now = now
    }

    func create(
        _ draft: TokenBoardTemplateDraft,
        templateID: UUID = UUID()
    ) throws -> TokenBoardTemplate {
        let validated = try validate(draft)
        let timestamp = now()
        let template = TokenBoardTemplate(
            id: templateID,
            name: validated.name,
            goalRawValue: validated.goal.rawValue,
            rewardLabel: validated.reward.label,
            rewardSystemSymbolName: validated.reward.systemSymbolName,
            sortIndex: try nextTemplateSortIndex(),
            createdAt: timestamp,
            updatedAt: timestamp
        )

        modelContext.insert(template)
        try saveOrRollback()
        return template
    }

    func fetchTemplates() throws -> [TokenBoardTemplate] {
        try modelContext.fetch(
            FetchDescriptor<TokenBoardTemplate>(
                sortBy: [
                    SortDescriptor(\TokenBoardTemplate.sortIndex),
                    SortDescriptor(\TokenBoardTemplate.createdAt),
                ]
            )
        )
    }

    func update(_ template: TokenBoardTemplate, with draft: TokenBoardTemplateDraft) throws {
        let validated = try validate(draft)
        let timestamp = now()

        template.name = validated.name
        template.goalRawValue = validated.goal.rawValue
        template.rewardLabel = validated.reward.label
        template.rewardSystemSymbolName = validated.reward.systemSymbolName
        template.updatedAt = timestamp

        try saveOrRollback()
    }

    func reorder(templateIDs: [UUID]) throws {
        let templates = try fetchTemplates()
        guard templateIDs.count == templates.count,
            Set(templateIDs).count == templateIDs.count,
            Set(templateIDs) == Set(templates.map(\.id))
        else {
            throw TokenBoardTemplateValidationError.invalidTemplateOrder
        }

        let timestamp = now()
        let templatesByID = Dictionary(uniqueKeysWithValues: templates.map { ($0.id, $0) })
        for (sortIndex, id) in templateIDs.enumerated() {
            guard let template = templatesByID[id] else {
                throw TokenBoardTemplateValidationError.invalidTemplateOrder
            }
            template.sortIndex = sortIndex
            template.updatedAt = timestamp
        }

        try saveOrRollback()
    }

    func delete(_ template: TokenBoardTemplate) throws {
        modelContext.delete(template)
        try saveOrRollback()
    }

    private func validate(_ draft: TokenBoardTemplateDraft) throws -> TokenBoardTemplateDraft {
        let name = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            throw TokenBoardTemplateValidationError.emptyTemplateName
        }

        let label = draft.reward.label.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !label.isEmpty else {
            throw TokenBoardTemplateValidationError.emptyRewardLabel
        }

        let systemSymbolName = draft.reward.systemSymbolName.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        guard !systemSymbolName.isEmpty else {
            throw TokenBoardTemplateValidationError.emptyRewardSymbolName
        }

        return TokenBoardTemplateDraft(
            name: name,
            goal: draft.goal,
            reward: TokenBoardReward(label: label, systemSymbolName: systemSymbolName)
        )
    }

    private func nextTemplateSortIndex() throws -> Int {
        var descriptor = FetchDescriptor<TokenBoardTemplate>(
            sortBy: [SortDescriptor(\TokenBoardTemplate.sortIndex, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        guard let highestSortIndex = try modelContext.fetch(descriptor).first?.sortIndex else {
            return 0
        }
        return highestSortIndex + 1
    }

    private func saveOrRollback() throws {
        do {
            try modelContext.save()
        } catch {
            modelContext.rollback()
            throw error
        }
    }
}

extension TokenBoardTemplateStore: TokenBoardTemplateStoring {
    func create(_ draft: TokenBoardTemplateDraft) throws -> TokenBoardTemplate {
        try create(draft, templateID: UUID())
    }
}
