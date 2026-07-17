import Synchronization
import XCTest
@testable import OTToolkit

@MainActor
final class VisualTimerControllerTests: XCTestCase {
    func testDefaultAndPresetSelectionsProduceExpectedDurations() {
        let controller = VisualTimerController(clock: ManualPresentationClock())

        XCTAssertEqual(controller.selectedPreset, .fiveMinutes)
        XCTAssertEqual(controller.selectedDuration, .seconds(300))

        controller.select(.oneMinute)
        XCTAssertEqual(controller.selectedPreset, .oneMinute)
        XCTAssertEqual(controller.selectedDuration, .seconds(60))

        controller.select(.fifteenMinutes)
        XCTAssertEqual(controller.selectedPreset, .fifteenMinutes)
        XCTAssertEqual(controller.selectedDuration, .seconds(900))
    }

    func testCustomSelectionAcceptsOnlyOneThroughOneHundredTwentyMinutes() {
        let controller = VisualTimerController(clock: ManualPresentationClock())

        XCTAssertTrue(controller.selectCustom(minutes: 1))
        XCTAssertEqual(controller.selectedDuration, .seconds(60))
        XCTAssertNil(controller.selectedPreset)

        XCTAssertTrue(controller.selectCustom(minutes: 120))
        XCTAssertEqual(controller.selectedDuration, .seconds(7_200))

        XCTAssertFalse(controller.selectCustom(minutes: 0))
        XCTAssertFalse(controller.selectCustom(minutes: 121))
        XCTAssertEqual(controller.customMinutes, 120)
        XCTAssertEqual(controller.selectedDuration, .seconds(7_200))
    }

    func testStartPauseResumeAndResetExposeOnlyDomainSnapshots() {
        let clock = ManualPresentationClock()
        let controller = VisualTimerController(clock: clock)

        XCTAssertTrue(controller.start())
        XCTAssertEqual(controller.phase, .running)
        XCTAssertEqual(controller.remainingClockText, "5:00")
        XCTAssertEqual(controller.progressFraction, 1, accuracy: 0.000_001)

        clock.advance(by: .seconds(60))
        controller.refresh()
        XCTAssertEqual(controller.remainingClockText, "4:00")
        XCTAssertEqual(controller.progressFraction, 0.8, accuracy: 0.000_001)

        XCTAssertTrue(controller.pause())
        XCTAssertEqual(controller.phase, .paused)
        clock.advance(by: .seconds(60))
        controller.refresh()
        XCTAssertEqual(controller.remainingClockText, "4:00")

        XCTAssertTrue(controller.resume())
        XCTAssertEqual(controller.phase, .running)

        controller.reset()
        XCTAssertEqual(controller.phase, .idle)
        XCTAssertEqual(controller.completionSequence, 0)
    }

    func testDelayedRefreshCompletesAndConsumesAnnouncementExactlyOnce() {
        let clock = ManualPresentationClock()
        let controller = VisualTimerController(
            clock: clock,
            startDurationOverride: .seconds(1)
        )

        XCTAssertTrue(controller.start())
        clock.advance(by: .seconds(10))

        controller.refresh()
        XCTAssertEqual(controller.phase, .completed)
        XCTAssertEqual(controller.remainingClockText, "0:00")
        XCTAssertEqual(controller.progressFraction, 0, accuracy: 0.000_001)
        XCTAssertEqual(controller.completionSequence, 1)

        controller.refresh()
        controller.refresh()
        XCTAssertEqual(controller.completionSequence, 1)

        controller.reset()
        XCTAssertTrue(controller.start())
        clock.advance(by: .seconds(1))
        controller.refresh()
        XCTAssertEqual(controller.completionSequence, 2)
    }

    func testDisplayRoundsPartialRemainingSecondsUp() {
        let clock = ManualPresentationClock()
        let controller = VisualTimerController(
            clock: clock,
            startDurationOverride: .milliseconds(1_500)
        )

        XCTAssertTrue(controller.start())
        XCTAssertEqual(controller.remainingClockText, "0:02")

        clock.advance(by: .milliseconds(501))
        controller.refresh()
        XCTAssertEqual(controller.remainingClockText, "0:01")
    }
}

private final class ManualPresentationClock: VisualTimerClock, Sendable {
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
