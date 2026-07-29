# OT Toolkit

OT Toolkit is a native iPhone and iPad toolkit for pediatric occupational therapists. It prioritizes fast in-session support, calm child-facing visuals, accessibility, offline reliability, and minimal collection of sensitive data.

## Status

Four tools are implemented: Visual Timer, First–Then Board (including an ephemeral multi-board visual schedule), Token Board, and Choice Board. These sit on the adaptive shell, design and accessibility foundation, protected local store, required settings and disclosures, and idempotent reset.

Choice Board is a candidate-v1 feature that the maintainer scheduled ahead of Gate B rather than after it. Gate B itself has not run: it depends on OTK-005 tester recruitment, which is the critical path to the beta.

## Core private beta

- Visual Timer
- First–Then Board, including a session visual schedule across several saved boards
- Token Board
- Adaptive navigation, sensory settings, and complete local-data reset

Choice Board is implemented and belongs to candidate v1 rather than the core beta. Regulation Cards remain gated behind clinical-content governance and may ship in v1.1; `Documentation/REGULATION_CONTENT_PLAN.md` is a draft awaiting a named clinical-content owner.

## Documentation

- [Product](Documentation/PRODUCT.md)
- [Roadmap](Documentation/ROADMAP.md)
- [Architecture](Documentation/ARCHITECTURE.md)
- [Design system](Documentation/DESIGN_SYSTEM.md)
- [Privacy](Documentation/PRIVACY.md)
- [Privacy policy](Documentation/PRIVACY_POLICY.md)
- [Beta release readiness](Documentation/BETA_RELEASE.md)
- [Regulation content plan (draft)](Documentation/REGULATION_CONTENT_PLAN.md)
- [Asset provenance](Documentation/ASSET_PROVENANCE.md)
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
