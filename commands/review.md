---
description: Review changed mobile code with parallel reviewer agents (perf, security, state, UI) and report P1/P2/P3 findings with the top 3 fixes
argument-hint: "[path | --all] [--quiet]"
model: opus
allowed-tools: Read, Grep, Glob, Agent, Bash(git rev-parse *), Bash(git symbolic-ref *), Bash(git show-ref *), Bash(git merge-base *), Bash(git diff *), Bash(git status *), Bash(git ls-files *)
---

# /tara:review

Arguments: `$ARGUMENTS`

Precedence when instructions conflict: (1) the user's current message, (2) project `CLAUDE.md` + `docs/tara-knowledge/project.md`, (3) `docs/tara-knowledge/learnings.md`, (4) plugin skills.

This command is read-only. Never edit files, stage, commit, or push. Offer fixes; don't apply them.

## 1. Load project knowledge

- Project root: `git rev-parse --show-toplevel`, or the current directory if not a git repo.
- Read `docs/tara-knowledge/project.md`. Take the stack, secondary stack, UI framework, state management, architecture, conventions, and protected files from it.
- If `project.md` is missing: do **not** stop (until `/tara:init` ships, review must work without it). Detect the stack read-only, checking in this order and stopping at the first match:
  1. `pubspec.yaml` containing `flutter` → flutter
  2. `package.json` containing `expo` → expo
  3. `package.json` containing `react-native` → react-native
  4. Gradle file with `kotlin("multiplatform")` or `kotlin-multiplatform` → kmp
  5. `*.xcodeproj`, `*.xcworkspace`, or `Package.swift` → ios
  6. `build.gradle(.kts)` + `AndroidManifest.xml` → android
  If nothing matches, say so and ask the user for the stack. Write nothing. Note in the report: "No project.md, so the stack was detected for this run only. Run /tara:init to save it."
- Read `docs/tara-knowledge/learnings.md` if present. Pass relevant entries to the reviewers.

## 2. Determine scope

Parse `$ARGUMENTS`: `--quiet` sets quiet output; `--all` means the whole project; any other argument is a path (file or directory).

- **Path:** every source file under that path. Changed lines = "whole file".
- **--all:** every source file in the project. Changed lines = "whole file". If more than 60 files, say how many and ask the user to confirm or narrow to a path first.
- **Default (diff-first):**
  1. Base branch: `git symbolic-ref --short refs/remotes/origin/HEAD` (strip `origin/`). If that fails, the first of `main`, `master`, `develop` that exists (`git show-ref --verify refs/heads/<name>` or `refs/remotes/origin/<name>`).
  2. If on a different branch than the base: `MB=$(git merge-base HEAD <base>)`, files = `git diff --name-only --diff-filter=ACMR $MB` (committed + staged + unstaged changes since the branch point).
  3. If on the base branch, or no base found: files = `git diff --name-only --diff-filter=ACMR HEAD` (staged + unstaged).
  4. Add untracked files: `git ls-files --others --exclude-standard`.
  5. Changed line ranges per file: `git diff -U0 <same base> -- <file>` hunk headers (`@@ -a,b +c,d @@` → lines c..c+d-1). Untracked files are "whole file".
  6. Not a git repo: ask for a path.
- **Exclude:** deleted files, binaries, lockfiles (`pubspec.lock`, `Podfile.lock`, `package-lock.json`, `yarn.lock`, `Package.resolved`, `*.lock`), generated code (`*.g.dart`, `*.freezed.dart`, `*.gr.dart`, `*.mocks.dart`, `*.pb.*`, `*.generated.*`, and generated paths in `project.md`), build output and dependencies (`build/`, `.dart_tool/`, `Pods/`, `DerivedData/`, `node_modules/`, `.gradle/`), and `*.pbxproj`.
- Nothing left in scope: print `tara review: nothing to review (no changes vs <base>)` and stop.

## 3. Choose reviewers

| Reviewer | Run when scope includes |
|---|---|
| `tara:security-reviewer` | always |
| `tara:perf-reviewer` | any source file (`.dart`, `.swift`, `.kt`, `.java`, `.ts`, `.tsx`, `.js`, `.jsx`, `.m`, `.mm`) |
| `tara:state-reviewer` | any source file outside tests |
| `tara:ui-reviewer` | UI code: Flutter widgets/screens (files importing `package:flutter/material.dart` or `cupertino.dart`, or under a UI folder from `project.md`), `import SwiftUI`/`import UIKit` files, `.storyboard`, `.xib`, Android layouts, `@Composable`, `.tsx`/`.jsx` components |

Config-only changes (plist, manifest, xml, gradle, yaml) get the security reviewer only.

## 4. Run reviewers in parallel

Launch all chosen reviewers **in a single message** (parallel Agent calls). Give each reviewer the same brief:

```
Project root: <absolute path>
Stack: <stack> (secondary: <secondary or none>); UI: <ui framework>; state: <state management>
Architecture: <one line from project.md, or "unknown">
Knowledge: <"docs/tara-knowledge/project.md present" | "no project.md; detected from <signal>">
Relevant learnings: <0–5 lines, or none>
Files in scope (path: changed lines):
- lib/features/cart/cart_screen.dart: 12-40, 88-95
- ios/Runner/AppDelegate.swift: whole file
Return findings in your output format only.
```

If there are more than 40 files, split them into batches of about 20 per reviewer call and run all batches in parallel too.

## 5. Merge

- Collect every line of the form `P<n> · file:line · issue · fix`. Ignore anything else a reviewer outputs.
- Dedupe: findings on the same file within ±3 lines describing the same problem merge into one. Keep the highest severity and the clearest fix, and tag the reviewers (`[perf+state]`).
- Verify every P1 by reading the cited line yourself. Downgrade or drop it if the code doesn't support the claim.
- Drop anything a formatter would fix, anything contradicting `project.md` conventions or `learnings.md`, and findings outside the scope unless they are P1.
- Sort P1 → P2 → P3, then by file path.

## 6. Report

Normal output:

```
## tara review — <scope description, e.g. "12 files changed vs main">
Stack: <stack> · Reviewers: <names> · Knowledge: <project.md | detected>

### P1
- `path:line` — issue → fix  [reviewer]
### P2
- …
### P3
- …

### Top 3 fixes
1. <highest-value fix, why it matters>
2. …
3. …
```

Omit empty severity sections. If no findings: `No issues found in <scope>.`

End with a summary of 5 lines or fewer: counts by severity, files reviewed, reviewers run, anything skipped (e.g. "UI reviewer skipped: no UI files"), and the next step (e.g. "Ask me to apply fix 1" or "Run /tara:init").

**`--quiet`:** print only one line:
`tara review: <n> P1 · <n> P2 · <n> P3 (<files> files vs <base>)`
