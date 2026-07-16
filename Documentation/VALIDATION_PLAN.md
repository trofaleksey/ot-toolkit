# Validation plan

## Purpose

Validate usefulness, speed, sensory fit, and reliability without in-app analytics or collecting patient information.

## Participants

- Recruit at least five practicing pediatric OTs in the primary persona.
- For Gate A, use the first three available participants.
- In raw research notes, record only a participant code, setting category, broad years-of-practice band, device class, and test week.
- Do not record child names, diagnoses, photos, session screenshots, or free-text case details.

## Gate A task

Starting from a cold app launch:

1. Ask the therapist to start a five-minute timer using any preset or custom path.
2. Start a stopwatch when the app becomes interactive.
3. Stop when the timer is visibly running.
4. Record elapsed seconds, wrong turns, help requested, and a short deidentified observation.
5. Repeat once only if a technical failure invalidated the attempt; retain both results and label the reason.

Pass when the median first valid attempt is under 10 seconds and no critical usability, lifecycle, sensory, or accessibility defect remains.

## Core beta tasks

- Start, pause, resume, and complete a timer.
- Create and present a First–Then board.
- Complete a Token Board and undo one token.
- Find and reset saved content.
- Use the participant's normal accessibility and appearance settings.

After each real-session use, ask:

- Which existing workaround did this replace, if any?
- What interrupted the therapist/child interaction?
- Was anything confusing, overly stimulating, inaccessible, or unsafe?
- Would the therapist choose to use it again next week? Why?
- Is it acceptable that a running timer is not restored after force-quit/process loss in the private beta?
- Is it acceptable that saved boards do not transfer through device backup?

For Gate C, ask at least three OTs to create/use a Choice Board, find a Regulation Card within stated constraints, locate and explain its safety notes, and complete the core regression tasks.

## Data handling

- The product owner stores coded raw observations in a separate access-controlled research location, not GitHub.
- Never attach session screenshots, board labels, photos, logs containing content, or child information.
- Put only aggregate themes and gate decisions in GitHub; do not paste participant-level notes or clinical narratives.
- Delete raw notes within 30 days after the applicable gate decision. Any extension requires a documented purpose, owner, access list, and deletion date outside GitHub.
- Participation and any session observation follow the tester's employer policies and applicable consent requirements.
- Do not directly observe a child session unless the therapist's organization has approved it and all required consent has been obtained; tester self-report is the default.

## Severity

- Critical: potential harm, privacy exposure, data loss, trapped child-facing mode, unusable primary flow, or materially incorrect timer.
- High: repeated failure or accessibility barrier with a workaround.
- Normal: limited friction or polish issue that does not block the session.

Critical findings block the gate. High findings require explicit disposition. Normal findings enter the prioritized backlog.

## Gate B decision

Record:

- Participant/use counts against the 5/3/2 thresholds.
- Median timer-start time.
- Tester-reported workflow replacements verified in deidentified follow-up.
- Critical/high defect status.
- Accessibility and sensory themes.
- Schema migration result.
- Acceptability of the timer-restoration and backup limitations.
- Go, conditional go, or no-go with reasons.

The decision contains only aggregate, deidentified information.

Gate C additionally records usability of each candidate-v1 feature, safety-note comprehension, core regression results, and the ship/defer decision for each addition.
