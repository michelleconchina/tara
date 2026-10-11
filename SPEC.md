# SPEC — `tara` Mobile Workflow Plugin for Claude Code

> This file is the single source of truth.
> Claude: read this whole file before any work. Implement only the phase you are asked for.

---

## 1. Goal

A Claude Code plugin installed once, usable on **any** mobile project.
The plugin contains only generic logic. Everything project-specific is **discovered by `/tara:init`** and stored in the project.

## 2. Design principles

1. **Generic plugin, generated project knowledge.** No project names, paths, or package choices hardcoded in the plugin.
2. **Detect, then confirm.** `init` proposes what it detected; the user confirms or corrects before anything is written.
3. **Human gates.** Plans stop for approval. Nothing is committed, pushed, signed, or uploaded without explicit approval.
4. **Verified knowledge only.** Learnings are saved only after tests/analyze pass, with evidence.
5. **Lean context.** Short entry files; details loaded only when needed (progressive disclosure).
6. **Fail soft.** Missing tools (e.g. `swiftformat` not installed) never block work — skip and report.
7. **Diff-first.** Review and test the changed code by default, not the whole repo.

## 3. Precedence (when instructions conflict)

1. User's current message
2. Project `CLAUDE.md` + `docs/tara-knowledge/project.md`
3. `docs/tara-knowledge/learnings.md`
4. Plugin skills (generic best practices)

Every command and agent must state this order once in its prompt.

## 4. Plugin structure

```
tara/
├── .claude-plugin/
│   └── plugin.json            # name, version, description, author
├── commands/
│   ├── init.md  plan.md  execute.md  test.md  review.md  learn.md
│   └── (later) build.md health.md debug.md pr.md release.md test-gen.md deps.md store-check.md
├── agents/
│   ├── perf-reviewer.md  security-reviewer.md  state-reviewer.md  ui-reviewer.md
├── skills/
│   ├── flutter/        SKILL.md state.md performance.md testing.md
│   ├── ios-swift/      SKILL.md concurrency.md swiftui.md uikit.md testing.md
│   ├── android-kotlin/ (later)
│   ├── react-native/   (later)
│   └── kmp/            (later)
├── hooks/
│   ├── hooks.json
│   └── scripts/        format.sh  guard.sh
├── fixtures/README.md  # how to test the plugin (see §11)
├── CHANGELOG.md
└── README.md
```

Before scaffolding, verify the current Claude Code plugin format (manifest fields, folder names, frontmatter keys, hook event names, `${CLAUDE_PLUGIN_ROOT}`) against the official docs. If anything here conflicts with the docs, the docs win — note the difference in CHANGELOG.md.

## 5. Project knowledge base (written into each project)

```
docs/tara-knowledge/
├── project.md       # written by init, edited by user. Commit it.
├── learnings.md     # appended by test/learn. Commit it.
└── plans/           # one file per feature. Commit or gitignore — user's choice at init.
```

`init` also adds one line to the project's `CLAUDE.md` (create if missing) so knowledge is always loaded:
```
See docs/tara-knowledge/project.md for stack, commands, and conventions.
```

### 5.1 `project.md` schema
```markdown
<!-- tara-schema: 1 -->
# Project
- Name:
- Stack: flutter | ios | android | react-native | expo | kmp
- Secondary: (e.g. native iOS module inside Flutter)
- Languages:
- State management:
- UI framework: (SwiftUI | UIKit | Compose | XML | Widgets | RN)
- Architecture: (describe folder pattern, with real paths)
- Flavors / schemes / environments:
- Firebase / backend services:

# Commands
- run:
- test:
- analyze/lint:
- format:
- build-android:
- build-ios:

# Conventions
- (only rules evidenced in existing code or confirmed by user)

# Protected files
- (signing files, env files, generated code paths)
```

### 5.2 `learnings.md` entry format
```markdown
- 2026-10-10 · [area] · lesson in one line · evidence: <test name / command / commit>
```
No entry without evidence. Max ~100 entries; `learn --prune` consolidates.

### 5.3 Plan file format (`plans/<slug>.md`)
```markdown
# <Feature>
Status: draft | approved | in-progress | done
## Context  (files read, 3–5 bullets)
## Phases
- [ ] Phase 1 — <goal>
  - Files:
  - Acceptance: <how we know it's done>
## Risks
## Decisions
```
`execute` updates checkboxes and Status so work can resume after `/clear` or a new session.

## 6. Detection rules (`init`)

Check in this order (Flutter/RN projects also contain `ios/` and `android/`):

| Order | Signal | Stack |
|---|---|---|
| 1 | `pubspec.yaml` with `flutter` | flutter |
| 2 | `package.json` with `expo` | expo (react-native) |
| 3 | `package.json` with `react-native` | react-native |
| 4 | Gradle with `kotlin("multiplatform")` / `kotlin-multiplatform` plugin | kmp |
| 5 | `*.xcodeproj` / `*.xcworkspace` / `Package.swift` | ios |
| 6 | `build.gradle(.kts)` + `AndroidManifest.xml` | android |

Then detect, from dependency files and source:
- State management (flutter_bloc, riverpod, provider, getx, mobx; redux/zustand; SwiftUI Observable/Combine/TCA; ViewModel/MVI)
- UI framework (SwiftUI vs UIKit by imports; Compose vs XML)
- Architecture (folder layout — report real paths, never guess)
- Flavors/schemes, Firebase config files, test setup, lint/format config files

Edge cases:
- **Monorepo / multiple apps:** list them, ask which one (or all, one `project.md` per app root).
- **Nothing detected:** say so, ask the user. Never write guesses.
- **Existing `project.md`:** `init --refresh` shows a diff of proposed changes; never overwrites user edits silently.

## 7. Commands

Every command:
1. Reads `project.md` first. If missing (except `init`), say "Run /tara:init first" and stop.
2. Reads `learnings.md` if present.
3. Uses commands from `project.md` — never hardcodes `flutter test` etc.
4. Ends with a ≤5-line summary.
5. Supports `--quiet` (result line only).

Frontmatter on each: `description`, `argument-hint`, and `model` / `allowed-tools` where useful.

### Core (v1)

| Command | Model | Steps | Output |
|---|---|---|---|
| `init [path]` | light | detect (§6) → show findings → **ask to confirm/correct** → write `project.md`, `CLAUDE.md` line, empty `learnings.md` | knowledge base |
| `plan <feature>` | strong | read knowledge → explore relevant files → write plan file (§5.3) → **STOP for approval** | `plans/<slug>.md` (draft) |
| `execute [plan]` | default | pick approved plan (ask if several) → one phase at a time → after each: run analyze + tests → tick checkbox → continue or stop on failure | updated plan, code |
| `test [plan]` | default → strong on 2nd failure | run analyze + tests → fix failures (max 3 attempts, then stop and report) → if all pass, propose learnings with evidence → **ask before saving** | learnings entries |
| `review [path\|--all]` | strong | default scope: `git diff` vs main branch (fallback: staged/unstaged changes) → run applicable reviewer agents **in parallel** → merge, dedupe → P1/P2/P3 → top 3 fixes | review report |
| `learn <lesson>` / `learn --prune` | light | add one entry (ask for evidence) / consolidate duplicates and stale entries, show diff, ask before writing | learnings.md |

If there are no tests: `test` runs analyze + build and gives a short manual test checklist instead of claiming success.

### Later (v2+)

| Command | Purpose |
|---|---|
| `build` | Platform build using `project.md` commands; flavor/scheme args; never touches signing config |
| `health` | SDK/tool versions, outdated deps, analyzer warning count, missing tests |
| `debug <trace>` | Reproduce → failing test → fix → verify |
| `pr` | Commit message + PR description from diff; **show before committing/pushing** |
| `release <version>` | Bump version in all platform files, changelog, tag — **approval before tag** |
| `test-gen [path]` | Write tests for untested, riskiest code first |
| `deps` | Upgrade one dependency at a time, check breaking changes, run tests |
| `store-check` | iOS privacy manifest + usage strings, Play data safety, permissions, icons |
| `distribute` | Firebase / TestFlight — last, only after everything else is stable |

## 8. Reviewer agents

All reviewers:
- `tools: Read, Grep, Glob` (read-only)
- Read `project.md` first; apply only checks relevant to the stack (load the matching skill's checklist)
- Output: `P1|P2|P3 · file:line · issue · fix` — max 10 findings, most severe first; "No issues" in one line if clean
- Never report style issues a formatter would fix

| Agent | Focus |
|---|---|
| perf-reviewer | rebuilds/recomposition, main-thread/isolate work, list virtualization, leaks, undisposed resources |
| security-reviewer | secrets, insecure storage, logging of personal/financial data, unvalidated input, network security config |
| state-reviewer | state-management misuse, logic in UI, layer violations, DI/dependency flow |
| ui-reviewer | accessibility, dark mode, dynamic type/text scale, loading/empty/error states, screen sizes |

Severity: **P1** crash, security, data loss, store rejection · **P2** performance, UX, architecture · **P3** cleanup.

## 9. Skills

- One skill per platform; description triggers on that platform's files/languages only.
- `SKILL.md` ≤ 60 lines: core rules + "read `<file>.md` when doing X".
- Generic best practices only. Project rules belong in `project.md`.
- v1: `flutter`, `ios-swift` (written from the author's own experience).
- Later: `android-kotlin`, `react-native`, `kmp` — from official docs only, short and factual; expand through real use.

## 10. Hooks & safety

| Hook | Event | Behavior |
|---|---|---|
| `format.sh` | after Edit/Write | read edited file path from hook input; pick formatter by extension (`.dart`→dart format, `.swift`→swiftformat, `.kt`→ktlint, `.ts/.tsx/.js`→prettier); **format only that file**; if tool missing, exit 0 silently |
| `guard.sh` | before Edit/Write/Bash | block edits to protected files (`*.jks`, `*.keystore`, `*.p12`, `*.mobileprovision`, `.env*`, `google-services.json`, `GoogleService-Info.plist`, paths in `project.md` → Protected files); block `rm -rf` outside the project, `git push --force`, and commits containing likely secrets; print the reason |

Scripts must be POSIX `sh`, executable, and work on macOS. Reference them via `${CLAUDE_PLUGIN_ROOT}`.

Recommended (documented in README, not forced): allow-list safe commands (test/analyze/git status) in project settings to reduce prompts.

## 11. Testing the plugin

`fixtures/README.md` describes 3 test projects (not committed — created locally):
1. `flutter create fixture_flutter`
2. A blank Xcode SwiftUI app
3. A real project (e.g. receipt calculator)

**Acceptance per change:** `init` detects correctly on all three; `review` runs and returns findings in the right format; hooks fire and fail soft when a formatter is missing.

## 12. Out of scope for v1

Signing management, env switching, distribution, Android/RN/KMP skills, branch-scoped knowledge, MCP integrations.

## 13. Roadmap

| Phase | Deliverable | Done when |
|---|---|---|
| 1 | Skeleton: manifest, README, CHANGELOG, `review` + 4 agents, `flutter` + `ios-swift` skills, hooks | Installs locally; `/tara:review` works on fixture 1 & 2 |
| 2 | `init` + knowledge base | Correct `project.md` on all 3 fixtures, with confirm step |
| 3 | `plan` → `execute` → `test` → `learn` | A second `plan` uses learnings from the first; resume after `/clear` works |
| 4 | `build`, `health`, `pr`, `debug` | Used on one real task each |
| 5 | Android / RN / KMP detection + skills | Detected and reviewed on a sample project each |
| 6 | `release`, `test-gen`, `deps`, `store-check`, `distribute` | After 2 weeks of real use |
