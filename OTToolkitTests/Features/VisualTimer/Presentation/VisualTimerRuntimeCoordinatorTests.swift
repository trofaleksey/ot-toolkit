import Synchronization
import XCTest
@testable import OTToolkit

@MainActor
final class VisualTimerRuntimeCoordinatorTests: XCTestCase {
    func testRunningForegroundPresentedTimerOwnsAndPauseRestoresIdleTimer() {
        let harness = makeHarness()

        XCTAssertTrue(harness.controller.start())
        harness.synchronize()
        XCTAssertTrue(harness.idleTimer.isIdleTimerDisabled)

        XCTAssertTrue(harness.controller.pause())
        harness.synchronize()
        XCTAssertFalse(harness.idleTimer.isIdleTimerDisabled)
    }

    func testCompletionRestoresIdleTimer() {
        let harness = makeHarness()
        XCTAssertTrue(harness.controller.start())
        harness.synchronize()

        harness.clock.advance(by: .seconds(1))
        harness.controller.refresh()
        harness.synchronize()

        XCTAssertEqual(harness.controller.phase, .completed)
        XCTAssertFalse(harness.idleTimer.isIdleTimerDisabled)
    }

    func testResetRestoresIdleTimer() {
        let harness = makeHarness()
        XCTAssertTrue(harness.controller.start())
        harness.synchronize()

        harness.controller.reset()
        harness.synchronize()

        XCTAssertFalse(harness.idleTimer.isIdleTimerDisabled)
    }

    func testBackgroundRestoresIdleTimerWithoutPausingTimer() {
        let harness = makeHarness()
        XCTAssertTrue(harness.controller.start())
        harness.synchronize()

        harness.synchronize(isSceneActive: false)

        XCTAssertEqual(harness.controller.phase, .running)
        XCTAssertFalse(harness.idleTimer.isIdleTimerDisabled)
    }

    func testDismissalRestoresIdleTimerWithoutPausingTimer() {
        let harness = makeHarness()
        XCTAssertTrue(harness.controller.start())
        harness.synchronize()

        harness.synchronize(isTimerPresented: false)

        XCTAssertEqual(harness.controller.phase, .running)
        XCTAssertFalse(harness.idleTimer.isIdleTimerDisabled)
    }

    func testDeinitRestoresIdleTimer() {
        let idleTimer = RecordingIdleTimerController()
        let feedback = RecordingCompletionFeedback()
        let clock = ManualRuntimeClock()
        let controller = VisualTimerController(
            clock: clock,
            startDurationOverride: .seconds(1)
        )
        var coordinator: VisualTimerRuntimeCoordinator? = VisualTimerRuntimeCoordinator(
            idleTimer: idleTimer,
            completionFeedback: feedback
        )

        XCTAssertTrue(controller.start())
        coordinator?.synchronize(
            controller: controller,
            isSceneActive: true,
            isTimerPresented: true
        )
        XCTAssertTrue(idleTimer.isIdleTimerDisabled)

        coordinator = nil

        XCTAssertFalse(idleTimer.isIdleTimerDisabled)
    }

    func testIdleTimerRestoresValueThatExistedBeforeOwnership() {
        let harness = makeHarness(initialIdleTimerValue: true)
        XCTAssertTrue(harness.controller.start())
        harness.synchronize()

        XCTAssertTrue(harness.controller.pause())
        harness.synchronize()

        XCTAssertTrue(harness.idleTimer.isIdleTimerDisabled)
    }

    func testEnabledCompletionFeedbackIsDeliveredAtMostOncePerRun() {
        let harness = makeHarness()
        harness.controller.setCompletionSoundEnabled(true)
        harness.controller.setCompletionHapticEnabled(true)
        XCTAssertTrue(harness.controller.start())

        harness.clock.advance(by: .seconds(1))
        harness.controller.refresh()
        harness.synchronize()
        harness.synchronize()
        harness.controller.refresh()
        harness.synchronize()

        XCTAssertEqual(
            harness.feedback.deliveries,
            [.init(soundEnabled: true, hapticEnabled: true)]
        )
    }

    func testBackgroundCompletionFeedbackIsDeferredUntilForeground() {
        let harness = makeHarness()
        harness.controller.setCompletionHapticEnabled(true)
        XCTAssertTrue(harness.controller.start())
        harness.synchronize()

        harness.synchronize(isSceneActive: false)
        harness.clock.advance(by: .seconds(1))
        harness.controller.refresh()
        harness.synchronize(isSceneActive: false)
        XCTAssertTrue(harness.feedback.deliveries.isEmpty)

        harness.synchronize(isSceneActive: true)
        harness.synchronize(isSceneActive: true)

        XCTAssertEqual(
            harness.feedback.deliveries,
            [.init(soundEnabled: false, hapticEnabled: true)]
        )
    }

    private func makeHarness(initialIdleTimerValue: Bool = false) -> RuntimeHarness {
        let clock = ManualRuntimeClock()
        let controller = VisualTimerController(
            clock: clock,
            startDurationOverride: .seconds(1)
        )
        let idleTimer = RecordingIdleTimerController(
            isIdleTimerDisabled: initialIdleTimerValue
        )
        let feedback = RecordingCompletionFeedback()
        let coordinator = VisualTimerRuntimeCoordinator(
            idleTimer: idleTimer,
            completionFeedback: feedback
        )
        return RuntimeHarness(
            clock: clock,
            controller: controller,
            idleTimer: idleTimer,
            feedback: feedback,
            coordinator: coordinator
        )
    }
}

@MainActor
private struct RuntimeHarness {
    let clock: ManualRuntimeClock
    let controller: VisualTimerController
    let idleTimer: RecordingIdleTimerController
    let feedback: RecordingCompletionFeedback
    let coordinator: VisualTimerRuntimeCoordinator

    func synchronize(isSceneActive: Bool = true, isTimerPresented: Bool = true) {
        coordinator.synchronize(
            controller: controller,
            isSceneActive: isSceneActive,
            isTimerPresented: isTimerPresented
        )
    }
}

private final class RecordingIdleTimerController:
    VisualTimerIdleTimerControlling,
    @unchecked Sendable
{
    var isIdleTimerDisabled: Bool

    init(isIdleTimerDisabled: Bool = false) {
        self.isIdleTimerDisabled = isIdleTimerDisabled
    }
}

@MainActor
private final class RecordingCompletionFeedback: VisualTimerCompletionFeedbackDelivering {
    struct Delivery: Equatable {
        let soundEnabled: Bool
        let hapticEnabled: Bool
    }

    private(set) var deliveries: [Delivery] = []

    func deliverCompletion(soundEnabled: Bool, hapticEnabled: Bool) {
        deliveries.append(
            Delivery(soundEnabled: soundEnabled, hapticEnabled: hapticEnabled)
        )
    }
}

private final class ManualRuntimeClock: VisualTimerClock, Sendable {
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
