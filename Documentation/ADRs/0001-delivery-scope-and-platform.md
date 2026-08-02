# ADR-0001: Delivery scope and platform baseline

- Status: Accepted (amended)
- Date: 2026-07-15
- Amended: 2026-08-01

## Context

The original plan called five tools the MVP while identifying only three as the functional nucleus. It also used a moving minimum-OS rule and a CI destination that could not support the required SwiftData framework.

After this ADR was accepted, the maintainer authorized OTK-050 (GitHub issue
#22) to ship Choice Board ahead of Gate B. That timing exception is now
implemented and documented in PRODUCT.md and ROADMAP.md; it does not change the
core-beta evidence Gate B must evaluate.

The maintainer subsequently chose in GitHub issue #65 to defer external OT
recruitment and the participant-dependent validation gates while iterating from
feedback already available. The four implemented tools now define the
functional feedback MVP. This is a sequencing and scope decision, not evidence
that Gate A, Gate B, or Gate C passed.

## Decision

- The core private beta is Visual Timer, First–Then Board, Token Board, adaptive navigation, settings, and reset.
- Choice Board was originally sequenced after Gate B. OTK-050 is the explicit
  exception: Choice Board shipped early as a candidate-v1 addition, remains
  outside the original three-tool validation nucleus, and does not count as
  Gate B evidence.
- Visual Timer, First–Then Board, Token Board, and Choice Board together are the
  functional feedback MVP.
- External recruitment and the participant-dependent parts of Gate A, Gate B,
  and Gate C are deferred. They remain future evidence requirements if the app
  is later presented as therapist-validated; they are not marked passed.
- Regulation Cards are deferred beyond the functional feedback MVP. They still
  require OTK-060 clinical-content approval before implementation and must not
  be populated with unapproved clinical material.
- Repository-side release readiness, maintainer evaluation with synthetic or
  generic content, and fixes driven by concrete feedback may proceed without
  external recruitment. Privacy, accessibility, real-device, content-safety,
  and distribution checks are unchanged.
- User-created regulation cards are out of v1.
- The deployment target is iOS/iPadOS 18.0.
- The original CI baseline is macOS 15, Xcode 16.4, and iOS 18.5; ADR-0004 supersedes this toolchain pin while retaining it as a compatibility lane.
- V1 is English-only, with all user-facing strings externalized for later localization.
- Use one Xcode project; add a workspace only when a real multi-project need exists.
- GitHub Issues are the active backlog. Repository Markdown contains durable product, architecture, validation, and decision material.

## Consequences

The original three core tools remain the future Gate B validation nucleus, but
the current implementation target is the four-tool feedback MVP. External
validation is postponed rather than assumed. Regulation Cards no longer block
the feedback MVP and cannot silently bypass clinical governance. Photo handling
and clinical content remain explicitly gated. Toolchain upgrades remain
intentional repository changes.
