# Contributing

## One-time checkout setup

Inspect the active hook path after each fresh clone:

```sh
git config --show-origin --get core.hooksPath
```

No output means no custom path is active. If the command names a custom or global hook directory you still need, preserve those hooks before changing the setting. Otherwise, enable and verify this repository's versioned hooks:

```sh
git config --local core.hooksPath .githooks
test "$(git config --local --get core.hooksPath)" = ".githooks"
test -x .githooks/pre-push
```

The pre-push hook rejects any update or deletion whose destination is the remote `main` branch. It protects against accidental direct pushes while this private repository is on GitHub Free. It is not a security boundary: hooks are local, must be enabled in every clone, can be bypassed with `git push --no-verify`, and do not govern GitHub web/API actions or clients that ignore hooks.

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

For every change to `main`:

1. Push only a `codex/otk-XXX-short-description` branch and open a pull request.
2. Wait for every available CI check to pass; GitHub Free cannot require those checks on this private repository.
3. Review the final diff and confirm no patient data, credentials, or unrelated files are present.
4. Squash-merge through GitHub, then allow GitHub to delete the merged branch.

Never push directly to `main`, force-push it, or delete it. These are maintainer rules even where GitHub cannot enforce them server-side.

## Validation

For documentation-only work, run the repository checks listed in the pull request. For app changes, run the formatter/linter configured by OTK-001 plus the relevant xcodebuild test command. Include iPhone and iPad UI coverage for critical flows and record manual assistive-technology checks.

## Sensitive reports

Do not open a public issue containing child/patient content, credentials, or exploitable security details. Follow SECURITY.md.
