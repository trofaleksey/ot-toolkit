# OT Toolkit

OT Toolkit is a native iPhone and iPad toolkit for pediatric occupational therapists. It prioritizes fast in-session support, calm child-facing visuals, accessibility, offline reliability, and minimal collection of sensitive data.

## Status

Foundation baseline. The repository contains a universal SwiftUI app target, unit and UI-test targets, a shared scheme/test plan, and pinned Xcode CI. Feature implementation begins with the adaptive shell and Visual Timer milestones in the roadmap.

## Core private beta

- Visual Timer
- First–Then Board
- Token Board
- Adaptive navigation, sensory settings, and complete local-data reset

Choice Board is gated behind core validation. Regulation Cards are gated behind clinical-content governance and may ship in v1.1.

## Documentation

- [Product](Documentation/PRODUCT.md)
- [Roadmap](Documentation/ROADMAP.md)
- [Architecture](Documentation/ARCHITECTURE.md)
- [Design system](Documentation/DESIGN_SYSTEM.md)
- [Privacy](Documentation/PRIVACY.md)
- [Validation plan](Documentation/VALIDATION_PLAN.md)
- [Regulation content governance](Documentation/CONTENT_GOVERNANCE.md)
- [Architecture decisions](Documentation/ADRs)
- [Engineering instructions](AGENTS.md)

## Project management

GitHub Issues are the active backlog and should use OTK-XXX identifiers. Milestones mirror ROADMAP.md. Pull requests link a primary issue and must not contain real child or patient information.

The repository should remain private until ownership and licensing for source code, illustrations, sounds, and clinical content are explicitly decided.

## Development

Xcode 26.6 with the iOS 26.5 simulator is the authoritative CI baseline. CI also runs the same checks with Xcode 16.4 and iOS 18.5 to protect the iOS/iPadOS 18.0 deployment target.

Format and lint Swift source with the Apple toolchain:

```sh
./Scripts/format.sh
./Scripts/lint.sh
```

Run the shared test plan with `xcodebuild`:

```sh
xcodebuild test \
  -project OTToolkit.xcodeproj \
  -scheme OTToolkit \
  -testPlan OTToolkit \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  CODE_SIGNING_ALLOWED=NO
```

Use an installed local simulator name and OS when needed. CI also runs the critical UI smoke flow on iPad and unsigned Debug and Release builds in both toolchain lanes.

## Privacy reminder

Do not include real patient/child names, photos, board content, screenshots, clinical narratives, or unsanitized logs in this repository or its GitHub Issues.

## License

No open-source license has been granted. All rights are reserved until the repository owner makes an explicit license decision.
