# Product

## Overview

OT Toolkit is a native iPhone and iPad application for pediatric occupational therapists. It provides fast, configurable visual and regulation supports for use during sessions with children from preschool through middle school (approximately ages 4–13).

The app is a calm, reliable toolkit rather than a practice-management or medical-record system. It is intended to replace a small set of laminated boards, physical timers, printouts, and unrelated apps while remaining fully useful offline.

## Target user

Primary persona:

- School-based and clinic-based pediatric occupational therapists.
- Therapists supporting attention, regulation, transitions, fine-motor tasks, and classroom participation.
- Therapists who need to configure or change a support without disengaging from a child.

Parents, caregivers, educators, aides, speech therapists, and physical therapists may benefit, but they do not drive private-beta decisions.

## Jobs to be done

The therapist needs to:

- Start a timer without configuring an entire session.
- Show a child what happens first and next.
- Reinforce completed tasks through a token system.
- Provide clear visual choices for activities, breaks, and rewards.
- Find movement or regulation activities within therapist-selected constraints.
- Save reusable boards and routines.
- Modify a tool while actively working with a child.
- Use the app reliably without internet access.

## Staged scope

### Core private beta

The smallest useful product contains:

1. Visual Timer
   - Preset and custom durations.
   - Clear numerical and original spatial representation of remaining time.
   - Optional foreground sound and haptic completion feedback.
   - Child-facing full-screen mode.
   - Screen stays awake only while the timer is running in the foreground.

2. First–Then Board
   - Bundled illustrations or SF Symbols with short labels for First and Then.
   - Mark First as completed and transition to Then.
   - Reusable boards and child-facing mode.
   - User photo import is gated by the media/privacy decision and is not part of the first vertical slice.

3. Token Board
   - Goals of 3, 5, 8, or 10.
   - Tap-to-add and remove tokens.
   - Reward label or bundled symbol selection.
   - Optional calm completion feedback, off by default.
   - Saved templates.

Supporting capabilities:

   - Adaptive iPhone and iPad navigation.
   - Sensory and appearance settings.
   - Complete reset of app-created data.

### Candidate App Store v1

After the core beta passes its validation gate:

4. Choice Board
   - Two to six choices.
   - Bundled symbols or illustrations; user photos only after the media/privacy gate.
   - Reordering, temporary hiding, clear selection, save, and duplicate.

5. Movement and Regulation Cards
   - Curated, bundled activity library.
   - Name, illustration, directions, duration, environment, equipment, regulation category, supervision, contraindications, stop criteria, and safety notes.
   - Filters, favorites, and a Pick for Me action limited to the therapist's active filters.
   - Content approved through the process in CONTENT_GOVERNANCE.md.

If Choice Board or Regulation Cards do not satisfy their gates, they move to v1.1 rather than delaying a stable core release. User-created regulation cards are out of scope for v1.

## Non-goals for v1

- Formal patient records, profiles, diagnoses, SOAP notes, or medical documentation.
- Insurance billing or claims.
- Audio/video recording or session transcription.
- AI-generated treatment plans or automated clinical recommendations.
- Messaging, collaboration, shared workspaces, or multi-user accounts.
- Analytics, remote logging, authentication, or in-app networking.
- CloudKit or other app-managed sync.
- Export or sharing of boards.
- Subscriptions, accounts, Android, web, macOS, or desktop implementations.
- Non-English localization in v1; all user-facing strings remain externalized for later localization.

## Success criteria

Validation is manual and deidentified as defined in VALIDATION_PLAN.md.

### Gate A: Timer usability

- Three practicing pediatric OTs complete the scripted timer task.
- Median launch-to-running time is under 10 seconds.
- No unresolved critical timer lifecycle, accessibility, or data-loss defect remains.

### Gate B: Core private beta

- At least five practicing pediatric OTs test the core tools.
- At least three use the app in more than one real session.
- At least two affirm, after the standardized question, that they intend to continue using the app.
- Testers report that a core tool replaced an existing workaround in at least two workflows, and the replacement is verified in a deidentified follow-up.
- No confirmed critical sensory, privacy, persistence, accessibility, or timer defect remains unresolved.
- Testers explicitly evaluate whether non-restored active timers and no device-backup transfer are acceptable for release.

### Gate C: Candidate-v1 additions

- At least three practicing pediatric OTs complete scripted Choice Board and Regulation Cards tasks.
- All can find and understand the safety notes before starting an activity.
- The full core regression, accessibility matrix, content validation, and migration tests pass.
- No confirmed critical defect remains unresolved.
- If Gate C fails, the affected addition moves to v1.1 rather than delaying the stable core.

Willingness to pay is useful discovery input, not a release gate until a concrete pricing hypothesis exists.

## Privacy boundary

OT Toolkit does not require or provide dedicated fields for patient records or PHI. Free-text labels and future imported images can nevertheless contain identifying or sensitive information, so the app minimizes collection, recommends generic labels, and treats user-provided content as potentially sensitive.

The app itself does not transmit application content in v1. CloudKit, analytics, remote logging, and external APIs remain disabled. Backup, deletion, diagnostics, and future media handling are specified in PRIVACY.md and ADR-0003.

## Related plans

- ROADMAP.md defines delivery order and go/no-go gates.
- VALIDATION_PLAN.md defines beta measurement.
- CONTENT_GOVERNANCE.md defines the Regulation Cards release gate.
- ADRs record decisions that should not live in active GitHub tickets.
