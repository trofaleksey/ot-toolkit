enum VisualTimerPhase: Equatable, Sendable {
    case idle
    case running
    case paused
    case completed
}

enum VisualTimerCommand: Equatable, Sendable {
    case start
    case pause
    case resume
}

enum VisualTimerError: Error, Equatable, Sendable {
    case invalidDuration(Duration)
    case invalidTransition(command: VisualTimerCommand, phase: VisualTimerPhase)
}

struct VisualTimerSnapshot: Equatable, Sendable {
    let phase: VisualTimerPhase
    let configuredDuration: Duration?
    let remainingDuration: Duration?
}

struct VisualTimerCompletion: Equatable, Sendable {
    let configuredDuration: Duration
}

struct VisualTimerStateMachine: Sendable {
    private enum Storage: Sendable {
        case idle
        case running(configuredDuration: Duration, deadline: ContinuousClock.Instant)
        case paused(configuredDuration: Duration, remainingDuration: Duration)
        case completed(configuredDuration: Duration)
    }

    private let clock: any VisualTimerClock
    private var storage = Storage.idle
    private var completionPending = false

    init(clock: any VisualTimerClock = ContinuousClock()) {
        self.clock = clock
    }

    @discardableResult
    mutating func start(duration: Duration) throws -> VisualTimerSnapshot {
        let now = clock.now
        reconcile(at: now)

        guard currentPhase == .idle else {
            throw VisualTimerError.invalidTransition(command: .start, phase: currentPhase)
        }
        guard duration > .zero else {
            throw VisualTimerError.invalidDuration(duration)
        }

        storage = .running(
            configuredDuration: duration,
            deadline: now.advanced(by: duration)
        )
        completionPending = false
        return snapshot(at: now)
    }

    @discardableResult
    mutating func pause() throws -> VisualTimerSnapshot {
        let now = clock.now
        reconcile(at: now)

        guard case let .running(configuredDuration, deadline) = storage else {
            throw VisualTimerError.invalidTransition(command: .pause, phase: currentPhase)
        }

        storage = .paused(
            configuredDuration: configuredDuration,
            remainingDuration: remainingDuration(
                configuredDuration: configuredDuration,
                deadline: deadline,
                now: now
            )
        )
        return snapshot(at: now)
    }

    @discardableResult
    mutating func resume() throws -> VisualTimerSnapshot {
        let now = clock.now
        reconcile(at: now)

        guard case let .paused(configuredDuration, remainingDuration) = storage else {
            throw VisualTimerError.invalidTransition(command: .resume, phase: currentPhase)
        }

        storage = .running(
            configuredDuration: configuredDuration,
            deadline: now.advanced(by: remainingDuration)
        )
        return snapshot(at: now)
    }

    @discardableResult
    mutating func reset() -> VisualTimerSnapshot {
        storage = .idle
        completionPending = false
        return idleSnapshot
    }

    @discardableResult
    mutating func reconcile() -> VisualTimerSnapshot {
        let now = clock.now
        reconcile(at: now)
        return snapshot(at: now)
    }

    mutating func takePendingCompletion() -> VisualTimerCompletion? {
        let now = clock.now
        reconcile(at: now)

        guard completionPending, case let .completed(configuredDuration) = storage else {
            return nil
        }

        completionPending = false
        return VisualTimerCompletion(configuredDuration: configuredDuration)
    }

    private var currentPhase: VisualTimerPhase {
        switch storage {
        case .idle:
            .idle
        case .running:
            .running
        case .paused:
            .paused
        case .completed:
            .completed
        }
    }

    private var idleSnapshot: VisualTimerSnapshot {
        VisualTimerSnapshot(
            phase: .idle,
            configuredDuration: nil,
            remainingDuration: nil
        )
    }

    private mutating func reconcile(at now: ContinuousClock.Instant) {
        guard case let .running(configuredDuration, deadline) = storage, now >= deadline else {
            return
        }

        storage = .completed(configuredDuration: configuredDuration)
        completionPending = true
    }

    private func snapshot(at now: ContinuousClock.Instant) -> VisualTimerSnapshot {
        switch storage {
        case .idle:
            idleSnapshot
        case let .running(configuredDuration, deadline):
            VisualTimerSnapshot(
                phase: .running,
                configuredDuration: configuredDuration,
                remainingDuration: remainingDuration(
                    configuredDuration: configuredDuration,
                    deadline: deadline,
                    now: now
                )
            )
        case let .paused(configuredDuration, remainingDuration):
            VisualTimerSnapshot(
                phase: .paused,
                configuredDuration: configuredDuration,
                remainingDuration: remainingDuration
            )
        case let .completed(configuredDuration):
            VisualTimerSnapshot(
                phase: .completed,
                configuredDuration: configuredDuration,
                remainingDuration: .zero
            )
        }
    }

    private func remainingDuration(
        configuredDuration: Duration,
        deadline: ContinuousClock.Instant,
        now: ContinuousClock.Instant
    ) -> Duration {
        min(configuredDuration, max(.zero, now.duration(to: deadline)))
    }
}
