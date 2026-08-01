# ADR-0001: Delivery scope and platform baseline

- Status: Accepted (amended)
- Date: 2026-07-15
- Amended: 2026-07-31

## Context

The original plan called five tools the MVP while identifying only three as the functional nucleus. It also used a moving minimum-OS rule and a CI destination that could not support the required SwiftData framework.

After this ADR was accepted, the maintainer authorized OTK-050 (GitHub issue
#22) to ship Choice Board ahead of Gate B. That timing exception is now
implemented and documented in PRODUCT.md and ROADMAP.md; it does not change the
core-beta evidence Gate B must evaluate.

## Decision

- The core private beta is Visual Timer, First–Then Board, Token Board, adaptive navigation, settings, and reset.
- Choice Board was originally sequenced after Gate B. OTK-050 is the explicit
  exception: Choice Board shipped early as a candidate-v1 addition, remains
  outside the core private beta, and does not count as Gate B evidence.
- The OTK-050 exception does not unblock other post-Gate-B work. Regulation
  Cards still require Gate B and the OTK-060 clinical-content approval, and may
  move to v1.1.
- User-created regulation cards are out of v1.
- The deployment target is iOS/iPadOS 18.0.
- The original CI baseline is macOS 15, Xcode 16.4, and iOS 18.5; ADR-0004 supersedes this toolchain pin while retaining it as a compatibility lane.
- V1 is English-only, with all user-facing strings externalized for later localization.
- Use one Xcode project; add a workspace only when a real multi-project need exists.
- GitHub Issues are the active backlog. Repository Markdown contains durable product, architecture, validation, and decision material.

## Consequences

The three core tools remain the validation nucleus even though the binary also
contains Choice Board. The one recorded timing exception does not establish a
general precedent for bypassing release gates. This sequence delivers evidence
earlier and reduces speculative shared infrastructure. Photo handling and
clinical content no longer silently expand the first implementation milestones.
Toolchain upgrades become intentional repository changes.
