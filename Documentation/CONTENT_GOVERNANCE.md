# Regulation content governance

## Status

Regulation Cards are gated candidate-v1 work. They do not begin until a named pediatric OT clinical-content owner accepts this process.

## Roles

- Clinical-content owner: approves scope, safety wording, and releases.
- Author: drafts activities from documented sources or professional consensus.
- Clinical reviewer: a pediatric OT other than the author checks appropriateness and clarity.
- Asset reviewer: verifies illustration and source rights.
- Engineer: validates schema, stable identifiers, and bundled-data tests.

One person may hold multiple roles except that an activity cannot receive final clinical approval solely from its author.

## Required activity fields

- Stable identifier and content version.
- Name and concise purpose.
- Step-by-step directions.
- Typical duration range.
- Environment and equipment.
- Regulation/movement category.
- Age or developmental considerations without diagnosis-based prescriptions.
- Supervision level.
- Contraindications and stop criteria.
- Safety notes.
- Source/provenance note.
- Author, reviewer, review date, and approval status.
- Illustration identifier and license/provenance.

Required fields are validated in tests. Draft or unapproved content is excluded from release bundles.

## Pick for Me

- It is a browsing convenience, not an individualized clinical recommendation.
- It selects only from activities remaining after the therapist applies environment, equipment, supervision, and other eligibility filters.
- It cannot determine patient-specific contraindications because the app stores no patient profile; individual suitability remains the therapist's decision.
- General contraindications and safety notes are always shown before the therapist starts an activity.
- Randomness is injectable so selection rules are deterministic in tests.

## Workflow

1. Draft content and record provenance.
2. Check language, equipment, environment, contraindications, stop criteria, and illustration rights.
3. Complete independent clinical review.
4. Mark approved with reviewer/date/version.
5. Run bundled JSON validation and UI safety-note checks.
6. Record a release-level clinical approval.

Changes to approved safety meaning increment the content version and require re-review. Editorial corrections still record a revision.

The clinical owner reviews the library at least annually and whenever a safety concern or material source change is reported. A withdrawal process removes unsafe content from the next build, records the affected stable IDs/versions and reason, evaluates whether beta users need direct notice, and blocks release until disposition is documented.

## Release gate

- Named owner and reviewer.
- OTK-060 defines and approves a bounded release inventory, required category coverage, and asset list before implementation is estimated or marked ready.
- No unapproved or duplicate stable IDs.
- Required safety fields complete.
- Pick for Me filter tests pass.
- Illustrations and sources have documented rights/provenance.
- Safety notes work with VoiceOver and largest Dynamic Type.
- Gate C confirms that therapists can find and understand the safety notes.
- Public copy states that activities are therapist-selected references, not medical advice.

If the gate cannot be met, Regulation Cards move to v1.1 without blocking the stable core app.
