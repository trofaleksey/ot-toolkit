enum TokenBoardGoal: Int, CaseIterable, Sendable {
    case three = 3
    case five = 5
    case eight = 8
    case ten = 10
}

struct TokenBoardReward: Equatable, Sendable {
    let label: String
    let systemSymbolName: String

    init(label: String, systemSymbolName: String) {
        self.label = label
        self.systemSymbolName = systemSymbolName
    }
}

enum TokenBoardCommand: Equatable, Sendable {
    case addToken
    case removeToken
}

enum TokenBoardError: Error, Equatable, Sendable {
    case boardComplete
    case boardEmpty
}

struct TokenBoardSnapshot: Equatable, Sendable {
    let goal: TokenBoardGoal
    let filledCount: Int
    let reward: TokenBoardReward

    var remainingCount: Int {
        goal.rawValue - filledCount
    }

    var isComplete: Bool {
        filledCount == goal.rawValue
    }
}

struct TokenBoardCompletion: Equatable, Sendable {
    let goal: TokenBoardGoal
    let reward: TokenBoardReward
}

/// Pure, deterministic Token Board domain: fill toward a fixed goal, remove
/// tokens, and reset. Completion is delivered once through
/// `takePendingCompletion()`, mirroring `VisualTimerStateMachine`; the sensory
/// feedback effect itself is injected at the presentation layer.
struct TokenBoardStateMachine: Sendable {
    private let goal: TokenBoardGoal
    private let reward: TokenBoardReward
    private var filledCount = 0
    private var completionPending = false

    init(goal: TokenBoardGoal, reward: TokenBoardReward) {
        self.goal = goal
        self.reward = reward
    }

    var snapshot: TokenBoardSnapshot {
        TokenBoardSnapshot(goal: goal, filledCount: filledCount, reward: reward)
    }

    @discardableResult
    mutating func addToken() throws -> TokenBoardSnapshot {
        guard filledCount < goal.rawValue else {
            throw TokenBoardError.boardComplete
        }

        filledCount += 1
        if filledCount == goal.rawValue {
            completionPending = true
        }
        return snapshot
    }

    @discardableResult
    mutating func removeToken() throws -> TokenBoardSnapshot {
        guard filledCount > 0 else {
            throw TokenBoardError.boardEmpty
        }

        filledCount -= 1
        completionPending = false
        return snapshot
    }

    @discardableResult
    mutating func reset() -> TokenBoardSnapshot {
        filledCount = 0
        completionPending = false
        return snapshot
    }

    mutating func takePendingCompletion() -> TokenBoardCompletion? {
        guard completionPending else {
            return nil
        }

        completionPending = false
        return TokenBoardCompletion(goal: goal, reward: reward)
    }
}
