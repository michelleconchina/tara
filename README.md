# tara

A Claude Code plugin for mobile app work: Flutter, iOS/Swift, and more later. Install it once and use it on any project. The plugin holds only generic logic. Project specifics (stack, commands, conventions) are discovered per project and stored in `docs/tara-knowledge/`.

The full design and roadmap are in [SPEC.md](SPEC.md).

## Status: v0.1.0 (Phase 1)

| Available | Coming |
|---|---|
| `/tara:review`, 4 reviewer agents, `flutter` + `ios-swift` skills, format + guard hooks | `init` (Phase 2) · `plan`, `execute`, `test`, `learn` (Phase 3) · `build`, `health`, `pr`, `debug` (Phase 4) |

## Install

Try it locally without installing:

```sh
claude --plugin-dir /path/to/tara
```

Run `/reload-plugins` after changing plugin files. To check the manifest, run `claude plugin validate /path/to/tara`.

## `/tara:review [path | --all] [--quiet]`

- **Default:** reviews only what changed vs the main branch: committed, staged, unstaged, and untracked. On the main branch it reviews uncommitted changes.
- **`path`:** reviews every file under that path. **`--all`:** reviews the whole project (asks first if it's large).
- Runs the relevant reviewers in parallel:

  | Agent | Focus |
  |---|---|
  | `perf-reviewer` | rebuilds, main-thread work, lists, leaks, disposal |
  | `security-reviewer` | secrets, storage, logging, input, network config |
  | `state-reviewer` | state misuse, logic in UI, layering, DI |
  | `ui-reviewer` | accessibility, dark mode, text scale, states, screen sizes |

  The UI reviewer only runs when UI files changed.
- Merges and dedupes the findings, checks each P1 against the code, and reports `P1 · file:line · issue · fix` plus the top 3 fixes. It never edits code.
- Severity: **P1** crash, security, data loss, store rejection · **P2** performance, UX, architecture · **P3** cleanup.
- Until `/tara:init` exists, review detects the stack for that run only and writes nothing.

## Skills

`flutter` and `ios-swift` load automatically when Claude works on matching files (`*.dart`, `*.swift`, `Package.swift`, …). Each `SKILL.md` stays short and points to detail files (state, performance, concurrency, SwiftUI, UIKit, testing) that load only when needed. They contain generic practice only. Project rules belong in `docs/tara-knowledge/project.md`.

> The `ios-swift` skill is a generic baseline. Revise it with your own experience (SPEC §9).

## Hooks

| Hook | When | What |
|---|---|---|
| `format.sh` | after Edit/Write | Formats only the edited file: `.dart` → `dart format`, `.swift` → `swiftformat`, `.kt`/`.kts` → `ktlint`, `.ts`/`.tsx`/`.js`/`.jsx` → `prettier` (the project's own first). A missing tool is skipped silently. |
| `guard.sh` | before Edit/Write/Bash | Blocks edits to protected files, `rm -rf` outside the project, `git push --force`, and commits that add likely secrets or signing/env files. Prints the reason. |

Protected by default: `*.jks`, `*.keystore`, `*.p12`, `*.mobileprovision`, `.env*` (except `.env.example`/`.sample`/`.template`/`.dist`), `google-services.json`, `GoogleService-Info.plist`. Add more under `# Protected files` in `docs/tara-knowledge/project.md` (globs are fine, e.g. `lib/generated/`).

If the guard blocks something you intend to do, run it yourself with `! <command>` in the prompt, or edit the file yourself. To commit a line the secret scan flags by mistake, add a `tara:allow-secret` comment to that line.

Scripts are POSIX `sh`. They use `jq` if present (macOS ships it) and fall back to `sed` otherwise.

## Recommended: fewer permission prompts

Not set by the plugin. To pre-approve safe read-only commands, add them to your project's `.claude/settings.json`, adjusted to your stack:

```json
{
  "permissions": {
    "allow": [
      "Bash(git status *)",
      "Bash(git diff *)",
      "Bash(git log *)",
      "Bash(flutter analyze *)",
      "Bash(flutter test *)",
      "Bash(dart format *)"
    ]
  }
}
```

## Development

- Testing: see [fixtures/README.md](fixtures/README.md).
- Changes: see [CHANGELOG.md](CHANGELOG.md).
- Precedence used by every command and agent: user's message > project `CLAUDE.md` + `project.md` > `learnings.md` > plugin skills.
