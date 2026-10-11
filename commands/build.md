---
description: Build the app for Android and/or iOS using the project's build commands, with flavor/scheme args; never touches signing
argument-hint: "[android | ios | all] [--flavor <name> | --scheme <name>] [--release] [--quiet]"
allowed-tools: Read, Read(/${CLAUDE_PLUGIN_ROOT}/skills/**), Grep, Glob
---

# /tara:build

Arguments: `$ARGUMENTS`

Precedence when instructions conflict: (1) the user's current message, (2) project `CLAUDE.md` + `docs/tara-knowledge/project.md`, (3) `docs/tara-knowledge/learnings.md`, (4) plugin skills.

Human gates: never edit signing configuration (keystores, `key.properties`, `signingConfigs`, provisioning profiles, entitlements, `ExportOptions.plist`, code-signing build settings), never pass signing identities, never upload. Never commit.

## 1. Load knowledge

- Find the app root: the nearest directory, from the current directory up to the git top level, that contains `docs/tara-knowledge/project.md`. All `docs/tara-knowledge/` paths below are relative to it. If none is found but app roots below the current directory have one (monorepo), list them and ask which app to use. If there is none at all: print `Run /tara:init first` and stop.
- Read that `project.md`.
- Read `docs/tara-knowledge/learnings.md` if present; apply `[build]` entries.
- Take `build-android` / `build-ios` from `project.md`. If the requested platform's command is `—` or empty, say so and stop for that platform.

## 2. Resolve the command

- Platform: from the argument. Default: both platforms that have a command (`all`), but on a non-macOS host skip iOS and say so.
- Flavor/scheme: `--flavor` or `--scheme` must match one listed in `project.md` → Flavors / schemes. If it doesn't, list the valid ones and stop. If the project has flavors and none was given, use the one already in the `project.md` command.
- Swap the flavor/scheme in the stored command with the requested one, keeping everything else verbatim.
- `--release`: change the build mode only (e.g. `--debug` → `--release`, `Debug` → `Release` configuration). Before running a release build, say it uses the project's existing signing setup, and ask to confirm. Keep `--no-codesign` on iOS unless the user explicitly asks for a signed build.
- Show the final command(s) before running.

## 3. Run

Run each platform's command (sequentially). Record duration, exit status, and the artifact path (e.g. `build/app/outputs/flutter-apk/app-debug.apk`, the `.app`/`.xcarchive` path, `app/build/outputs/apk/...`) with its size.

## 4. On failure

1. Find the first real error (not the last line): compiler `file:line`, Gradle task failure, Xcode build error, CocoaPods error.
2. Explain the cause in 1–2 lines and propose a fix.
3. Code errors in the project: offer to fix them (ask first).
4. Environment issues: propose the command and ask before running it, because these change local state. Examples: missing pods (`pod install` / `pod repo update`), stale build (`flutter clean`, `./gradlew clean`, DerivedData), wrong JDK/Xcode/SDK version, missing `local.properties`.
5. **Signing errors** (no provisioning profile, missing keystore, wrong team): explain them, then stop. Don't edit signing files or settings.
6. Re-run once after an approved fix. If it fails again, stop and report.

## 5. Summary

End with at most 5 lines: per platform `✓/✗ <mode> <flavor/scheme> · <duration> · <artifact path> (<size>)`, the error and the proposed fix if failed, and the next step.

`--quiet`: output only this one line, with no progress notes or summary before it: `tara build: android ✓ (1m12s) · ios ✗ (signing)`
