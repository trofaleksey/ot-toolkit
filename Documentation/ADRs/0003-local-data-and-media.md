# ADR-0003: Local data and media boundary

- Status: Accepted
- Date: 2026-07-15

## Context

The product avoids formal patient records, but arbitrary labels and photos can still be sensitive. The original plan allowed photos without defining metadata removal, file protection, backups, or deletion. User-created Regulation Cards also expanded persistence without a product requirement.

## Decision

### Core private beta

- Use bundled illustrations and SF Symbols; do not import photos and do not request camera/library permission.
- Do not provide patient-profile or dedicated PHI fields.
- Treat board names and labels as potentially sensitive and recommend generic content.
- Use AppStorage for simple device preferences.
- Establish SwiftData VersionedSchema V1 with the first real persisted board model and freeze it when the first persistent TestFlight build is distributed.
- Store application content in an app-controlled Application Support directory using FileProtectionType.complete for the directory, SQLite store, WAL/SHM sidecars, and future media.
- Exclude the app-created content directory from device and iCloud backups and disclose the no-transfer consequence.
- Configure every SwiftData ModelConfiguration with cloudKitDatabase .none and verify CloudKit entitlements are absent.
- Cover board labels and child-facing content before inactive app-switcher snapshots are captured.
- Reset tears down the live container/contexts, removes the persistent store, sidecars, app-owned files, caches, and temporary content, clears all app-owned AppStorage/UserDefaults keys, then recreates and validates the protected backup-excluded store.
- User-created Regulation Cards are out of v1.

### Conditional photo import

Photo import needs a separate issue and amendment to this ADR. Approval requires:

- System picker with least-privilege access.
- Re-encoding, metadata stripping, downsampling, and bounded decoded memory.
- Opaque identifiers with app-owned files rather than external paths or SwiftData image blobs.
- File protection, backup exclusion, deletion, orphan cleanup, and reset tests.
- Inactive-screen redaction and sanitized logs/artifacts.
- Accurate permission copy, Privacy Manifest, App Store disclosure, and public privacy policy.

## Consequences

The early product is safer and faster to build but cannot use personalized child photos. Saved boards do not migrate through device backups. These constraints are explicit rather than accidental and can be revisited after core value is validated.
