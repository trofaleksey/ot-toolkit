# Contributing

## Before starting

- Read AGENTS.md and the durable documentation it lists.
- Select a ready GitHub Issue, confirm its maintainer-assigned OTK roadmap ID, and review linked ADRs and dependencies.
- Do not use real child or patient information in any development or project artifact.
- Create a branch named codex/otk-XXX-short-description.

## Change discipline

- Keep one primary outcome per pull request.
- Preserve feature-oriented source and mirrored test paths.
- Introduce shared abstractions only after multiple concrete consumers exist.
- Do not add dependencies, networking, analytics, CloudKit, authentication, export, or permissions without explicit approval and updated documentation.
- Never silently delete user data to recover from persistence errors.

## Pull requests

Complete the pull-request template with scope, decisions, data impact, accessibility impact, exact validation commands, and manual checks. Link the primary issue and any ADR. Draft pull requests are appropriate until all acceptance criteria and tests pass.

## Validation

For documentation-only work, run the repository checks listed in the pull request. For app changes, run the formatter/linter configured by OTK-001 plus the relevant xcodebuild test command. Include iPhone and iPad UI coverage for critical flows and record manual assistive-technology checks.

## Sensitive reports

Do not open a public issue containing child/patient content, credentials, or exploitable security details. Follow SECURITY.md.
