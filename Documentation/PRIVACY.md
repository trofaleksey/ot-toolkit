# Privacy

## Scope and claims

OT Toolkit is a local-first support tool, not a patient-record system. V1 does not require, solicit, or provide dedicated fields for formal patient records, diagnoses, clinical notes, or PHI.

Free-text labels and future imported images can still contain identifiable or sensitive information depending on what a therapist enters. The app therefore treats all user-provided board content as potentially sensitive. It does not claim that sensitive data can never be entered, and it does not claim HIPAA compliance.

## Data inventory

### App-created local content

- Saved First–Then, Token, and later Choice boards.
- Board names, short labels, stable identifiers, ordering, and configuration.
- Reward labels and saved templates.
- Favorite bundled-activity identifiers.
- Sensory and appearance preferences.

User-created regulation cards are not part of v1.

### Bundled content

- Read-only regulation activities and metadata.
- Bundled illustrations, symbols, sounds, and localizations.

Bundled content contains no patient-specific information and has documented provenance and review status.

### Conditional future media

The core private beta does not import photos or use the camera. Photo import cannot ship until ADR-0003 is amended and tests cover selection, re-encoding, metadata removal, protected storage, backup behavior, deletion, reset, cache cleanup, and permission denial.

### Explicitly excluded in v1

- Patient profile fields, date of birth, address, diagnosis, clinical history, SOAP notes, insurance data, and session transcripts.
- Audio or video recording.
- Authentication credentials for external services.
- Analytics events, third-party diagnostics, or remote logs.
- App-managed cloud sync, sharing, or export.

## Data minimization

- Default board names and examples are generic.
- The UI recommends generic activity or routine labels; initials and nicknames can still identify a child and are not presented as risk-free.
- No dedicated patient identifier field may be added.
- Test fixtures are synthetic.
- GitHub Issues, pull requests, screenshots, logs, crash attachments, and test artifacts must not contain real child or patient content.
- A neutral privacy cover obscures board labels and child-facing content whenever the scene becomes inactive, before the app-switcher snapshot is captured.

## Storage and backup

App-created domain content is stored in an app-controlled Application Support directory using SwiftData. Simple preferences use AppStorage. The content directory, SQLite store, WAL/SHM sidecars, and any future media use FileProtectionType.complete. Real-device tests verify locked/unlocked behavior and reapply the protection after directory recreation.

For v1, the app-created content directory is excluded from device and iCloud backups. The UI and support material disclose that boards do not transfer to a new or restored device. Backup behavior is tested on a real device before beta distribution.

The app itself makes no network requests and does not enable CloudKit. Operating-system services such as user-controlled device diagnostics or App Store crash reporting may transmit system-managed diagnostic information under the user's Apple settings; application logs must never include board names, labels, images, or activity selections.

## Deletion and reset

- Deleting a board removes its SwiftData graph according to explicit delete rules.
- Future media deletion must remove the app-owned original, derivatives, cache entries, and orphaned files.
- Reset app data first tears down the live ModelContainer/contexts, removes the database and write-ahead-log sidecars, clears all app-owned AppStorage/UserDefaults keys, removes app-owned media, thumbnails, caches, and temporary files, then recreates a protected, backup-excluded, empty valid store.
- Reset requires clear confirmation and reports success or a recoverable failure.
- Automated tests verify deletion and idempotent reset against a real on-disk store.

## Photos and camera

If photo import is approved after the core beta:

- Prefer PhotosPicker or its current system equivalent so broad library access is not required.
- Copy only the selected asset into app-owned storage.
- Re-encode and downsample it, remove metadata including location, and delete temporary input.
- Store a stable opaque file identifier in SwiftData, never an external photo-library path or a large image blob.
- Keep the app usable with bundled symbols when access is denied.
- Request camera permission only at the moment a separately approved camera feature is used.
- Provide accurate usage descriptions, Privacy Manifest entries when applicable, and App Store privacy declarations.

## Timer alerts and permissions

Private-beta timer completion feedback is foreground-only and does not request notification permission. Any future background alert requires a separate product/privacy decision, generic lock-screen text, opt-in permission handling, cancellation semantics, and an ADR update.

No microphone, location, HealthKit, contacts, or tracking permission is allowed in v1.

## Clinical-content boundary

Regulation Cards provide therapist-reviewed reference content, not individualized treatment recommendations. Pick for Me operates only within therapist-selected filters. CONTENT_GOVERNANCE.md defines the safety, provenance, and approval gate.

## Privacy manifest baseline

The OTK-001 bootstrap collects no data, performs no tracking, and directly uses no required-reason API. Its PrivacyInfo.xcprivacy declares `NSPrivacyTracking` as false and omits unused data-collection and accessed-API declarations. OTK-004 must re-audit the manifest when SwiftData, AppStorage/UserDefaults, file timestamps, or other persistence APIs are introduced; later tickets repeat the review whenever the implemented data flow or API surface changes.

## Public disclosures and release gate

Before TestFlight use with real sessions or App Store submission:

- Publish a plain-language privacy policy matching actual behavior.
- Complete App Store privacy answers from the implemented data flow.
- Verify every SwiftData ModelConfiguration explicitly uses cloudKitDatabase .none and that CloudKit/prohibited entitlements are absent.
- Verify backup exclusion, file protection, reset, inactive-screen redaction, and sanitized logs.
- Create and review PrivacyInfo.xcprivacy against the required-reason APIs actually used.
- Document how users report privacy or security concerns.

Any future sync, export, collaboration, analytics, diagnostics SDK, or media expansion requires an updated data-flow review, public privacy policy, and explicit approval before implementation.
