import Synchronization
import XCTest
@testable import OTToolkit

final class VisualTimerStateMachineTests: XCTestCase {
    func testNewStateMachineStartsIdle() {
        var timer = VisualTimerStateMachine(clock: ManualVisualTimerClock())

        XCTAssertEqual(timer.reconcile(), idleSnapshot)
        XCTAssertNil(timer.takePendingCompletion())
    }

    func testStartAcceptsPositiveDuration() throws {
        let clock = ManualVisualTimerClock()
        var timer = VisualTimerStateMachine(clock: clock)

        let snapshot = try timer.start(duration: .seconds(60))

        XCTAssertEqual(snapshot, runningSnapshot(total: .seconds(60), remaining: .seconds(60)))
    }

    func testStartAcceptsSmallestTestedPositiveDuration() throws {
        let clock = ManualVisualTimerClock()
        var timer = VisualTimerStateMachine(clock: clock)

        try timer.start(duration: .nanoseconds(1))
        clock.advance(by: .nanoseconds(1))

        XCTAssertEqual(timer.reconcile(), completedSnapshot(total: .nanoseconds(1)))
    }

    func testStartRejectsZeroDurationWithoutMutation() {
        var timer = VisualTimerStateMachine(clock: ManualVisualTimerClock())

        assertThrows(.invalidDuration(.zero)) {
            try timer.start(duration: .zero)
        }

        XCTAssertEqual(timer.reconcile(), idleSnapshot)
    }

    func testStartRejectsNegativeDurationWithoutMutation() {
        var timer = VisualTimerStateMachine(clock: ManualVisualTimerClock())

        assertThrows(.invalidDuration(.seconds(-1))) {
            try timer.start(duration: .seconds(-1))
        }

        XCTAssertEqual(timer.reconcile(), idleSnapshot)
    }

    func testIdleRejectsPauseAndResume() {
        var timer = VisualTimerStateMachine(clock: ManualVisualTimerClock())

        assertThrows(.invalidTransition(command: .pause, phase: .idle)) {
            try timer.pause()
        }
        assertThrows(.invalidTransition(command: .resume, phase: .idle)) {
            try timer.resume()
        }

        XCTAssertEqual(timer.reconcile(), idleSnapshot)
    }

    func testRunningRejectsStartAndResumeWithoutMutation() throws {
        let clock = ManualVisualTimerClock()
        var timer = VisualTimerStateMachine(clock: clock)
        try timer.start(duration: .seconds(10))
        clock.advance(by: .seconds(3))

        assertThrows(.invalidTransition(command: .start, phase: .running)) {
            try timer.start(duration: .seconds(5))
        }
        assertThrows(.invalidTransition(command: .resume, phase: .running)) {
            try timer.resume()
        }

        XCTAssertEqual(
            timer.reconcile(),
            runningSnapshot(total: .seconds(10), remaining: .seconds(7))
        )

        clock.advance(by: .seconds(7))

        XCTAssertEqual(timer.reconcile(), completedSnapshot(total: .seconds(10)))
    }

    func testPausedRejectsStartAndPauseWithoutMutation() throws {
        let clock = ManualVisualTimerClock()
        var timer = VisualTimerStateMachine(clock: clock)
        try timer.start(duration: .seconds(10))
        let expected = try timer.pause()

        assertThrows(.invalidTransition(command: .start, phase: .paused)) {
            try timer.start(duration: .seconds(5))
        }
        assertThrows(.invalidTransition(command: .pause, phase: .paused)) {
            try timer.pause()
        }

        XCTAssertEqual(timer.reconcile(), expected)
    }

    func testCompletedRejectsStartPauseAndResumeWithoutConsumingCompletion() throws {
        let clock = ManualVisualTimerClock()
        var timer = VisualTimerStateMachine(clock: clock)
        try timer.start(duration: .seconds(1))
        clock.advance(by: .seconds(1))
        let expected = timer.reconcile()

        assertThrows(.invalidTransition(command: .start, phase: .completed)) {
            try timer.start(duration: .seconds(5))
        }
        assertThrows(.invalidTransition(command: .pause, phase: .completed)) {
            try timer.pause()
        }
        assertThrows(.invalidTransition(command: .resume, phase: .completed)) {
            try timer.resume()
        }

        XCTAssertEqual(timer.reconcile(), expected)
        XCTAssertEqual(
            timer.takePendingCompletion(), VisualTimerCompletion(configuredDuration: .seconds(1)))
    }

    func testPauseImmediatelyPreservesFullDuration() throws {
        var timer = VisualTimerStateMachine(clock: ManualVisualTimerClock())
        try timer.start(duration: .seconds(10))

        XCTAssertEqual(
            try timer.pause(),
            pausedSnapshot(total: .seconds(10), remaining: .seconds(10))
        )
    }

    func testPauseCapturesRemainingDuration() throws {
        let clock = ManualVisualTimerClock()
        var timer = VisualTimerStateMachine(clock: clock)
        try timer.start(duration: .seconds(10))
        clock.advance(by: .seconds(3))

        XCTAssertEqual(
            try timer.pause(),
            pausedSnapshot(total: .seconds(10), remaining: .seconds(7))
        )
    }

    func testPauseNearDeadlineCapturesPositiveRemainder() throws {
        let clock = ManualVisualTimerClock()
        var timer = VisualTimerStateMachine(clock: clock)
        try timer.start(duration: .seconds(1))
        clock.advance(by: .seconds(1) - .nanoseconds(1))

        XCTAssertEqual(
            try timer.pause(),
            pausedSnapshot(total: .seconds(1), remaining: .nanoseconds(1))
        )
    }

    func testPauseAtDeadlineReconcilesToCompletedBeforeRejectingCommand() throws {
        let clock = ManualVisualTimerClock()
        var timer = VisualTimerStateMachine(clock: clock)
        try timer.start(duration: .seconds(1))
        clock.advance(by: .seconds(1))

        assertThrows(.invalidTransition(command: .pause, phase: .completed)) {
            try timer.pause()
        }

        XCTAssertEqual(timer.reconcile(), completedSnapshot(total: .seconds(1)))
        XCTAssertEqual(
            timer.takePendingCompletion(),
            VisualTimerCompletion(configuredDuration: .seconds(1))
        )
        XCTAssertNil(timer.takePendingCompletion())
    }

    func testStartAtDeadlineReconcilesToCompletedBeforeRejectingCommand() throws {
        let clock = ManualVisualTimerClock()
        var timer = VisualTimerStateMachine(clock: clock)
        try timer.start(duration: .seconds(1))
        clock.advance(by: .seconds(1))

        assertThrows(.invalidTransition(command: .start, phase: .completed)) {
            try timer.start(duration: .seconds(5))
        }

        XCTAssertEqual(timer.reconcile(), completedSnapshot(total: .seconds(1)))
        XCTAssertEqual(
            timer.takePendingCompletion(),
            VisualTimerCompletion(configuredDuration: .seconds(1))
        )
        XCTAssertNil(timer.takePendingCompletion())
    }

    func testResumeAtDeadlineReconcilesToCompletedBeforeRejectingCommand() throws {
        let clock = ManualVisualTimerClock()
        var timer = VisualTimerStateMachine(clock: clock)
        try timer.start(duration: .seconds(1))
        clock.advance(by: .seconds(1))

        assertThrows(.invalidTransition(command: .resume, phase: .completed)) {
            try timer.resume()
        }

        XCTAssertEqual(timer.reconcile(), completedSnapshot(total: .seconds(1)))
        XCTAssertEqual(
            timer.takePendingCompletion(),
            VisualTimerCompletion(configuredDuration: .seconds(1))
        )
        XCTAssertNil(timer.takePendingCompletion())
    }

    func testTimeSpentPausedDoesNotReduceRemainingDuration() throws {
        let clock = ManualVisualTimerClock()
        var timer = VisualTimerStateMachine(clock: clock)
        try timer.start(duration: .seconds(10))
        clock.advance(by: .seconds(3))
        let paused = try timer.pause()

        clock.advance(by: .seconds(86_400))

        XCTAssertEqual(timer.reconcile(), paused)
        XCTAssertNil(timer.takePendingCompletion())
    }

    func testResumeCreatesDeadlineFromCapturedRemainder() throws {
        let clock = ManualVisualTimerClock()
        var timer = VisualTimerStateMachine(clock: clock)
        try timer.start(duration: .seconds(10))
        clock.advance(by: .seconds(3))
        try timer.pause()
        clock.advance(by: .seconds(3_600))

        XCTAssertEqual(
            try timer.resume(),
            runningSnapshot(total: .seconds(10), remaining: .seconds(7))
        )

        clock.advance(by: .seconds(2))
        XCTAssertEqual(
            timer.reconcile(),
            runningSnapshot(total: .seconds(10), remaining: .seconds(5))
        )
    }

    func testRepeatedPauseResumeSegmentsUseExactElapsedMath() throws {
        let clock = ManualVisualTimerClock()
        var timer = VisualTimerStateMachine(clock: clock)
        try timer.start(duration: .seconds(10))

        clock.advance(by: .seconds(2))
        try timer.pause()
        clock.advance(by: .seconds(100))
        try timer.resume()
        clock.advance(by: .seconds(3))

        XCTAssertEqual(
            try timer.pause(),
            pausedSnapshot(total: .seconds(10), remaining: .seconds(5))
        )

        try timer.resume()
        clock.advance(by: .seconds(5))
        XCTAssertEqual(timer.reconcile(), completedSnapshot(total: .seconds(10)))
    }

    func testReconcileBeforeDeadlineUsesMonotonicElapsedTime() throws {
        let clock = ManualVisualTimerClock()
        var timer = VisualTimerStateMachine(clock: clock)
        try timer.start(duration: .seconds(10))

        clock.advance(by: .seconds(9))

        XCTAssertEqual(
            timer.reconcile(),
            runningSnapshot(total: .seconds(10), remaining: .seconds(1))
        )
        XCTAssertNil(timer.takePendingCompletion())
    }

    func testReconcileExactlyAtDeadlineCompletes() throws {
        let clock = ManualVisualTimerClock()
        var timer = VisualTimerStateMachine(clock: clock)
        try timer.start(duration: .seconds(10))

        clock.advance(by: .seconds(10))

        XCTAssertEqual(timer.reconcile(), completedSnapshot(total: .seconds(10)))
    }

    func testLongReconciliationDelayCompletesWithoutNegativeRemainingTime() throws {
        let clock = ManualVisualTimerClock()
        var timer = VisualTimerStateMachine(clock: clock)
        try timer.start(duration: .seconds(10))

        clock.advance(by: .seconds(86_400))

        XCTAssertEqual(timer.reconcile(), completedSnapshot(total: .seconds(10)))
    }

    func testForegroundReconciliationBeforeDeadlineKeepsTimerRunning() throws {
        let clock = ManualVisualTimerClock()
        var timer = VisualTimerStateMachine(clock: clock)
        try timer.start(duration: .seconds(10))

        clock.advance(by: .seconds(4))

        XCTAssertEqual(
            timer.reconcile(),
            runningSnapshot(total: .seconds(10), remaining: .seconds(6))
        )
        XCTAssertNil(timer.takePendingCompletion())
    }

    func testForegroundReconciliationAfterDeadlineCompletesWithOnePendingEvent() throws {
        let clock = ManualVisualTimerClock()
        var timer = VisualTimerStateMachine(clock: clock)
        try timer.start(duration: .seconds(10))

        clock.advance(by: .seconds(15))

        XCTAssertEqual(timer.reconcile(), completedSnapshot(total: .seconds(10)))
        XCTAssertEqual(
            timer.takePendingCompletion(),
            VisualTimerCompletion(configuredDuration: .seconds(10))
        )
        XCTAssertNil(timer.takePendingCompletion())
    }

    func testRepeatedReconciliationDoesNotRearmConsumedCompletion() throws {
        let clock = ManualVisualTimerClock()
        var timer = VisualTimerStateMachine(clock: clock)
        try timer.start(duration: .seconds(1))
        clock.advance(by: .seconds(1))

        XCTAssertNotNil(timer.takePendingCompletion())
        XCTAssertEqual(timer.reconcile(), completedSnapshot(total: .seconds(1)))
        XCTAssertEqual(timer.reconcile(), completedSnapshot(total: .seconds(1)))
        XCTAssertNil(timer.takePendingCompletion())
    }

    func testResetBeforeCompletionConsumptionDropsPendingEvent() throws {
        let clock = ManualVisualTimerClock()
        var timer = VisualTimerStateMachine(clock: clock)
        try timer.start(duration: .seconds(1))
        clock.advance(by: .seconds(1))
        timer.reconcile()

        XCTAssertEqual(timer.reset(), idleSnapshot)
        XCTAssertNil(timer.takePendingCompletion())
    }

    func testNewRunAfterResetCanDeliverOneNewCompletion() throws {
        let clock = ManualVisualTimerClock()
        var timer = VisualTimerStateMachine(clock: clock)
        try timer.start(duration: .seconds(1))
        clock.advance(by: .seconds(1))
        XCTAssertNotNil(timer.takePendingCompletion())

        timer.reset()
        try timer.start(duration: .seconds(2))
        clock.advance(by: .seconds(2))

        XCTAssertEqual(
            timer.takePendingCompletion(),
            VisualTimerCompletion(configuredDuration: .seconds(2))
        )
        XCTAssertNil(timer.takePendingCompletion())
    }

    func testResetIsIdempotentFromEveryPhase() throws {
        let clock = ManualVisualTimerClock()
        var timer = VisualTimerStateMachine(clock: clock)

        XCTAssertEqual(timer.reset(), idleSnapshot)
        XCTAssertEqual(timer.reset(), idleSnapshot)

        try timer.start(duration: .seconds(10))
        XCTAssertEqual(timer.reset(), idleSnapshot)
        XCTAssertEqual(timer.reset(), idleSnapshot)

        try timer.start(duration: .seconds(10))
        try timer.pause()
        XCTAssertEqual(timer.reset(), idleSnapshot)
        XCTAssertEqual(timer.reset(), idleSnapshot)

        try timer.start(duration: .seconds(1))
        clock.advance(by: .seconds(1))
        timer.reconcile()
        XCTAssertEqual(timer.reset(), idleSnapshot)
        XCTAssertEqual(timer.reset(), idleSnapshot)
    }

    func testNewInstanceDoesNotRestoreExistingRun() throws {
        let clock = ManualVisualTimerClock()
        var existingTimer = VisualTimerStateMachine(clock: clock)
        try existingTimer.start(duration: .seconds(10))
        clock.advance(by: .seconds(5))

        var relaunchedTimer = VisualTimerStateMachine(clock: clock)

        XCTAssertEqual(relaunchedTimer.reconcile(), idleSnapshot)
        XCTAssertNil(relaunchedTimer.takePendingCompletion())
        XCTAssertEqual(
            existingTimer.reconcile(),
            runningSnapshot(total: .seconds(10), remaining: .seconds(5))
        )
    }

    private var idleSnapshot: VisualTimerSnapshot {
        VisualTimerSnapshot(
            phase: .idle,
            configuredDuration: nil,
            remainingDuration: nil
        )
    }

    private func runningSnapshot(total: Duration, remaining: Duration) -> VisualTimerSnapshot {
        VisualTimerSnapshot(
            phase: .running,
            configuredDuration: total,
            remainingDuration: remaining
        )
    }

    private func pausedSnapshot(total: Duration, remaining: Duration) -> VisualTimerSnapshot {
        VisualTimerSnapshot(
            phase: .paused,
            configuredDuration: total,
            remainingDuration: remaining
        )
    }

    private func completedSnapshot(total: Duration) -> VisualTimerSnapshot {
        VisualTimerSnapshot(
            phase: .completed,
            configuredDuration: total,
            remainingDuration: .zero
        )
    }

    private func assertThrows<T>(
        _ expectedError: VisualTimerError,
        file: StaticString = #filePath,
        line: UInt = #line,
        _ operation: () throws -> T
    ) {
        do {
            _ = try operation()
            XCTFail("Expected error \(expectedError)", file: file, line: line)
        } catch let error as VisualTimerError {
            XCTAssertEqual(error, expectedError, file: file, line: line)
        } catch {
            XCTFail("Unexpected error \(error)", file: file, line: line)
        }
    }
}

private final class ManualVisualTimerClock: VisualTimerClock, Sendable {
    private let instant: Mutex<ContinuousClock.Instant>

    init(now: ContinuousClock.Instant = ContinuousClock().now) {
        instant = Mutex(now)
    }

    var now: ContinuousClock.Instant {
        instant.withLock { $0 }
    }

    func advance(by duration: Duration) {
        precondition(duration >= .zero)

        instant.withLock {
            $0 = $0.advanced(by: duration)
        }
    }
}
