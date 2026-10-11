---
description: Detect this mobile project's stack, commands, and conventions, confirm them with you, then write docs/tara-knowledge/
argument-hint: "[path] [--refresh] [--quiet]"
model: haiku
allowed-tools: Read, Read(/${CLAUDE_PLUGIN_ROOT}/skills/**), Grep, Glob, Bash(sh ${CLAUDE_PLUGIN_ROOT}/scripts/detect.sh *), Bash(git rev-parse *), Bash(git check-ignore *)
---

# /tara:init

Arguments: `$ARGUMENTS`

Precedence when instructions conflict: (1) the user's current message, (2) project `CLAUDE.md` + `docs/tara-knowledge/project.md`, (3) `docs/tara-knowledge/learnings.md`, (4) plugin skills.

Principles: **detect, then confirm.** Nothing is written before the user confirms. Never write a guess. Every value is either evidenced by a file you can name or confirmed by the user. Unknown values stay empty or say `unknown`.

## 1. Arguments

- `path`: the directory to scan (default: current directory).
- `--refresh`: update an existing `project.md` (see step 6).
- `--quiet`: skip the detailed findings and show only the proposed file and the confirm question; end with one result line.

## 2. Detect

Run the read-only detector:

```
sh ${CLAUDE_PLUGIN_ROOT}/scripts/detect.sh <path>
```

- `apps: none`: say nothing was detected and list the signals checked. Ask the user for the stack and app root. Write nothing until they answer.
- `apps: N` (monorepo or several projects): show the list. Ask which app root to set up, or `all` (one `project.md` per app root, under `<app-root>/docs/tara-knowledge/`). Flutter `package` entries are libraries, so suggest the `app` roots. Then rerun with `--root <app-root>` for each chosen root.
- One root: the output already has the details.

If `project_md: exists` and `--refresh` wasn't passed, say so and offer `--refresh`. Stop.

## 3. Fill gaps by reading (only what's needed)

The detector gives facts; you turn them into the schema. Read a few files to confirm, not the whole repo:

- **Stack / Secondary:** stack from `stack:`. Secondary only if `native_ios_files`/`native_android_files`/`platform_channel_files` > 0 (e.g. "native iOS module (ios/Runner/Payments/*.swift) via MethodChannel").
- **Languages:** from `## languages` (ignore counts of 0; Flutter's own `AppDelegate.swift` doesn't make Swift a project language unless there is secondary native code).
- **State management:** the package from `state_packages` and the usage counts. If several, report the dominant one (highest usage) and mention the others. Open one example file to confirm.
- **UI framework:** Widgets / RN / SwiftUI vs UIKit (by file counts; "SwiftUI (UIKit for N legacy screens)" if mixed) / Compose vs XML.
- **Architecture:** describe the folder pattern using real paths from `## folders`, e.g. `feature-first: lib/features/<feature>/{data,domain,presentation}`. If the folder list is too shallow to tell, read 2–3 files. Never name a pattern you didn't see.
- **Flavors / schemes / environments:** from `## environments` (flavors, schemes, `main_*.dart` entrypoints, env file *names*, never contents).
- **Firebase / backend services:** from `## services`; if the section is empty, write `none detected`.
- **Conventions:** only rules evidenced in code or config: the lint package (`analysis_include`), codegen (`build_runner`), DI library, folder naming, test layout, fvm. Each one cites its evidence in parentheses. 3–8 bullets max. Don't invent style rules.
- **Protected files:** signing files found, env files, generated code paths (`*.g.dart`, `lib/generated/`), and anything else found in `## protected_candidates`. The guard hook already blocks `*.jks`, `*.keystore`, `*.p12`, `*.mobileprovision`, `.env*`, `google-services.json`, and `GoogleService-Info.plist`; list project-specific paths here.

### Commands

Propose commands from evidence, in this priority: the project's own scripts (`melos_scripts`, `make_targets`, `npm_scripts`, `just_recipes`) > stack defaults. Prefix Flutter/Dart commands with `fvm` when `fvm: yes`. Include flavor/scheme args when flavors exist (use the first/dev flavor and say so).

| Stack | run | test | analyze/lint | format | build-android | build-ios |
|---|---|---|---|---|---|---|
| flutter | `flutter run [--flavor F -t lib/main_F.dart]` | `flutter test` | `flutter analyze` | `dart format .` | `flutter build apk --debug [--flavor F]` | `flutter build ios --no-codesign [--flavor F]` |
| ios | `xcodebuild -scheme S -destination 'platform=iOS Simulator,name=<simulator>' build` | same with `test` | `swiftlint` if `.swiftlint.yml`, else `—` | `swiftformat .` if `.swiftformat`, else `—` | — | `xcodebuild -scheme S -destination 'generic/platform=iOS Simulator' build` |
| android | `./gradlew installDebug` | `./gradlew testDebugUnitTest` | `./gradlew lint` (+ `detekt`/`ktlintCheck` if configured) | `./gradlew ktlintFormat` if configured | `./gradlew assembleDebug` | — |
| react-native / expo | npm script `start`/`ios`/`android` | npm script `test` | npm script `lint` | `prettier --write .` if configured | `cd android && ./gradlew assembleDebug` (expo: `npx expo run:android`) | `npx react-native run-ios` (expo: `npx expo run:ios`) |
| kmp | — | `./gradlew allTests` | `./gradlew lint` / `detekt` if configured | `ktlintFormat` if configured | `./gradlew :<androidApp>:assembleDebug` | `xcodebuild` on the iOS app's scheme |

For iOS, use a real scheme from `schemes:` and the simulator from `simulator:`; use `-workspace` if a `.xcworkspace` exists, else `-project`. Use the package manager matching the lock file (`yarn`, `pnpm`, `npm`, `bun`). Use `—` where a command doesn't apply. Build commands must not sign or upload.

## 4. Show and confirm

Show, in this order:

1. **Findings** (skip with `--quiet`): 6–10 bullets, each with its evidence (`flutter_bloc in pubspec.yaml; 14 Cubits under lib/features`).
2. **The complete proposed `project.md`** in a code block, exactly as it will be written (schema below).
3. **What else will be written:** `docs/tara-knowledge/learnings.md` (empty), the `CLAUDE.md` line (append, or create `CLAUDE.md` if missing; skip if already present), and `docs/tara-knowledge/plans/`.
4. **Questions** (use the AskUserQuestion tool if available, else ask in text), in one round:
   - Confirm, or what to correct.
   - Plans: commit `docs/tara-knowledge/plans/` (recommended for teams, so plans survive across machines), or add it to `.gitignore`?
   - Any field you marked `unknown` that matters (e.g. the test command when there are no tests yet).

Then **stop and wait**. Apply corrections and show the changed lines again if anything changed beyond trivial edits. Write only after an explicit yes.

## 5. Write

For each confirmed app root:

1. `docs/tara-knowledge/project.md` with this exact schema:

```markdown
<!-- tara-schema: 1 -->
# Project
- Name:
- Stack: flutter | ios | android | react-native | expo | kmp
- Secondary:
- Languages:
- State management:
- UI framework:
- Architecture:
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

   Keep one line per field; put paths in backticks. If no protected paths were found, write `- (none)`. Commands are bare (in backticks) so other tara commands can run them verbatim. Use `—` for not applicable. Under Protected files, one path or glob per bullet; it is the first token on the line (the guard hook reads it), and a note may follow in parentheses.

2. `docs/tara-knowledge/learnings.md`, only if missing:

```markdown
<!-- tara-schema: 1 -->
# Learnings
<!-- One line per lesson: - YYYY-MM-DD · [area] · lesson · evidence: <test / command / commit> -->
<!-- Added by /tara:test and /tara:learn after verification. No entry without evidence. Prune with /tara:learn --prune. -->
```

3. `docs/tara-knowledge/plans/` with a `.gitkeep`. If the user chose to ignore plans, append `docs/tara-knowledge/plans/` to the `.gitignore` **in the app root** (create it if missing), because a pattern with a slash only matches relative to its own `.gitignore`. Skip `.gitkeep`. Verify with `git check-ignore -q docs/tara-knowledge/plans/x.md` from the app root.
4. `CLAUDE.md` at the app root: append (with a blank line before it) or create with exactly:
   `See docs/tara-knowledge/project.md for stack, commands, and conventions.`
   Skip if a line already references `docs/tara-knowledge/project.md`.

Don't commit anything.

## 6. `--refresh`

1. Read the existing `project.md`. If its `tara-schema` is missing or older than 1, say so and map fields by name.
2. Run detection and build the proposal as above.
3. Show a field-by-field diff: only fields where detection differs from the file. For each, show `current` vs `detected` with the evidence.
4. The user's text wins by default: a field the user edited (anything not matching a previous detection) is only changed if they accept that change. Never drop Conventions or Protected files bullets; only propose additions or removals with reasons.
5. Ask which changes to apply (all / none / pick). Write only the accepted changes. Never touch `learnings.md` or plans on refresh.

## 7. Summary

End with at most 5 lines: stack and app root(s), files written (or "nothing written"), fields left unknown, and the next step (`/tara:plan <feature>` or `/tara:review`).

`--quiet`: output only this one line, with no progress notes, findings, or summary before it (questions that need an answer still appear): `tara init: <stack> at <root> · wrote project.md, learnings.md, CLAUDE.md line` (or `· nothing written`).
