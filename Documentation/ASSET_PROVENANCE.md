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
| `checkmark.circle.fill` | Referenced SF Symbol; not copied | Apple platform asset referenced by symbol name; repository source and hash not applicable | Decorative reinforcement for localized success text; hidden from assistive technologies |

Engineering review date: 2026-07-16. Owning work item: GitHub issue OTK-003 (`#8`). The
engineering reviewer is the Codex OTK-003 implementation audit. This is the initial original
palette; it contains no modified third-party source material. The SF Symbol is referenced
unchanged under the applicable Apple SDK terms and requires no in-app attribution. Product
owner rights confirmation remains a release check.
