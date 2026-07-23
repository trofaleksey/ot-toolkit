import Foundation
@preconcurrency import SwiftData

@Model
final class TokenBoardTemplate {
    @Attribute(.unique) var id: UUID
    var name: String
    var goalRawValue: Int
    var rewardLabel: String
    var rewardSystemSymbolName: String
    var sortIndex: Int
    var createdAt: Date
    var updatedAt: Date

    var goal: TokenBoardGoal? {
        TokenBoardGoal(rawValue: goalRawValue)
    }

    init(
        id: UUID,
        name: String,
        goalRawValue: Int,
        rewardLabel: String,
        rewardSystemSymbolName: String,
        sortIndex: Int,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.name = name
        self.goalRawValue = goalRawValue
        self.rewardLabel = rewardLabel
        self.rewardSystemSymbolName = rewardSystemSymbolName
        self.sortIndex = sortIndex
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
