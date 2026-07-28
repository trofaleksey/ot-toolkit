# Asset provenance

## Purpose

This ledger records the origin and permitted use of visual, audio, and font assets shipped
with OT Toolkit. It must not contain patient information, child images, clinical notes, or
prompts derived from real sessions.

For each future asset, record its stable catalog name, type, creator or source, acquisition
date, license or retained terms, attribution requirement, modifications, repository source
path and SHA-256, accessibility and localization intent, reviewer and date, and the owning
issue or pull request. Generated assets also record the provider, model or tool version,
terms snapshot, and human trade-dress review.

## Current ledger

The semantic palette is original OT Toolkit project work created on 2026-07-16 for OTK-003.
It is project-owned, all rights reserved, requires no third-party attribution, and was created
as sRGB light, dark, light increased-contrast, and dark increased-contrast values. Each color
is reviewed by automated contrast tests as well as the manual accessibility release matrix.

| Stable asset | Type | Repository source and SHA-256 | Accessibility/localization intent |
| --- | --- | --- | --- |
| `OTBackground` | Original semantic color | `OTToolkit/Resources/Assets.xcassets/OTBackground.colorset/Contents.json` — `282e542dbc85918271d8dc9198a6cf2c79f55565607b9b62ff1ab77c5738a871` | Opaque app background; no label |
| `OTSurface` | Original semantic color | `OTToolkit/Resources/Assets.xcassets/OTSurface.colorset/Contents.json` — `507fa47d6ae7a60ec1a693083bc5de52106bbac3d8ae754b7739436c9ffa70e4` | Opaque grouped surface; no label |
| `OTElevatedSurface` | Original semantic color | `OTToolkit/Resources/Assets.xcassets/OTElevatedSurface.colorset/Contents.json` — `6f193654eb6cebcb318bef445b1b1a37cf9bc4580e77a6b20fd7f5f93c3a10da` | Opaque elevated surface; no label |
| `OTPrimaryText` | Original semantic color | `OTToolkit/Resources/Assets.xcassets/OTPrimaryText.colorset/Contents.json` — `6cb780d10873f7d051413c8fe026fe4df1a4cf6d4f0e00070ba98c679b5e3460` | Primary readable foreground; labels come from localized copy |
| `OTSecondaryText` | Original semantic color | `OTToolkit/Resources/Assets.xcassets/OTSecondaryText.colorset/Contents.json` — `7b5a7216ee1e9ffc6d75fc7eb35d478902f0f8c531a3477059e70d91b51623fa` | Secondary readable foreground; labels come from localized copy |
| `OTAccent` | Original semantic color | `OTToolkit/Resources/Assets.xcassets/OTAccent.colorset/Contents.json` — `5d69b4901595deba44c7990bcd512413ad5fdfc06282952eeb42716497afcacd` | Accent foreground only; never the sole state cue |
| `OTSelection` | Original semantic color | `OTToolkit/Resources/Assets.xcassets/OTSelection.colorset/Contents.json` — `7419ccb704d1c42d1f890f8416668ab220dc72f4f0a6cca51c62bbb7597092bf` | Selection surface paired with primary text and a non-color cue |
| `OTSuccess` | Original semantic color | `OTToolkit/Resources/Assets.xcassets/OTSuccess.colorset/Contents.json` — `ba4fb1655cdedff428a4fe40184341c0529a1c804f0d02bd58311cb9f04ae30c` | Success foreground paired with text or a symbol |
| `OTWarning` | Original semantic color | `OTToolkit/Resources/Assets.xcassets/OTWarning.colorset/Contents.json` — `df366728054826eacfd419ddcb48cb9c2335aa0013597fe1c9e70c9cf0c77a73` | Warning foreground paired with text or a symbol |
| `OTDestructive` | Original semantic color | `OTToolkit/Resources/Assets.xcassets/OTDestructive.colorset/Contents.json` — `09a910ba689feb20dbb8706ff5b8696a482dd131af53f9050f3836eb986dbf7b` | Destructive foreground paired with explicit localized copy |
| `OTSeparator` | Original semantic color | `OTToolkit/Resources/Assets.xcassets/OTSeparator.colorset/Contents.json` — `ea9cd7482a968661e2f63fdfbd216bbb830711260eb52b295a2d8d7bcea1b399` | Essential boundary color; no label |
| `OTFocus` | Original semantic color | `OTToolkit/Resources/Assets.xcassets/OTFocus.colorset/Contents.json` — `e39c5e3a74fc6b94ea47446e3afd3d9f3d955df54d039c017c83141c99d33174` | Focus foreground or outline paired with shape and platform focus behavior |
| `visualTimer.completionTone` | Original programmatic audio | `OTToolkit/Features/VisualTimer/Presentation/VisualTimerRuntimeCoordinator.swift` — `722ee857da4be58efc4b2ead96e5f330efc348792b3f9e5893a7fc88610e7c16` | Optional foreground-only completion cue, off by default; visible completed text, shape, and zero-time value remain the primary meaning |

## SF Symbols

Every symbol below is an unmodified Apple SF Symbol referenced by name. None is copied
into the repository, so a repository source path and SHA-256 do not apply. They are Apple
platform assets used under the applicable SDK terms, require no in-app attribution, and
carry no third-party license obligation. No symbol is the sole carrier of meaning: each
either accompanies localized text or is hidden from assistive technologies as decorative.

`Scripts/verify_asset_provenance.sh` fails the build when a shipped symbol is absent from
this section, which is how the ledger stays current as features land.

### Navigation and shell

| Stable asset | Accessibility/localization intent |
| --- | --- |
| `square.grid.2x2` | Reinforces the localized Tools navigation label; the text remains the primary meaning |
| `folder` | Reinforces the localized Saved navigation label; the text remains the primary meaning |
| `gearshape` | Reinforces the localized Settings navigation label; the text remains the primary meaning |
| `chevron.up` | Decorative affordance on the running-timer banner; hidden from assistive technologies |
| `rectangle.portrait.and.arrow.right` | Reinforces the localized adult-exit label; the visible text and confirmation provide the primary meaning |

### Tool identity

| Stable asset | Accessibility/localization intent |
| --- | --- |
| `timer` | Reinforces localized Visual Timer text; decorative instances are hidden from assistive technologies |
| `rectangle.split.2x1` | Reinforces localized First–Then text; decorative instances are hidden from assistive technologies |
| `circle.grid.2x2` | Reinforces localized Token Board text; decorative instances are hidden from assistive technologies |

### State and status

| Stable asset | Accessibility/localization intent |
| --- | --- |
| `play.circle.fill` | Paired with localized running-state text; never the sole running indicator |
| `pause.circle.fill` | Paired with localized paused-state text; never the sole paused indicator |
| `checkmark.circle.fill` | Paired with localized completed-state or selected-state text; never the sole completion cue |
| `circle` | Unselected counterpart to `checkmark.circle.fill`; selection is also stated in text |
| `1.circle.fill` | Marks the First position alongside localized role and state text |
| `2.circle` | Marks the Then position alongside localized role and state text |
| `star.fill` | Earned token; the filled/unfilled distinction is also reported as a localized count |
| `star` | Unearned token; the filled/unfilled distinction is also reported as a localized count |
| `exclamationmark.triangle` | Paired with localized persistence-recovery text; never the sole failure indicator |
| `exclamationmark.circle` | Paired with localized editor validation text; never the sole error indicator |
| `info.circle` | Paired with localized timer disclosure text; never the sole disclosure |

### Actions

| Stable asset | Accessibility/localization intent |
| --- | --- |
| `plus` | Labeled create action; the localized label carries the meaning |
| `pencil` | Labeled edit action; the localized label carries the meaning |
| `trash` | Labeled delete action; the localized label and confirmation carry the meaning |
| `play.fill` | Labeled start and resume actions; the localized label carries the meaning |
| `pause.fill` | Labeled pause action; the localized label carries the meaning |
| `arrow.counterclockwise` | Labeled reset and start-another actions; the localized label carries the meaning |
| `arrow.uturn.backward` | Labeled remove-token and previous-board actions; the localized label carries the meaning |
| `checkmark.circle` | Labeled complete-First action; the localized label carries the meaning |
| `arrow.right.circle.fill` | Labeled Then transition and next-board action; the localized label carries the meaning |
| `arrow.down` | Decorative First-to-Then flow indicator, and the labeled move-later control in schedule ordering; decorative instances are hidden from assistive technologies |
| `arrow.up` | Labeled move-earlier control in schedule ordering; the localized label carries the meaning |
| `minus.circle` | Labeled remove-from-schedule action; the localized label carries the meaning |
| `xmark.circle` | Labeled end-schedule action; the localized label carries the meaning |
| `list.bullet` | Labeled start-visual-schedule action; the localized label carries the meaning |
| `rectangle.inset.filled` | Labeled enter-child-facing action; the localized label carries the meaning |

### Settings disclosures

| Stable asset | Accessibility/localization intent |
| --- | --- |
| `externaldrive.badge.xmark` | Decorative mark on the no-backup-transfer disclosure; the disclosure text carries the meaning |
| `textformat` | Decorative mark on the generic-naming disclosure; the disclosure text carries the meaning |

### Bundled board content

Therapist-selectable activity and reward symbols. Each is chosen by the therapist and
always presented with the therapist's own localized label, so the symbol never identifies
a child or carries meaning on its own.

| Stable asset | Accessibility/localization intent |
| --- | --- |
| `figure.walk` | First–Then movement activity option |
| `tshirt` | First–Then dressing activity option |
| `book.closed` | First–Then reading activity and Token Board reading reward option |
| `paintbrush` | First–Then creative activity option |
| `fork.knife` | First–Then eating activity option |
| `puzzlepiece` | First–Then play activity and Token Board play reward option |
| `music.note` | Token Board music reward option |
| `carrot` | Token Board snack reward option |
| `figure.play` | Token Board outside-play reward option |

Engineering review date: 2026-07-16. Owning work item: GitHub issue OTK-003 (`#8`). The
engineering reviewer is the Codex OTK-003 implementation audit. This is the initial original
palette; it contains no modified third-party source material. SF Symbols referenced by OTK-002
are unchanged Apple platform assets under the applicable SDK terms and require no in-app
attribution. OTK-002 engineering review date: 2026-07-16.

OTK-041 re-reviewed the full shipped inventory on 2026-07-27 for the beta release gate. The
ledger had covered only the five symbols present at OTK-002 and had not been updated as
OTK-011, OTK-021, OTK-022, OTK-030, OTK-031, and OTK-040 shipped; the missing thirty-four
symbols are now recorded and `Scripts/verify_asset_provenance.sh` runs in CI so the gap
cannot reopen silently. The beta ships no bitmap illustration, no bundled audio file, and no
custom font: the only non-symbol assets are the original semantic colors above and the
programmatically generated completion tone. Product owner rights confirmation remains a
release check.

The `visualTimer.completionTone` waveform is deterministic original OT Toolkit code created
on 2026-07-16 for OTK-012 (`#12`). It is a 220-millisecond, 659.25 Hz sine tone with a short
attack and release envelope, generated in memory at runtime. It has no external provider,
model, source recording, or third-party license; it is project-owned, all rights reserved,
and requires no attribution. Engineering review confirms that it is optional, calm, and not
used as the sole completion cue. Real-device sensory acceptability remains part of Gate B.
