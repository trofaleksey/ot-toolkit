# Architecture

## Overview

OT Toolkit is a universal, local-first SwiftUI application for iPhone and iPad. The architecture favors vertical feature slices, offline reliability, testable domain behavior, and accessible child-facing presentation.

Shared abstractions are extracted only after a second real consumer demonstrates the need. Third-party state frameworks and cross-platform layers are intentionally avoided.

## Reproducible platform baseline

- Language mode: Swift 6.
- UI framework: SwiftUI.
- Persistence: SwiftData for domain content; AppStorage for simple device preferences.
- Deployment target: iOS and iPadOS 18.0.
- Authoritative CI baseline: macOS 26 runner with Xcode 26.6 and an iOS 26.5 simulator.
- Compatibility CI baseline: macOS 15 runner with Xcode 16.4 and an iOS 18.5 simulator.
- Project: one OTToolkit.xcodeproj with app, unit-test, and UI-test targets.
- Shared artifacts: OTToolkit scheme and OTToolkit test plan.
- Language scope: English-only v1 with all user-facing strings in Localizable.xcstrings.
- App Intents metadata extraction: disabled until an approved feature introduces AppIntents.

Local Xcode versions do not replace the pinned authoritative and compatibility CI lanes. Changes to the deployment target or either toolchain require an ADR and matching CI update. A future App Intents feature must remove the metadata-extraction override and its bootstrap guard in the same change.

## Project structure

    OTToolkit/
    ├── App/
    │   ├── OTToolkitApp.swift
    │   ├── AppRouter.swift
    │   └── AppEnvironment.swift
    ├── Core/
    │   ├── DesignSystem/
    │   ├── Persistence/
    │   ├── Utilities/
    │   └── Accessibility/
    ├── Features/
    │   ├── Home/
    │   ├── VisualTimer/
    │   ├── FirstThen/
    │   ├── TokenBoard/
    │   ├── ChoiceBoard/
    │   ├── RegulationCards/
    │   ├── SavedBoards/
    │   └── Settings/
    └── Resources/
        ├── Assets.xcassets
        ├── ActivityLibrary.json
        └── Localizable.xcstrings

    OTToolkitTests/
    ├── Core/
    └── Features/

    OTToolkitUITests/
    └── CriticalFlows/

    Documentation/
    ├── ADRs/
    ├── ARCHITECTURE.md
    ├── CONTENT_GOVERNANCE.md
    ├── DESIGN_SYSTEM.md
    ├── PRIVACY.md
    ├── PRODUCT.md
    ├── ROADMAP.md
    └── VALIDATION_PLAN.md

Feature source and mirrored test paths own their domain types, views, observable state, services, fixtures, and focused tests. Core contains only code with multiple proven consumers.

## Dependency and state boundaries

- Plain Swift types own domain state transitions where practical.
- SwiftUI state owns transient presentation details.
- Observable feature controllers coordinate use cases and dependencies.
- SwiftData models describe persistence, not view state.
- Protocols are introduced for clocks, persistence boundaries, and content loading when fakes materially improve testing.
- Dependencies enter through initializers or typed SwiftUI environment values.
- ModelContext access is isolated to the main actor or a dedicated ModelActor; contexts are never shared unsafely.
- Global mutable state and a global AppViewModel are prohibited.

## Persistence contract

The first feature with a real persisted domain model establishes VersionedSchema V1 and SchemaMigrationPlan. V1 becomes immutable when the first persistent TestFlight build is distributed; a schema is never shipped as an unversioned prototype.

Persisted domain models require:

- Stable UUIDs plus created and updated timestamps.
- Explicit sort indexes for ordered items.
- Documented relationship optionality, inverse relationships, and delete rules.
- Stable bundled-content identifiers so favorites survive content updates.
- Explicit defaults and validation at the domain boundary.
- Non-destructive migration failure handling.

Migration failure preserves the original store and presents a recoverable blocking state. Reset is offered only after explicit confirmation. Reset first tears down the live ModelContainer and contexts, removes the store and sidecars, clears every app-owned AppStorage/UserDefaults key, recreates the protected directory and backup exclusion, and validates a fresh container. The operation is idempotent.

Tests cover in-memory CRUD and relationships, on-disk migration fixtures, delete cascades, reset behavior, and duplicate bundled-content identifiers. Simple sensory and appearance settings use AppStorage unless a concrete cross-model need justifies SwiftData.

Every v1 ModelConfiguration sets cloudKitDatabase to .none explicitly. Tests and release checks also verify that CloudKit entitlements are absent.

## Media contract

The core private beta uses bundled illustrations and SF Symbols. Camera and photo import are deferred under ADR-0003.

If media import is approved later, it must use a system picker with least-privilege access, re-encode and downsample into app-owned Application Support storage, remove source metadata, use stable file identifiers rather than SwiftData blobs, apply file protection and the documented backup policy, and delete derived, orphaned, temporary, and cached files. DESIGN_SYSTEM.md is the single source for pixel and decoded-memory budgets.

## Navigation

### Regular-width iPad

- NavigationSplitView provides sidebar, content, and detail columns.
- The sidebar lists tools, saved boards, and settings.
- Content provides templates or configuration.
- Detail hosts the active tool or child-facing presentation.

### Compact width and iPhone

- iPhone uses Tools, Saved, and Settings tabs with NavigationStack in each tab.
- iPad multitasking and compact-width layouts collapse to the same typed routes without losing active-tool state.
- iPhone landscape remains functional even though portrait receives primary design attention.

### Child-facing mode

Navigation chrome is minimized, but exit is never an undiscoverable corner gesture. A visible, labeled adult-exit control uses a deliberate hold/confirmation interaction and exposes equivalent VoiceOver, Switch Control, and keyboard behavior. Guided Access is supported through instructions, not assumed.

When the scene becomes inactive, a neutral privacy cover obscures board labels and child-facing content before the app-switcher snapshot is captured.

## Visual Timer contract

ADR-0002 is the source of truth. The private-beta timer has idle, running, paused, and completed states and uses Swift ContinuousClock semantics, behind an injected test-clock boundary, while the process is alive. This clock advances across suspension and is unaffected by wall-clock changes. Display refresh ticks never define elapsed time.

The timer continues logically while the scene is inactive or suspended, reconciles on return, and is not restored after force-quit or process termination in the private beta. Completion notifications while backgrounded are deferred. Foreground sound and haptics occur at most once. The app disables the idle timer only while the visual timer is running and foreground-active, then restores it on every exit path.

## Accessibility architecture

Every feature ticket includes testable requirements for:

- VoiceOver labels, values, actions, focus order, and announcement frequency.
- Dynamic Type through the largest accessibility categories without loss of required actions.
- Reduce Motion, Increase Contrast, Differentiate Without Color, and Reduce Transparency.
- Switch Control and keyboard access where applicable.
- Minimum 44 by 44 point controls.
- iPhone, full-width iPad, and compact iPad layouts.

Child-facing state is never communicated through color, sound, haptics, or motion alone.

## Testing strategy

- Pure unit tests cover domain transitions and validation.
- Persistence tests cover in-memory behavior and real on-disk migrations.
- Bundled JSON tests reject missing fields, duplicate stable IDs, and missing safety content.
- UI tests use deterministic launch arguments for store reset, seed data, timer duration, locale, and animation settings.
- Critical UI smoke flows run on iPhone and iPad.
- Automated accessibility audits supplement, but do not replace, the manual release matrix.

The canonical formatter commands use the Apple toolchain bundled with the selected Xcode:

    ./Scripts/format.sh
    ./Scripts/lint.sh

The canonical iPhone CI command runs the shared unit and UI test plan:

    xcodebuild test \
      -project OTToolkit.xcodeproj \
      -scheme OTToolkit \
      -testPlan OTToolkit \
      -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
      CODE_SIGNING_ALLOWED=NO

Critical iPad UI smoke tests run through the same plan in a second invocation:

    xcodebuild test \
      -project OTToolkit.xcodeproj \
      -scheme OTToolkit \
      -testPlan OTToolkit \
      -only-testing:OTToolkitUITests \
      -destination 'platform=iOS Simulator,name=iPad (A16),OS=26.5' \
      CODE_SIGNING_ALLOWED=NO

CI performs the same lint, settings verification, unsigned Debug and Release simulator builds, iPhone test plan, and iPad UI smoke tests in the authoritative and compatibility lanes. It uses warnings-as-errors for project code, result bundles on failures, read-only permissions, cancellation of superseded pull-request runs, and a bounded timeout. OTK-001 establishes the no-tracking manifest with no required-reason declarations; OTK-004 re-audits it when persistence and preferences are introduced.

## Decision records

ADRs capture durable choices such as scope, timer semantics, persistence, media, and privacy behavior. GitHub Issues track active work and must link the relevant ADR rather than restating it.
