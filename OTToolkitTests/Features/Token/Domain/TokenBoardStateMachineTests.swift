import XCTest
@testable import OTToolkit

final class TokenBoardStateMachineTests: XCTestCase {
    private let reward = TokenBoardReward(label: "Sticker", systemSymbolName: "star.fill")

    func testNewBoardStartsEmptyForEveryGoal() {
        for goal in TokenBoardGoal.allCases {
            let board = TokenBoardStateMachine(goal: goal, reward: reward)
            let snapshot = board.snapshot

            XCTAssertEqual(snapshot.filledCount, 0, "\(goal)")
            XCTAssertEqual(snapshot.remainingCount, goal.rawValue, "\(goal)")
            XCTAssertFalse(snapshot.isComplete, "\(goal)")
            XCTAssertEqual(snapshot.reward, reward, "\(goal)")
        }
    }

    func testAddingTokensFillsUpToEachGoalAndCompletesOnce() throws {
        for goal in TokenBoardGoal.allCases {
            var board = TokenBoardStateMachine(goal: goal, reward: reward)

            for filled in 1...goal.rawValue {
                let snapshot = try board.addToken()
                XCTAssertEqual(snapshot.filledCount, filled, "\(goal)")
                XCTAssertEqual(snapshot.remainingCount, goal.rawValue - filled, "\(goal)")
            }

            XCTAssertTrue(board.snapshot.isComplete, "\(goal)")
            XCTAssertEqual(
                board.takePendingCompletion(),
                TokenBoardCompletion(goal: goal, reward: reward),
                "\(goal)"
            )
            XCTAssertNil(board.takePendingCompletion(), "\(goal)")
        }
    }

    func testCompletionDoesNotFireBeforeReachingGoal() throws {
        var board = TokenBoardStateMachine(goal: .five, reward: reward)

        for _ in 1..<TokenBoardGoal.five.rawValue {
            try board.addToken()
        }

        XCTAssertFalse(board.snapshot.isComplete)
        XCTAssertNil(board.takePendingCompletion())
    }

    func testAddingBeyondGoalThrowsWithoutMutation() throws {
        for goal in TokenBoardGoal.allCases {
            var board = TokenBoardStateMachine(goal: goal, reward: reward)
            for _ in 1...goal.rawValue {
                try board.addToken()
            }

            assertThrows(.boardComplete) {
                try board.addToken()
            }
            XCTAssertEqual(board.snapshot.filledCount, goal.rawValue, "\(goal)")
        }
    }

    func testRemovingFromEmptyThrowsWithoutMutation() {
        for goal in TokenBoardGoal.allCases {
            var board = TokenBoardStateMachine(goal: goal, reward: reward)

            assertThrows(.boardEmpty) {
                try board.removeToken()
            }
            XCTAssertEqual(board.snapshot.filledCount, 0, "\(goal)")
        }
    }

    func testRemovingATokenReversesPendingCompletion() throws {
        var board = TokenBoardStateMachine(goal: .three, reward: reward)
        for _ in 1...TokenBoardGoal.three.rawValue {
            try board.addToken()
        }

        let snapshot = try board.removeToken()

        XCTAssertFalse(snapshot.isComplete)
        XCTAssertEqual(snapshot.filledCount, 2)
        XCTAssertNil(board.takePendingCompletion())
    }

    func testRefillingAfterRemovalReArmsCompletion() throws {
        var board = TokenBoardStateMachine(goal: .three, reward: reward)
        for _ in 1...TokenBoardGoal.three.rawValue {
            try board.addToken()
        }
        _ = board.takePendingCompletion()
        try board.removeToken()

        try board.addToken()

        XCTAssertEqual(
            board.takePendingCompletion(),
            TokenBoardCompletion(goal: .three, reward: reward)
        )
    }

    func testResetClearsProgressAndPendingCompletionForEveryGoal() throws {
        for goal in TokenBoardGoal.allCases {
            var board = TokenBoardStateMachine(goal: goal, reward: reward)
            for _ in 1...goal.rawValue {
                try board.addToken()
            }

            let snapshot = board.reset()

            XCTAssertEqual(snapshot.filledCount, 0, "\(goal)")
            XCTAssertEqual(snapshot.remainingCount, goal.rawValue, "\(goal)")
            XCTAssertFalse(snapshot.isComplete, "\(goal)")
            XCTAssertEqual(snapshot.reward, reward, "\(goal)")
            XCTAssertNil(board.takePendingCompletion(), "\(goal)")
        }
    }

    func testRewardIsPreservedAcrossOperations() throws {
        var board = TokenBoardStateMachine(goal: .three, reward: reward)

        try board.addToken()
        try board.removeToken()
        try board.addToken()

        XCTAssertEqual(board.snapshot.reward, reward)
    }

    private func assertThrows(
        _ expected: TokenBoardError,
        file: StaticString = #filePath,
        line: UInt = #line,
        _ body: () throws -> Void
    ) {
        XCTAssertThrowsError(try body(), file: file, line: line) { error in
            XCTAssertEqual(error as? TokenBoardError, expected, file: file, line: line)
        }
    }
}
