# Beta release readiness

OTK-041 owns this document. It records what must be true before a TestFlight
build is used in a real therapy session, who verified each item, and what is
still owed. Gate B (OTK-042) reads from it.

Nothing here may contain child, patient, or participant-level information.

## 1. Distribution setup

These require the maintainer's Apple Developer account and cannot be completed
from the repository. Record the date and outcome inline as each is done.

| Item | Value or status |
| --- | --- |
| Apple Developer team | _owner to record_ |
| Bundle identifier | `com.trofaleksey.ottoolkit` (set in the project; do not change after first upload) |
| Marketing version / build | `1.0` / `1` (in the project; increment build per upload) |
| App Store Connect app record | _owner to create_ |
| Signing | Automatic; a distribution certificate and provisioning profile are needed only for upload. CI builds stay unsigned with `CODE_SIGNING_ALLOWED=NO`. |
| Export compliance | Answered in the build: `ITSAppUsesNonExemptEncryption = NO`. The app uses only iOS file protection, which is exempt. No per-upload prompt should appear; if one does, stop and re-verify the setting. |
| Support contact shown to testers | _owner to record; must match `SECURITY.md`_ |
| Privacy policy URL | _owner to publish `Documentation/PRIVACY_POLICY.md` and record the URL_ |
| Beta app review information | Not required for internal testers; required if external TestFlight testing is used |

### TestFlight "What to Test" text

Use this text, which matches shipped behavior:

> This build contains four tools: Visual Timer, First–Then Board, Token Board,
> and Choice Board. The core-beta study focuses on the first three; Choice Board
> is an early candidate-v1 addition. Please use the core tools in real sessions
> where that is appropriate for your setting and your employer's policy.
>
> Known limits in this build, all intentional:
> • A running timer ends if the app is force-quit or the system reclaims it.
>   There is no background or lock-screen alert.
> • Saved boards stay on one device. They are excluded from backups and will
>   not transfer to a new or restored device.
> • Sound and haptic feedback are off until you turn them on in Settings.
>
> Please use generic activity or routine labels. Do not enter a child's name,
> initials, or nickname, and do not send us screenshots containing them.

## 2. App Store privacy answers

Derived from the implemented data flow, not from intent.

**Answer: "No, we do not collect data from this app."**

Apple defines collection as transmitting data off the device. OT Toolkit makes
no network requests, so no data type is collected, linked to identity, or used
for tracking. Board content, labels, and preferences are stored on device only
and are therefore out of scope for the questionnaire.

If any future feature transmits anything, this answer becomes wrong and must be
redone before that feature ships.

## 3. Privacy manifest verification

Re-audited against the code on 2026-07-27 for this gate.

| Declaration | Verified against |
| --- | --- |
| `NSPrivacyTracking` = false | No tracking, advertising, or attribution code exists |
| `NSPrivacyTrackingDomains` = empty | No network requests at all |
| `NSPrivacyCollectedDataTypes` = empty | Nothing is transmitted off device |
| `NSPrivacyAccessedAPICategoryUserDefaults`, reason `CA92.1` | `OTPreferences` and `AppOwnedPreferences` read, clear, and restore only this app's own preferences |

Required-reason categories deliberately **not** declared, each confirmed absent
from the code:

- File timestamp: the persistence layer sets file protection and backup
  exclusion but never reads creation or modification dates.
- Disk space: no free-space or capacity query.
- System boot time: `ProcessInfo` is used only for launch arguments.
- Active keyboard: no keyboard enumeration.

Repeat this audit whenever the persistence or platform API surface changes.

## 4. Enforced in CI

These are asserted on every pull request, so they do not need manual re-checking
per build:

- The privacy manifest is present, valid, bundled into the built app, declares
  no tracking, and declares no collected data types.
- No entitlements file, no `com.apple.developer.*` capability, no
  `NS*UsageDescription` permission string, and no Swift package dependency.
- No networking API (`URLSession`, `Network`, `WKWebView`, and similar) appears
  in the app target.
- No logging API (`print`, `NSLog`, `os_log`, `Logger`) appears in the app
  target, which is how log sanitization is guaranteed rather than reviewed.
- Every SwiftData `ModelConfiguration` passes `cloudKitDatabase: .none`.
- Every shipped SF Symbol appears in `Documentation/ASSET_PROVENANCE.md`.

## 5. Real-device checks still owed

Automation cannot cover these. Run them on a physical iPhone **and** a physical
iPad against a Release build before any real-session use, and record the date
and result.

| Check | How | Result |
| --- | --- | --- |
| Backup exclusion | Create a board, take an encrypted local backup, confirm no OT Toolkit content directory is present | _owed_ |
| File protection while locked | With content saved, lock the device and confirm the store is unreadable to a file-inspection tool | _owed_ |
| Reset on device | Reset with real content present; confirm success, an empty valid store, and that a second reset also succeeds | _owed_ |
| App-switcher redaction | From each of the four shipped tools and from child-facing mode, switch apps and confirm the preview shows the neutral cover, not board labels | _owed_ |
| Log sanitization | Watch Console.app for the whole journey; confirm the app emits no message containing a board name or label | _owed_ |
| No network traffic | Run the full journey with the Xcode network report open; confirm zero connections | _owed_ |
| No permission prompts | Complete the full journey; confirm iOS never prompts for any permission | _owed_ |
| Timer lifecycle | Force-quit a running timer and relaunch; confirm no timer is restored and the disclosure matches | _owed_ |
| Accessibility matrix | Full VoiceOver, largest Dynamic Type, Reduce Motion, Increase Contrast, Differentiate Without Color, Reduce Transparency, Switch Control, and keyboard pass across all four shipped tools | _owed_ |

## 6. Participant protocol

Before a tester receives a build:

1. Send the privacy policy URL and the limitations in the "What to Test" text.
2. Confirm the tester has checked their employer's policy on using a new tool in
   sessions, and any consent their setting requires.
3. Confirm the tester understands not to enter or send identifying content.
4. Give the tester the support contact for problems and the security contact for
   anything privacy-related.

Direct observation of a child session is not the default and requires the
organization's approval and all required consent. Tester self-report is the
normal channel. `Documentation/VALIDATION_PLAN.md` holds the task scripts and
the standardized questions.

## 7. Research-note handling

| Field | Value |
| --- | --- |
| Storage location | _owner to record: a specific access-controlled location outside GitHub_ |
| Owner | Product owner (repository maintainer) |
| Access list | Product owner only unless extended in writing |
| Contents allowed | Participant code, setting category, years-of-practice band, device class, test week, deidentified observations |
| Contents forbidden | Child names, diagnoses, photos, session screenshots, board labels, free-text case detail |
| Deletion | Within 30 days of the applicable gate decision |
| Deletion date | _owner to record once Gate B is decided_ |

Only aggregate themes and the gate decision go into GitHub.

## 8. Blocking items for the owner

The engineering and documentation work for OTK-041 is complete. These four
require the maintainer and block distribution:

1. Publish the privacy policy and record its URL here and in App Store Connect.
2. Choose and record a monitored security/privacy contact address, then remove
   the placeholder in `SECURITY.md` and `Documentation/PRIVACY_POLICY.md`.
3. Complete the Apple Developer and App Store Connect setup in section 1.
4. Run and record the real-device checks in section 5.
