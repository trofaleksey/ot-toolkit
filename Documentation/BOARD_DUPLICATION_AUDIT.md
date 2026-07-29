# Board duplication audit (OTK-032)

**Status: measurement only. No extraction is proposed for now — see the
recommendation.**

OTK-032 acceptance criterion 1 requires that "the issue documents measurable
current duplication before implementation begins." This is that measurement,
taken after three board features shipped rather than the two the roadmap
originally anticipated.

Measured on 2026-07-28 at `0ba73e6`, across First–Then (OTK-020/021/022/023),
Token Board (OTK-030/031), and Choice Board (OTK-050).

## Feature sizes

| Feature | Swift lines (app target) |
| --- | --- |
| First–Then | 2351 |
| Token Board | 1401 |
| Choice Board | 1584 |

## What is genuinely duplicated

### 1. `saveOrRollback` — byte-identical in all three stores

```swift
private func saveOrRollback() throws {
    do {
        try modelContext.save()
    } catch {
        modelContext.rollback()
        throw error
    }
}
```

8 lines × 3 = **24 lines, zero variation.** This is the single clearest
candidate in the codebase.

### 2. `reorder(...)` — 21 lines each, structurally identical

All three validate that the incoming id list is complete, duplicate-free, and
matches the stored set, then write `sortIndex` and stamp `updatedAt`. They
differ only in model type and which validation error they throw.

**63 lines across three copies.**

### 3. `next…SortIndex()` — identical shape

A descending `FetchDescriptor` with `fetchLimit = 1`, returning
`highest + 1` or `0`. Differs only in model type. Token names it
`nextTemplateSortIndex`; the other two use `nextBoardSortIndex`.

### 4. Controller CRUD — near-identical line for line

| Controller | reload | create | update | delete |
| --- | --- | --- | --- | --- |
| `FirstThenBoardController` | 13 | 10 | 15 | 15 |
| `TokenBoardController` | 13 | 10 | 15 | 15 |
| `ChoiceBoardController` | 13 | 9 | 14 | 14 |

Every one follows: look up the model by id, call the store, `reload()`, set a
`failure` case on throw. Roughly **160 lines** of the same five-line skeleton.

### 5. The failure enum

`FirstThenBoardOperation`, `TokenBoardTemplateOperation`, and
`ChoiceBoardOperation` are the same `load / create / update / delete` enum;
Choice adds `duplicate`.

## What is not duplicated, and should not be

- **Session/domain logic.** `FirstThenBoardSession`, `TokenBoardStateMachine`,
  `FirstThenScheduleSession`, and `ChoiceBoardSession` model genuinely different
  things: a two-step transition, a counter with a goal, an ordered walk across
  boards, and a single-select with hiding. Their only commonality is being value
  types with `@discardableResult` mutators.
- **Views.** The therapist screens differ in structure, and the child-facing
  screens differ more. `FirstThenBoardSequenceView` is already shared between
  the single-board journey and the schedule, which is the one place a real
  second consumer existed.
- **Validation rules.** Each store validates different constraints. The shared
  part is only "trim, then reject empty."

## Recommendation: extract `saveOrRollback` only, and not yet

The roadmap's bar is duplication "causing material maintenance cost," and
explicitly says a second consumer alone does not justify extraction. Measured
against that bar:

- **`saveOrRollback` (24 lines) meets it on identity but not on cost.** It has
  never changed since OTK-020 and has no plausible reason to. Extracting it
  saves 16 lines and buys nothing.
- **`reorder` and the CRUD skeleton look like the big win (~220 lines) but are
  not.** Making them shared requires a protocol over "a SwiftData model with
  `id`, `sortIndex`, and `updatedAt`" plus an associated error type. That
  generic machinery would plausibly cost more lines than it removes, and it
  would couple three features that currently change independently — the exact
  "speculative shared-board component" the core-beta target excludes.
- **No maintenance pain has actually materialised.** Across OTK-023, OTK-050,
  and the OTK-041 privacy work, no change had to be applied three times to these
  stores. The one place repetition *did* bite was the UI-test scroll helpers,
  which had drifted into three divergent versions — and that was consolidated
  separately because the copies had genuinely diverged and were carrying bugs.

**Proposed disposition: keep OTK-032 closed/deferred.** Revisit only if a future
change requires editing the same store or controller logic in all three
features, which is the concrete trigger the roadmap asks for. This document is
the baseline to compare against when that happens.

## If it is picked up anyway

Extract in this order, smallest risk first:

1. `saveOrRollback` as a small `ModelContext` extension. No generics needed.
2. `next…SortIndex` as a generic helper over `PersistentModel & Sortable`.
3. Stop there. `reorder` and the controller skeleton are where the abstraction
   starts costing more than it saves.

Do not extract the views, the session types, or the validation rules.
