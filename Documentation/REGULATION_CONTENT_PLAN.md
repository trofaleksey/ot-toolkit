# Regulation Cards content plan (OTK-060) — DRAFT FOR APPROVAL

**Status: draft. Not approved. No implementation may begin from this document.**

This is a proposal prepared for the clinical-content owner to review, amend, and
approve. It fills in the mechanical parts of OTK-060 — schema, identifiers,
validation, and a proposed inventory shape — so the decision is a review rather
than a blank page. Every clinical judgement in it is a placeholder.

`Documentation/CONTENT_GOVERNANCE.md` is the governing process and wins on any
conflict. Nothing here changes it.

## 1. Roles — owner to fill in

OTK-060 cannot be approved until these are real, named people. An activity
cannot receive final clinical approval solely from its author.

| Role | Person | Notes |
| --- | --- | --- |
| Clinical-content owner | _to be named_ | Pediatric OT. Approves scope, safety wording, releases. Must accept `CONTENT_GOVERNANCE.md` before work starts. |
| Author(s) | _to be named_ | Drafts activities from documented sources or professional consensus. |
| Clinical reviewer | _to be named_ | Pediatric OT other than the author. |
| Asset reviewer | _to be named_ | Verifies illustration and source rights. |
| Engineer | repository maintainer | Schema, stable IDs, bundled-data tests. |

**Until the clinical-content owner is named and has accepted the process, this
plan stays in draft and OTK-061 stays out of Ready.**

## 2. Proposed content schema

One JSON file bundled read-only. Every field below is required unless marked
optional; the validation in section 5 fails the build when any is missing.

| Field | Type | Notes |
| --- | --- | --- |
| `id` | string | Stable identifier, `reg-<category>-<slug>`. Never reused or renumbered. |
| `contentVersion` | integer | Starts at 1. Increments on any change to safety meaning. |
| `name` | string | Short activity name. |
| `purpose` | string | One or two sentences. |
| `directions` | array of strings | Ordered steps. |
| `durationMinutes` | object | `{ "min": int, "max": int }`, typical range. |
| `environment` | array of enum | See section 3. |
| `equipment` | array of strings | Empty array means none required. |
| `category` | enum | See section 3. |
| `developmentalConsiderations` | string | Developmental, never diagnosis-based prescription. |
| `supervisionLevel` | enum | `withinArmsReach`, `continuousVisual`, `intermittent`. |
| `contraindications` | array of strings | General only. Never patient-specific. |
| `stopCriteria` | array of strings | Observable signals to stop. |
| `safetyNotes` | array of strings | Shown before the activity starts. |
| `source` | object | `{ "citation": string, "url": string? }` provenance note. |
| `author` | string | Role reference, not a patient-identifying name. |
| `reviewer` | string | Must differ from `author`. |
| `reviewDate` | string | ISO 8601 date. |
| `approvalStatus` | enum | `draft`, `inReview`, `approved`. Only `approved` ships. |
| `illustration` | object | `{ "assetId": string, "license": string, "provenance": string }`. |

Nothing in this schema stores or references child, patient, or session data,
consistent with `PRIVACY.md`.

## 3. Proposed enumerations — owner to confirm clinical accuracy

**Category** — the axis a therapist filters on. Proposed set, to be confirmed:
`heavyWork`, `movement`, `breathing`, `quietFocus`, `oralMotor`, `tactile`.

**Environment**: `clinic`, `classroom`, `home`, `outdoor`, `smallSpace`.

**Supervision level**: `withinArmsReach`, `continuousVisual`, `intermittent`.

These names are engineering placeholders. The owner should replace them with the
terms they would actually use with a colleague — they become filter labels a
therapist reads under time pressure.

## 4. Proposed inventory shape — owner to set the real numbers

A bounded inventory is what makes OTK-061 estimable. Proposed shape for a first
release, deliberately small:

| Category | Proposed cards | Rationale |
| --- | --- | --- |
| `heavyWork` | 5 | Most frequently requested in the persona notes in PRODUCT.md. |
| `movement` | 5 | Broad applicability across environments. |
| `breathing` | 3 | Small set; wording carries the most safety weight. |
| `quietFocus` | 3 | Complements transitions already served by the timer. |
| `oralMotor` | 2 | Highest contraindication burden; smallest set. |
| `tactile` | 2 | Equipment-dependent. |
| **Total** | **20** | |

Twenty is a proposal, not a recommendation — the owner sets the real count. The
engineering point is only that the number must be **fixed before implementation
starts**, because "a library of activities" is not estimable and invites scope
drift.

Illustrations: 20 cards implies up to 20 assets. Each needs an entry in
`Documentation/ASSET_PROVENANCE.md` with license and provenance before it ships,
enforced by the existing `Scripts/verify_asset_provenance.sh` guard.

## 5. How "unapproved content cannot enter the release bundle" gets enforced

OTK-060 acceptance criterion 3 needs a mechanism, not a promise. Proposed, to be
built as the first task of OTK-061:

1. A bundled-JSON validation test that fails when any required field in section
   2 is missing or empty.
2. A test asserting every shipped card has `approvalStatus == "approved"`. Draft
   and in-review cards fail the build rather than being filtered at runtime.
3. A test asserting `id` values are unique and stable — a removed id may not be
   reused by a different activity.
4. A test asserting `reviewer != author` for every card.
5. A CI check that every `illustration.assetId` appears in the provenance
   ledger, extending the existing guard.

These are the same shape as the invariants added in OTK-041: the claim is
enforced by a failing build, not by review discipline.

## 6. Withdrawal and review — owner to confirm

Per `CONTENT_GOVERNANCE.md`, unchanged and restated here for the approval
record:

- The clinical owner reviews the library at least annually, and whenever a
  safety concern or material source change is reported.
- Withdrawal removes unsafe content from the next build, records affected stable
  ids and versions with a reason, evaluates whether beta users need direct
  notice, and blocks release until disposition is documented.
- Changes to approved safety meaning increment `contentVersion` and require
  re-review. Editorial corrections still record a revision.

## 7. What approval of this document means

Approving means the owner has: named the roles in section 1, confirmed or
replaced the enumerations in section 3, set the inventory numbers in section 4,
and accepted the enforcement in section 5. At that point OTK-061 becomes
estimable and may enter Ready.

Approving does **not** approve any individual activity. Each card still goes
through the per-activity workflow in `CONTENT_GOVERNANCE.md`.

## 8. Open questions for the owner

1. Is `oralMotor` in scope for a first release at all, given it carries the
   highest contraindication burden? Dropping it is a legitimate answer.
2. Should `supervisionLevel` be a single value, or can an activity's supervision
   requirement vary by environment?
3. Should equipment be a free-text list or a controlled vocabulary? Controlled
   is filterable; free text is faster to author.
4. Is a citation required for every card, or is documented professional
   consensus sufficient for some — and if so, how is that recorded?
