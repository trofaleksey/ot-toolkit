# OT Toolkit

OT Toolkit is a planned native iPhone and iPad toolkit for pediatric occupational therapists. It prioritizes fast in-session support, calm child-facing visuals, accessibility, offline reliability, and minimal collection of sensitive data.

## Status

Planning baseline. The product and delivery plan have been reviewed; no Xcode project or app code exists yet. The first implementation issue is OTK-001, which will create the universal app, test targets, shared scheme/test plan, and real Xcode CI.

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

## Privacy reminder

Do not include real patient/child names, photos, board content, screenshots, clinical narratives, or unsanitized logs in this repository or its GitHub Issues.

## License

No open-source license has been granted. All rights are reserved until the repository owner makes an explicit license decision.
