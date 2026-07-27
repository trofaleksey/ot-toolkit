# OT Toolkit privacy policy

**Effective date:** to be set on the day this policy is published.
**Applies to:** OT Toolkit for iPhone and iPad, private beta and version 1.

This is the plain-language policy published for testers and App Store reviewers.
`Documentation/PRIVACY.md` remains the engineering specification; this document
must never describe behavior the app does not have. Update both together.

## The short version

OT Toolkit does not collect your data. Everything you create stays on your
iPhone or iPad. The app has no accounts, no analytics, no advertising, no
tracking, and makes no network requests of any kind. Nothing you type or choose
is ever sent to us, because there is nowhere for it to be sent.

## What the app stores on your device

When you use OT Toolkit, the app saves the following in its own protected
storage area on your device:

- First–Then boards: the board name, the two item labels you type, and the
  symbols you pick.
- Token Boards: the template name, the token goal, the reward label you type,
  and the reward symbol you pick.
- Your three sensory-feedback settings (Visual Timer sound, Visual Timer haptic,
  and Token Board haptic). All three are off unless you turn them on.

That is the complete list. The app has no field for a child's name, date of
birth, diagnosis, clinical notes, session history, insurance details, photos, or
audio. It does not record sessions, and it does not keep a history of the boards
you have run.

## What we receive

Nothing. We have no server, no database, and no way to see your content. The app
never transmits your boards, labels, settings, or usage anywhere.

Two things are outside our control and worth naming honestly:

- **Apple.** If you download the app through TestFlight or the App Store, Apple
  knows you installed it, in the same way it does for every app. If you have
  turned on sharing of crash and diagnostic data in your Apple settings, Apple
  may send us aggregated crash reports. The app writes no log messages at all,
  so a crash report cannot contain your board names or labels.
- **Your device backups.** The app's content directory is deliberately excluded
  from iPhone, iPad, and iCloud backups. This protects your content, and it also
  means your boards do not transfer to a new or restored device. This is
  intentional for version 1, and the app tells you so in Settings.

## A caution about what you type

The app gives you free-text fields for board and reward labels. It suggests
generic activity or routine names, and its examples are generic. But the app
cannot control what you type, so please treat those fields as if they were
sensitive: a child's first name, initials, or a nickname can still identify
them.

OT Toolkit is a support tool for your practice. It is not a patient-record
system, not a medical device, and we make no claim of HIPAA compliance. Your
own professional and employer obligations still apply to anything you enter.

## Children

OT Toolkit is designed for a therapist to use alongside a child, so a child will
often be looking at the screen and touching it. The app collects no information
about that child, shows no advertising, offers no in-app purchases, contains no
external links or messaging, and has no tracking of any kind. There is nothing
in the app for a child to sign up for or send.

## How the app protects what it stores

- Content is stored in an app-private directory that other apps cannot read.
- Files use the strongest iOS file protection setting, so they are encrypted and
  unreadable while the device is locked.
- When you switch apps, a neutral cover hides board content before iOS captures
  the app-switcher preview, so labels do not appear there.
- The app requests no permissions: no camera, photos, microphone, location,
  contacts, notifications, or health access.

## Deleting your data

You are always in control:

- Delete a single board from within the app at any time.
- Use **Settings → Reset app data** to erase everything the app has stored: all
  boards and templates, all settings, and the underlying database. It asks you
  to confirm first, then tells you whether it succeeded.
- Delete the app from your device. iOS removes its storage with it.

Because we never receive your data, there is nothing for you to ask us to
delete, and no data-export request we could meaningfully fulfill.

## Changes to this policy

Any future feature that would change what the app stores or transmits — photo
import, sharing, export, sync, or diagnostics — requires this policy to be
updated and republished before that feature ships. We will not add such a
feature quietly.

## Contact

Privacy questions and privacy or security concerns: **_[publish a monitored
address here before distributing the beta — see `SECURITY.md`]_**

Please do not include a child's name, photo, or any clinical detail in a message
to us. Describe the problem generically; we can work from that.
