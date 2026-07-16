# ADR-0004: Supported build and compatibility toolchains

- Status: Accepted
- Date: 2026-07-16

## Context

ADR-0001 pinned macOS 15, Xcode 16.4, and iOS 18.5 until an explicit toolchain update. Apple now requires App Store Connect uploads to use Xcode 26 or later and an iOS/iPadOS 26 SDK or later. The original lane remains useful because the product still supports iOS and iPadOS 18.0, while the current submission toolchain's GitHub runner does not include an iOS 18 simulator runtime.

GitHub's macOS 26 runner is generally available and includes Xcode 26.6 plus iOS 26.5 simulator destinations. Its default Xcode may change independently, so CI must continue selecting and verifying the exact developer directory.

## Decision

- The authoritative CI lane uses the GitHub `macos-26` runner, Xcode 26.6, the iOS 26.5 SDK and simulator runtime, iPhone 17, and iPad (A16).
- The compatibility CI lane uses the GitHub `macos-15` runner, Xcode 16.4, the iOS 18.5 SDK and simulator runtime, iPhone 16, and iPad (10th generation).
- Both lanes run the same strict lint, project/privacy verification, unsigned Debug and Release builds, shared iPhone test plan, and critical iPad UI tests.
- The deployment target remains iOS and iPadOS 18.0. Building with the iOS 26.5 SDK does not authorize use of APIs unavailable on that deployment target without availability handling.
- CI pins and verifies the macOS major version, exact Xcode version, simulator SDK version, and named destinations before building.
- Beta and release-candidate Xcode or iOS versions are out of scope for authoritative CI.
- A future deployment-target or toolchain change requires another explicit issue, ADR update, matching CI changes, and successful validation in every retained lane.

## Consequences

TestFlight and App Store builds can be validated against Apple's current submission requirements without silently dropping iOS 18 support. New Swift compiler and SDK diagnostics become visible in the authoritative lane, while the compatibility lane catches behavior that only fails on the supported iOS 18 generation.

Running the full workflow twice increases macOS CI time and cost. Exact runner paths and simulator device names may change, so a runner-image update can require a bounded maintenance change even when application code is unchanged.

## References

- [Apple Xcode support](https://developer.apple.com/support/xcode/)
- [Apple SDK minimum requirements](https://developer.apple.com/news/upcoming-requirements/)
- [GitHub macOS 26 runner image](https://github.com/actions/runner-images/blob/main/images/macos/macos-26-Readme.md)
- [GitHub macOS 15 runner image](https://github.com/actions/runner-images/blob/main/images/macos/macos-15-arm64-Readme.md)
- GitHub issue #29 (OTK-007)
