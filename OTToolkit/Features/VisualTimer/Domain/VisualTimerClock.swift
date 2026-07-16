protocol VisualTimerClock: Sendable {
    var now: ContinuousClock.Instant { get }
}

extension ContinuousClock: VisualTimerClock {}
