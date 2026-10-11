# tara

A Claude Code plugin for mobile app work: Flutter, iOS/Swift, Android/Kotlin, React Native/Expo, and Kotlin Multiplatform. Install it once and use it on any project. The plugin holds only generic logic. Project specifics (stack, commands, conventions, protected files) are discovered by `/tara:init` and stored in the project under `docs/tara-knowledge/`.

The full design is in [SPEC.md](SPEC.md). Changes and deviations from the spec are in [CHANGELOG.md](CHANGELOG.md).

## Install

```sh
claude --plugin-dir /path/to/tara        # try it without installing
claude plugin validate /path/to/tara     # check the manifest
```

Run `/reload-plugins` after changing plugin files.

## Workflow

```
/tara:init                  detect stack → you confirm → writes docs/tara-knowledge/
/tara:plan <feature>        explore → phased plan → stops for your approval
/tara:execute               one phase at a time, analyze + tests after each, ticks the plan
/tara:test                  analyze + tests, fixes failures (max 3), proposes evidenced learnings
/tara:review                parallel reviewers on your diff → P1/P2/P3 + top 3 fixes
/tara:pr                    commit message + PR text → asks before commit, push, PR
```

Plans are files (`docs/tara-knowledge/plans/<slug>.md`) with checkboxes and status, so `/tara:execute` resumes after `/clear` or in a new session. Learnings (`learnings.md`) are saved only with evidence, and only after you say yes. The next `/tara:plan` cites the ones it applies.

## Commands

| Command | What it does | Gates |
|---|---|---|
| `init [path] [--refresh]` | Detects stack, state, UI, architecture, flavors, services, tests, tooling. Monorepos: asks which app(s). | Writes only after you confirm. `--refresh` shows a diff. |
| `plan <feature>` | Writes a plan with phases, files, and checkable acceptance criteria. | Stops for approval. |
| `execute [plan]` | Implements approved phases, verifies each one, records evidence in the plan. | Stops on failure. Never commits. |
| `test [plan]` | Diff-first tests. Up to 3 fix attempts (escalates to Opus). Manual checklist if there are no tests. | Asks before saving learnings. |
| `review [path\|--all]` | Runs perf, security, state, and UI reviewers in parallel and merges their findings. | Read-only. |
| `learn <lesson>` / `--prune` | Adds one evidenced lesson, or consolidates the file. | Asks for evidence; diff before pruning. |
| `build [android\|ios] [--flavor\|--scheme] [--release]` | Builds with the project's commands and explains failures. | Never touches signing. Asks before release builds and environment fixes. |
| `health` | Toolchain, outdated deps, analyzer counts, untested risky files. | Read-only. |
| `debug <trace>` | Reproduce → failing test → root-cause fix → verify. | Asks when a decision is the user's to make. |
| `pr [--draft]` | Commit message + PR description from the diff and plan. | Separate approvals for commit, push, and PR. |
| `release <version\|major\|minor\|patch>` | Bumps versions in every platform file and updates the changelog. | Approvals for edits, commit, tag, and push. |
| `test-gen [path]` | Writes tests for untested code, riskiest first. Reports suspected bugs instead of bending tests. | Asks before writing. |
| `deps [package] [--major]` | Upgrades one dependency at a time: changelog check, migrate, verify. Reverts upgrades that fail. | Asks for selection; majors opt-in. |
| `store-check [ios\|android]` | Usage strings, privacy manifest, permissions, data safety, icons, versions. | Read-only. |
| `distribute <firebase\|testflight>` | Uses the project's existing pipeline (fastlane, CI, EAS). | Explicit yes to the exact upload command. |

Every command reads `project.md` first (otherwise: "Run /tara:init first"), applies `learnings.md`, uses the project's own commands, ends with a ≤5-line summary, and supports `--quiet`.

Precedence when instructions conflict: your message > project `CLAUDE.md` + `project.md` > `learnings.md` > plugin skills.

## Reviewer agents

| Agent | Focus |
|---|---|
| `perf-reviewer` | rebuilds/recomposition, main-thread work, lists, leaks, disposal |
| `security-reviewer` | secrets, insecure storage, sensitive logging, input validation, network config |
| `state-reviewer` | state-library misuse, logic in UI, layer violations, DI |
| `ui-reviewer` | accessibility, dark mode, text scale, loading/empty/error states, screen sizes |

The agents are read-only and use the project's conventions. Output: `P1|P2|P3 · file:line · issue · fix`. Severity: **P1** crash, security, data loss, store rejection · **P2** performance, UX, architecture · **P3** cleanup.

## Skills

`flutter`, `ios-swift`, `android-kotlin`, `react-native`, `kmp`. Each one loads automatically only for its platform's files. A short `SKILL.md` points to detail files (state, performance, concurrency, Compose, SwiftUI, UIKit, testing) that load only when needed. Generic practice only; project rules belong in `project.md`.

> `ios-swift` and `flutter` are generic baselines to revise with your own experience. `android-kotlin`, `react-native`, and `kmp` follow the official docs and are meant to grow through real use (SPEC §9).

## Hooks

| Hook | When | What |
|---|---|---|
| `format.sh` | after Edit/Write | Formats only the edited file: `.dart` → `dart format`, `.swift` → `swiftformat`, `.kt`/`.kts` → `ktlint`, `.ts`/`.tsx`/`.js`/`.jsx` → `prettier` (the project's own first). A missing tool is skipped silently. |
| `guard.sh` | before Edit/Write/Bash | Blocks edits to protected files, `rm -rf` outside the project, `git push --force`, and commits that add likely secrets or signing/env files. Prints the reason. |

Protected by default: `*.jks`, `*.keystore`, `*.p12`, `*.mobileprovision`, `.env*` (except `.env.example`/`.sample`/`.template`/`.dist`), `google-services.json`, `GoogleService-Info.plist`. Add more under `# Protected files` in `project.md` (globs are fine, e.g. `lib/generated/`).

If the guard blocks something you intend to do, run it yourself with `! <command>`, or edit the file yourself. To commit a line the secret scan flags by mistake, add a `tara:allow-secret` comment to that line. `--force-with-lease` is allowed.

Scripts are POSIX `sh`. They use `jq` if present (macOS ships it) and fall back to `sed`.

## Recommended: fewer permission prompts

Not set by the plugin. To pre-approve your stack's safe commands, add them to the project's `.claude/settings.json`:

```json
{
  "permissions": {
    "allow": [
      "Bash(git status *)", "Bash(git diff *)", "Bash(git log *)",
      "Bash(flutter analyze *)", "Bash(flutter test *)", "Bash(dart format *)"
    ]
  }
}
```

## Development

- Testing and fixtures: [fixtures/README.md](fixtures/README.md). Keep fixture projects **outside** the plugin folder, because Claude Code protects files under a loaded plugin's directory.
- The detector can be run by hand: `sh scripts/detect.sh <project> [--root <app>]`.
