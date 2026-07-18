import Foundation
import Observation

enum VisualTimerPreset: Int, CaseIterable, Identifiable, Sendable {
    case oneMinute = 1
    case threeMinutes = 3
    case fiveMinutes = 5
    case tenMinutes = 10
    case fifteenMinutes = 15

    var id: Int { rawValue }

    var duration: Duration {
        .seconds(rawValue * 60)
    }
}

@MainActor
@Observable
final class VisualTimerController {
    static let customMinuteRange = 1...120
    static let defaultCustomMinutes = 20

    private var stateMachine: VisualTimerStateMachine
    private let startDurationOverride: Duration?

    private(set) var snapshot: VisualTimerSnapshot
    private(set) var selectedPreset: VisualTimerPreset? = .fiveMinutes
    private(set) var customMinutes = defaultCustomMinutes
    private(set) var completionSequence = 0
    private(set) var isCompletionSoundEnabled = false
    private(set) var isCompletionHapticEnabled = false

    init(
        clock: any VisualTimerClock = ContinuousClock(),
        startDurationOverride: Duration? = nil
    ) {
        stateMachine = VisualTimerStateMachine(clock: clock)
        snapshot = VisualTimerSnapshot(
            phase: .idle,
            configuredDuration: nil,
            remainingDuration: nil
        )
        self.startDurationOverride = startDurationOverride
    }

    var phase: VisualTimerPhase {
        snapshot.phase
    }

    var selectedDuration: Duration {
        selectedPreset?.duration ?? .seconds(customMinutes * 60)
    }

    var selectedDurationDescription: String {
        durationDescription(seconds: selectedDuration.wholeSecondsRoundedUp)
    }

    var customDurationDescription: String {
        durationDescription(seconds: customMinutes * 60)
    }

    var remainingClockText: String {
        let totalSeconds = remainingSeconds
        let hours = totalSeconds / 3_600
        let minutes = (totalSeconds % 3_600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }

        return String(format: "%d:%02d", minutes, seconds)
    }

    var remainingAccessibilityValue: String {
        durationDescription(seconds: remainingSeconds)
    }

    var progressFraction: Double {
        guard
            let configuredDuration = snapshot.configuredDuration,
            let remainingDuration = snapshot.remainingDuration
        else {
            return 1
        }

        let configuredSeconds = configuredDuration.secondsValue
        guard configuredSeconds > 0 else {
            return 0
        }

        return min(1, max(0, remainingDuration.secondsValue / configuredSeconds))
    }

    var isRunning: Bool {
        phase == .running
    }

    func select(_ preset: VisualTimerPreset) {
        guard phase == .idle else { return }
        selectedPreset = preset
    }

    @discardableResult
    func selectCustom(minutes: Int) -> Bool {
        guard phase == .idle, Self.customMinuteRange.contains(minutes) else {
            return false
        }

        customMinutes = minutes
        selectedPreset = nil
        return true
    }

    func selectCurrentCustomDuration() {
        guard phase == .idle else { return }
        selectedPreset = nil
    }

    func setCompletionSoundEnabled(_ isEnabled: Bool) {
        isCompletionSoundEnabled = isEnabled
    }

    func setCompletionHapticEnabled(_ isEnabled: Bool) {
        isCompletionHapticEnabled = isEnabled
    }

    @discardableResult
    func start() -> Bool {
        let duration = startDurationOverride ?? selectedDuration
        return update { stateMachine in
            try stateMachine.start(duration: duration)
        }
    }

    @discardableResult
    func pause() -> Bool {
        update { stateMachine in
            try stateMachine.pause()
        }
    }

    @discardableResult
    func resume() -> Bool {
        update { stateMachine in
            try stateMachine.resume()
        }
    }

    func reset() {
        snapshot = stateMachine.reset()
    }

    func refresh() {
        let refreshedSnapshot = stateMachine.reconcile()
        if refreshedSnapshot != snapshot {
            snapshot = refreshedSnapshot
        }
        consumePendingCompletion()
    }

    private var remainingSeconds: Int {
        snapshot.remainingDuration?.wholeSecondsRoundedUp ?? 0
    }

    private func update(
        _ operation: (inout VisualTimerStateMachine) throws -> VisualTimerSnapshot
    ) -> Bool {
        do {
            snapshot = try operation(&stateMachine)
            consumePendingCompletion()
            return true
        } catch {
            snapshot = stateMachine.reconcile()
            consumePendingCompletion()
            return false
        }
    }

    private func consumePendingCompletion() {
        guard stateMachine.takePendingCompletion() != nil else { return }
        completionSequence += 1
    }

    private func durationDescription(seconds: Int) -> String {
        guard seconds > 0 else {
            return String(localized: "visualTimer.time.zero")
        }

        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .full
        formatter.zeroFormattingBehavior = .dropAll
        formatter.maximumUnitCount = 3

        if seconds >= 3_600 {
            formatter.allowedUnits = [.hour, .minute, .second]
        } else if seconds >= 60 {
            formatter.allowedUnits = [.minute, .second]
        } else {
            formatter.allowedUnits = [.second]
        }

        return formatter.string(from: TimeInterval(seconds))
            ?? String(localized: "visualTimer.time.zero")
    }
}

private extension Duration {
    var secondsValue: Double {
        let components = self.components
        return Double(components.seconds) + Double(components.attoseconds) / 1e18
    }

    var wholeSecondsRoundedUp: Int {
        Int(ceil(max(0, secondsValue)))
    }
}
