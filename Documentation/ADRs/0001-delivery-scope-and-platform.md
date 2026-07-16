# ADR-0001: Delivery scope and platform baseline

- Status: Accepted
- Date: 2026-07-15

## Context

The original plan called five tools the MVP while identifying only three as the functional nucleus. It also used a moving minimum-OS rule and a CI destination that could not support the required SwiftData framework.

## Decision

- The core private beta is Visual Timer, First–Then Board, Token Board, adaptive navigation, settings, and reset.
- Choice Board begins only after the core beta passes Gate B.
- Regulation Cards require the clinical-content gate and may move to v1.1.
- User-created regulation cards are out of v1.
- The deployment target is iOS/iPadOS 18.0.
- CI is pinned to macOS 15, Xcode 16.4, and iOS 18.5 until an explicit toolchain update.
- V1 is English-only, with all user-facing strings externalized for later localization.
- Use one Xcode project; add a workspace only when a real multi-project need exists.
- GitHub Issues are the active backlog. Repository Markdown contains durable product, architecture, validation, and decision material.

## Consequences

This sequence delivers evidence earlier and reduces speculative shared infrastructure. Photo handling and clinical content no longer silently expand the first implementation milestones. Toolchain upgrades become intentional repository changes.
