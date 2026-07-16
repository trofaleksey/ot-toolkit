# ADR-0002: Private-beta timer lifecycle

- Status: Accepted
- Date: 2026-07-15

## Context

A stored wall-clock end date is vulnerable to system-time changes. A reliable timer also needs explicit behavior for app suspension, device locking, process termination, completion feedback, and screen-awake ownership.

## Decision

### State

The domain states are idle, running, paused, and completed.

- Start creates a duration and monotonic deadline.
- Pause captures remaining duration and removes the active deadline.
- Resume creates a new monotonic deadline from the captured duration.
- Reset returns to idle and clears completion delivery state.

### Time source

Swift ContinuousClock semantics are the source of truth while the process is alive: time advances across process suspension and is unaffected by wall-clock changes. The domain receives an injectable abstraction with equivalent semantics so tests control time deterministically. UI ticks only trigger display refresh.

### Scene lifecycle

- Becoming inactive or backgrounded does not pause the timer.
- The app does not request background execution.
- When the same process returns, state reconciles immediately from the monotonic clock.
- If the deadline elapsed while suspended, the state becomes completed.
- Force-quit, process eviction, device reboot, or relaunch does not restore an active timer in the private beta; the app opens idle.

### Feedback

- Sound and haptics are optional, foreground-only, and delivered at most once per run.
- If completion occurred while suspended, completed state is shown on return and any enabled feedback is delivered once then.
- Local notifications and lock-screen timer alerts are deferred pending a separate permission/privacy decision.

### Screen awake

The app disables the system idle timer only while the domain is running and the scene is foreground-active. It restores prior behavior when paused, completed, reset, backgrounded, dismissed, or deinitialized.

## Required tests

- Every valid and invalid state transition.
- Pause/resume math and zero-duration boundaries.
- Long UI tick delay.
- Inactive/background and foreground before/after the deadline.
- Manual wall-clock jump while monotonic time is unchanged.
- Exactly-once completion feedback.
- Idle-timer restoration on every exit path.
- Relaunch opens idle.

## Consequences

The private beta has deterministic semantics without notification permission or persisted active-timer state. OTK-012 tells testers that force-quitting/process loss ends the active timer and no background alert is guaranteed, then Gate B records whether that limit is acceptable for release. Restoring timers or adding notifications requires a new ADR.
