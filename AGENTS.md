# OT Toolkit engineering instructions

## Product

OT Toolkit is a native SwiftUI application for pediatric occupational therapists on iPhone and iPad. The core private beta contains Visual Timer, First–Then Board, and Token Board. PRODUCT.md and ROADMAP.md define later gated scope.

## Required reading

Before changing product code or durable plans, read:

1. Documentation/PRODUCT.md
2. Documentation/ARCHITECTURE.md
3. Documentation/DESIGN_SYSTEM.md
4. Documentation/PRIVACY.md
5. Documentation/ROADMAP.md
6. Any ADR and GitHub Issue relevant to the change

## Technical constraints

- Use Swift, SwiftUI, SwiftData, and Apple frameworks.
- Do not add a third-party dependency without explicit approval.
- Pin platform/toolchain behavior to ARCHITECTURE.md and update CI with any approved change.
- Use feature-oriented folders and mirrored test paths.
- Keep domain logic independent from SwiftUI where practical.
- Use injectable monotonic clocks and randomness for time/random-dependent code.
- Use a versioned SwiftData schema from V1; never ship an unversioned persistent model.
- Keep ModelContext access actor-safe.
- Avoid force unwraps, global mutable state, and speculative shared abstractions.
- Preserve offline functionality.
- Do not add analytics, networking, AI, authentication, CloudKit, export, or sharing in v1 unless explicitly approved.
- Do not add formal patient records or dedicated PHI fields.
- Treat arbitrary labels and any future media as potentially sensitive.
- Never put real child/patient data in source, fixtures, logs, screenshots, GitHub, or test artifacts.

## Interface requirements

- Support iPhone and iPad, including compact iPad layouts.
- Use adaptive typed navigation.
- Keep iPhone landscape functional even when portrait is prioritized.
- Support Dynamic Type, VoiceOver, Switch Control, and keyboard input where applicable.
- Respect Reduce Motion, Increase Contrast, Differentiate Without Color, and Reduce Transparency.
- Do not communicate state through color, sound, motion, or haptics alone.
- Keep child-facing views calm and low in sensory clutter.
- Provide a visible, accessible adult-exit control in child-facing mode.
- Use the design-system tokens and patterns in DESIGN_SYSTEM.md.

## Testing

- Add pure unit tests for domain logic in each feature.
- Add in-memory and on-disk migration tests for persistence changes.
- Add UI tests for critical journeys on iPhone and iPad.
- Use deterministic UI-test launch arguments and synthetic fixtures.
- Run the relevant shared test plan with xcodebuild before reporting product-code completion.
- Run the configured formatting/lint command from OTK-001.
- Do not delete, skip, or weaken a test merely to make a build pass.
- Record manual accessibility, lifecycle, permission, and real-device checks that automation cannot cover.

## Workflow

Before editing:

1. Inspect the GitHub Issue, linked ADRs, relevant implementation, and tests.
2. State the files expected to change.
3. Identify ambiguity or architectural, privacy, accessibility, clinical-content, and migration risk.
4. Stop for a decision if the work would expand scope or contradict an accepted ADR.

After editing:

1. Run formatting/lint, build, and relevant tests locally.
2. Review the diff for unrelated changes and sensitive data.
3. Summarize implementation and changed files.
4. Report exact test commands and results.
5. List remaining risks and manual checks.

## GitHub Actions budget

GitHub-hosted CI is a final integration gate, not the development feedback loop. Preserve the required pinned lanes, but minimize workflow runs:

- Finish a coherent change and complete the required local validation before opening a pull request. Opening a draft pull request also starts CI, so use a draft before local validation only when early remote review is genuinely needed.
- Once a pull request exists, accumulate related fixups locally, rerun the affected local checks, and push the fixes together. Do not push each small edit separately.
- Diagnose failures from the existing logs before changing code or starting another run. Do not rerun a failed job without a code/configuration change unless the failure is demonstrably transient infrastructure trouble.
- Do not start `workflow_dispatch`, rerun individual jobs, or rerun all jobs without explicit maintainer approval.
- Do not push no-op commits or make whitespace-only edits solely to trigger CI.
- Never weaken, skip, or remove a required check to save Actions minutes. If the Actions allowance is exhausted, report the locally verified state and wait for the allowance or a maintainer decision before merging.

## Project management

GitHub Issues are the source of truth for active tickets, ownership, status, and acceptance criteria. ROADMAP.md defines sequence and gates; ADRs define durable decisions. Do not create a parallel Markdown ticket backlog. Maintainers allocate unique OTK roadmap IDs; GitHub issue numbers are separate and are used in pull-request closing keywords.

Use branches named codex/otk-XXX-short-description. Keep pull requests small enough to review and link one primary issue with Closes #<number>. Keep ordinary work local until it is coherent and locally validated; use a draft pull request earlier only when collaboration or an explicit review need justifies the CI run.

## Issue template

Each implementation issue includes:

# OTK-XXX: Outcome-focused title

## Context and user story

As a pediatric occupational therapist, I want ... so that ...

## Scope

- Required behavior and screens
- Required persistence
- Required accessibility
- Required failure and empty states

## Out of scope

- Explicit exclusions

## Dependencies and decisions

- Blocking issues
- Linked ADRs
- Assumptions that need confirmation

## Data and safety impact

- Data classification and storage
- Migration, deletion, backup, and reset
- Permissions or entitlements
- Clinical-content review, if applicable

## Acceptance criteria

1. Given ... When ... Then ...
2. Given ... When ... Then ...

## Testing

- Unit/domain cases
- Persistence/migration cases
- iPhone/iPad UI flows
- Accessibility matrix
- Manual lifecycle/permission/device checks

## Deliverable

- Summary
- Changed files
- Test commands/results
- Manual checks
- Risks/assumptions

## Prompt pattern

Use bounded prompts:

    Implement GitHub issue OTK-XXX.
    First inspect AGENTS.md, the durable documentation, linked ADRs,
    and the relevant feature/tests. Before editing, summarize the approach,
    states, transitions, data impact, and accessibility risks. Implement only
    the ticketed scope, add focused tests, and run the relevant shared test
    plan locally. Batch any fixups before pushing to an open pull request.
    Report changes, files, tests, manual validation, risks, and assumptions.

For reviews, inspect the diff without editing first. Report confirmed findings by severity with file and line references, then apply only approved/in-scope fixes and rerun relevant tests.

## Parallel work

Safe parallel tasks include one feature implementation, one read-only architecture review, one accessibility review, and non-overlapping tests. Do not let multiple agents concurrently edit the same Swift or project file.
