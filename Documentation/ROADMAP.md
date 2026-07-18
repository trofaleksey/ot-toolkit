# Roadmap

## Operating model

GitHub Issues are the source of truth for active work, status, assignee, priority, and acceptance criteria. This file records sequencing and release gates; ADRs record durable decisions. Do not maintain a second ticket backlog in Markdown.

OTK roadmap IDs are allocated here by the maintainer and must be unique. GitHub issue numbers are separate and are the references pull requests use to close work.

Work in vertical slices and keep only one feature implementation in progress unless two tickets have no shared files or decisions. Optimize the private beta for a complete therapist journey across all three core tools, not for polish or reusable infrastructure within the first tool. Extract shared board infrastructure only when duplication is causing material maintenance cost; a second consumer alone does not make extraction release-blocking.

## Core-beta operating target

The private-beta journey is:

> Open the app, select a core tool, configure it quickly, enter child-facing mode, complete the activity, exit safely, and optionally reuse a saved board.

Work that neither enables nor protects this journey is deferred until after Gate B. In particular, the core-beta sequence excludes alternate timer visuals, nonessential appearance themes, board duplication, elaborate celebrations, speculative shared-board components, Choice Board, and Regulation Cards.

Delivery uses two evidence levels:

### Feature complete

A feature can advance to the next vertical slice when:

- Its bounded therapist and child-facing journey works end to end.
- Pure domain tests and required persistence/migration tests pass.
- Focused automated critical-flow coverage passes on iPhone and iPad.
- Required semantics, labels, non-color state indicators, Dynamic Type layout, and adult exit are implemented and receive focused checks relevant to the changed flow.
- No known critical privacy, data-loss, timer, or accessibility defect remains.

Feature completion does not require rerunning and recording the entire manual release matrix after every intermediate pull request. A feature-specific manual check remains required when behavior cannot be meaningfully verified through automation.

### Beta ready

Before TestFlight use in real sessions, the complete shared test plan, full manual accessibility matrix, lifecycle and real-device checks, privacy and storage checks, asset provenance review, and regression across all three tools must pass. Deferring repeated exhaustive verification to this gate does not defer implementation of accessibility or privacy requirements.

## Current status

The universal Xcode foundation, adaptive navigation, design/accessibility tokens, protected local-store boundary, deterministic timer domain, accessible timer UI, and timer lifecycle/feedback closeout are implemented. Timer enhancements are frozen unless Gate A or a critical defect demonstrates a need. The remaining MVP work is organized as three delivery slices: First–Then, Token Board, and Beta Release.

## Lean delivery sequence

1. **Timer closeout:** OTK-012 is complete; run Gate A when participants are available and keep noncritical timer enhancements parked.
2. **First–Then slice:** complete OTK-020, OTK-021, and OTK-022 consecutively without unrelated infrastructure or polish work between them.
3. **Token Board slice:** complete OTK-030 and OTK-031 using the smallest concrete implementation that satisfies the journey. Direct local duplication is acceptable when an abstraction would delay the usable tool.
4. **Beta Release slice:** complete a trimmed OTK-040, then OTK-041 and OTK-042. Settings include only controls and disclosures required by shipped behavior; no theme system or general settings framework is required.

OTK-032 is deferred until after Gate B. Reopen or reschedule it only if the completed First–Then and Token Board implementations reveal costly repeated behavior with a stable common shape.

## Milestone 0 — Foundation

Goal: create the smallest testable universal app and remove architectural uncertainty.

| Issue | Outcome | Depends on |
| --- | --- | --- |
| OTK-001 | Xcode project, app/unit/UI targets, shared scheme/test plan, pinned Xcode CI | none |
| OTK-002 | Minimal adaptive shell and typed routes on iPhone and iPad | OTK-001 |
| OTK-003 | Design tokens and accessibility test harness | OTK-001 |
| OTK-004 | Store/container harness, file protection, explicit no-CloudKit configuration, reset, backup exclusion, and Privacy Manifest review | OTK-001 |
| OTK-005 | Recruit five beta OTs and confirm three Gate A participants as parallel product validation | none |
| OTK-006 | Solo-maintainer governance for private GitHub Free: local main-push guard, manual green-CI/squash workflow, ownership, and reporting handoff | none |
| OTK-007 | Xcode 26.6 / iOS 26.5 authoritative CI with an Xcode 16.4 / iOS 18.5 compatibility lane | OTK-001 |

Exit gate:

- Debug and Release builds pass without new warnings.
- Unit and UI smoke tests run through the shared test plan.
- CI runs on the pinned toolchain.
- The app launches on iPhone and full/compact iPad layouts.
- No networking, CloudKit, analytics, authentication, or unapproved permissions are present.
- OTK-005 recruitment continues in parallel and does not block OTK-011 engineering completion; three participants must still be confirmed before Gate A validation begins.

## Milestone 1 — Visual Timer

| Issue | Outcome | Depends on |
| --- | --- | --- |
| OTK-010 | Pure timer domain and lifecycle tests implementing ADR-0002 | OTK-001 |
| OTK-011 | Accessible timer setup, running, paused, completed, and child-facing UI | OTK-002, OTK-003, OTK-010 |
| OTK-012 | Foreground sensory settings, idle-timer ownership, lifecycle-limit disclosure, and tester-acceptability check | OTK-011 |

After OTK-012, issue 37 and other noncritical timer enhancements remain outside the core-beta sequence.

Gate A:

- Three practicing pediatric OTs complete the scripted task in VALIDATION_PLAN.md.
- Median launch-to-running time is under 10 seconds.
- Foreground/background reconciliation, system-clock change, pause/resume, and exactly-once completion tests pass.
- No unresolved critical accessibility or lifecycle defect remains.

## Milestone 2 — First–Then Board

| Issue | Outcome | Depends on |
| --- | --- | --- |
| OTK-020 | First meaningful VersionedSchema V1 with board/item ordering, delete rules, and migration fixtures | OTK-004 |
| OTK-021 | Create, save, edit, complete First, and present Then | OTK-002, OTK-003, OTK-020 |
| OTK-022 | Child-facing presentation and reusable-board UI tests | OTK-021 |

The first slice uses bundled symbols. A photo-import ticket may be created only after ADR-0003 is amended and approved.

Exit gate:

- Create/edit/delete/reset and on-disk migration tests pass.
- The critical flow passes on iPhone and iPad.
- VoiceOver, largest Dynamic Type, Reduce Motion, and adult-exit checks pass.
- V1 becomes an immutable released schema when the first persistent TestFlight build is distributed.

## Milestone 3 — Token Board

| Issue | Outcome | Depends on |
| --- | --- | --- |
| OTK-030 | Token domain, goals, add/remove, reward, and completion tests | OTK-003 |
| OTK-031 | Saved templates and accessible child-facing token flow | OTK-020, OTK-030 |

OTK-032 is not part of this milestone's exit gate. It is deferred until after Gate B and requires evidence that extraction will reduce current maintenance cost.

Exit gate:

- Goals 3, 5, 8, and 10 behave deterministically.
- Completion is clear without color, motion, sound, or haptics alone.
- Celebrations are off by default and Reduce Motion-safe.

## Milestone 4 — Core private beta

| Issue | Outcome | Depends on |
| --- | --- | --- |
| OTK-040 | Essential shipped-behavior settings, idempotent reset, inactive-screen redaction, privacy copy, and support guidance | Milestones 1–3 |
| OTK-041 | Pre-beta privacy policy/reporting channel, asset provenance, signing/App Store Connect setup, Privacy Manifest verification, TestFlight metadata, and manual beta protocol | OTK-040 |
| OTK-042 | Resolve beta defects and record Gate B decision | OTK-041 |

Gate B:

- Five OTs test; three use the app in multiple real sessions; two affirm continued-use intent after the standardized question.
- Testers report at least two verified workflow replacements.
- Zero unresolved critical privacy, data-loss, accessibility, or timer defects.
- Versioned-store migration from the earliest beta fixture passes.
- The decision addresses acceptability of no active-timer restoration after process loss and no board transfer through device backup.
- A written go/no-go decision is recorded without patient data.

## Milestone 5 — Candidate App Store v1

| Issue | Outcome | Depends on |
| --- | --- | --- |
| OTK-050 | Choice Board vertical slice using proven board patterns | Gate B |
| OTK-060 | Name clinical owner and approve a bounded card inventory, category coverage, assets, content schema, and workflow | Gate B |
| OTK-061 | Regulation library, filters, favorites, safe filtered selection | OTK-060 |
| OTK-062 | Run Gate C usability, safety-note comprehension, and core regression | OTK-050 and OTK-061 |
| OTK-070 | Revalidate privacy policy/labels, asset licenses, accessibility matrix, and release build | OTK-062, or an explicit scope reduction |

Regulation Cards move to v1.1 if the content gate is not met. Core release stability takes priority over feature count.

Gate C:

- Three OTs complete scripted tasks for every post-Gate-B feature.
- Regulation safety notes are found and understood before use.
- Core regression, migration, accessibility, and content-validation checks pass.
- Zero confirmed critical defects remain unresolved.

## Definition of ready

An issue is ready only when it has:

- User outcome and bounded scope.
- Dependencies and explicit out-of-scope behavior.
- Given/When/Then acceptance criteria.
- Domain states and transitions where applicable.
- Persistence, migration, deletion, permission, and data-classification impact.
- Accessibility behavior and device/layout matrix.
- Unit, UI, manual, and failure-case test expectations.
- Linked ADR or an explicit statement that no decision change is needed.

## Definition of done

- Use the **Feature complete** evidence level for intermediate feature delivery and the **Beta ready** evidence level before TestFlight use in real sessions.
- Acceptance criteria are demonstrated.
- Focused tests pass; critical flows include iPhone and iPad coverage.
- Formatting/linting configured by OTK-001 passes.
- Debug and Release builds add no warnings.
- Persistence changes include versioned migration and real-store fixtures.
- Relevant automated and feature-specific manual accessibility checks are recorded during implementation; the full VoiceOver, largest Dynamic Type, Reduce Motion, Increase Contrast, Differentiate Without Color, Reduce Transparency, Switch Control, and keyboard matrix is recorded at the beta gate.
- Privacy/content/permission documentation matches behavior.
- No real child or patient data appears in source, fixtures, issues, logs, or artifacts.
- Remaining manual checks and risks are listed in the pull request.

## GitHub setup

Recommended milestones mirror sections 0–5. Recommended labels:

- enhancement, bug, chore, decision
- priority: critical, priority: high, priority: normal
- area: timer, area: boards, area: persistence, area: accessibility, area: privacy, area: content
- status: blocked, status: needs-validation

A GitHub Project may show Status, Priority, Area, Risk, and Milestone.

The repository remains private on GitHub Free. That plan does not provide server-enforced protected branches or rulesets for a private repository, so OTK-006 records the limitation and uses compensating solo-maintainer controls instead of blocking delivery:

1. Inspect any existing hook path, then run `git config --local core.hooksPath .githooks` in every compatible clone so the versioned pre-push hook rejects any update or deletion targeting remote `main`.
2. Work only on `codex/otk-XXX-short-description` branches and open a pull request for every change.
3. Wait for all available CI checks to pass, inspect the final diff, and squash-merge through GitHub.
4. Keep squash-only merging and automatic merged-branch deletion enabled; keep CODEOWNERS, issue/PR templates, milestones, Dependabot alerts, and automated security updates maintained.

The local hook prevents accidents but is not a security boundary and can be bypassed with `--no-verify`. Server-enforced branch rules remain out of scope while the repository is both private and on GitHub Free. OTK-001 replaces the planning workflow with pinned Xcode CI. The pre-beta security path is the detail-free collaborator fallback in SECURITY.md; OTK-041 owns a monitored direct fallback before TestFlight. Secret scanning and push protection should remain enabled when GitHub makes them available to the repository.

## Principal risks

| Risk | Mitigation or gate |
| --- | --- |
| Timer suspension/clock behavior surprises users | ADR-0002 and Gate A |
| Free text or photos contain sensitive data | Generic defaults, ADR-0003, photo feature gate |
| SwiftData beta data becomes an accidental schema contract | Versioned V1 before first persistent beta |
| Child mode traps or excludes users | Visible adult control and assistive-technology matrix |
| Regulation content creates clinical/safety exposure | Named clinical owner and CONTENT_GOVERNANCE.md |
| Building all five tools delays evidence | Gate Choice/Regulation work behind core beta |
