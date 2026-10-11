---
description: Read-only project health report covering SDK/tool versions, outdated dependencies, analyzer warnings, and untested code
argument-hint: "[--quiet]"
allowed-tools: Read, Read(/${CLAUDE_PLUGIN_ROOT}/skills/**), Grep, Glob, Bash(flutter --version*), Bash(dart --version*), Bash(fvm *), Bash(xcodebuild -version*), Bash(swift --version*), Bash(java -version*), Bash(flutter doctor*), Bash(node --version*), Bash(pod --version*), Bash(git log *), Bash(git ls-files *)
---

# /tara:health

Arguments: `$ARGUMENTS`

Precedence when instructions conflict: (1) the user's current message, (2) project `CLAUDE.md` + `docs/tara-knowledge/project.md`, (3) `docs/tara-knowledge/learnings.md`, (4) plugin skills.

Read-only: never upgrade, install, clean, or edit anything. Recommend; don't act.

## 1. Load knowledge

- Find the app root: the nearest directory, from the current directory up to the git top level, that contains `docs/tara-knowledge/project.md`. All `docs/tara-knowledge/` paths below are relative to it. If none is found but app roots below the current directory have one (monorepo), list them and ask which app to use. If there is none at all: print `Run /tara:init first` and stop.
- Read that `project.md`.
- Read `docs/tara-knowledge/learnings.md` if present.

## 2. Checks

A tool that isn't installed is a `WARN` with "not installed". Never a reason to stop.

1. **Toolchain.** Installed versions vs what the project requires:
   - Flutter/Dart: `flutter --version` (or `fvm flutter --version` when the project uses fvm) vs `environment:` constraints in `pubspec.yaml` and `.fvmrc`.
   - iOS: `xcodebuild -version`, `swift --version`, CocoaPods (`pod --version`) if a `Podfile` exists; deployment targets (`IPHONEOS_DEPLOYMENT_TARGET`, `platform :ios` in `Podfile`).
   - Android: the JDK the build actually uses, not just `java` on `PATH`. Flutter: the `Java binary at:` line of `flutter doctor -v` (Flutter defaults to Android Studio's bundled JBR). Native Android: `JAVA_HOME`, the Gradle toolchain, or Android Studio's JBR. `java` missing from `PATH` is not a failure on its own. Then the Gradle wrapper version (`gradle/wrapper/gradle-wrapper.properties`), AGP and Kotlin versions, `compileSdk`/`targetSdk`/`minSdk`. Google Play enforces a minimum `targetSdk` that rises every year, so state the value found and say to check it against the current Play requirement.
   - RN/Expo: `node --version` vs `engines`, the React Native or Expo SDK version.
2. **Outdated dependencies.** Use the stack's read-only listing: `flutter pub outdated` (or `dart pub outdated`), `npm outdated` / `yarn outdated` / `pnpm outdated`, version catalogs vs latest for Gradle (only if a check task such as `dependencyUpdates` exists), `pod outdated` only if quick. Separate **major** updates (potentially breaking) from minor/patch. Flag discontinued or deprecated packages.
3. **Analyzer.** Run the `analyze/lint` command from `project.md`. Count errors, warnings, and infos. List the top 5 files by count.
4. **Missing tests.** Compare source files to test files (mirrored paths or imports). Report coverage of logic files (state/view models, repositories, services, utils, parsing) separately from UI files. List the 10 riskiest untested files. Risk = logic layer + size + churn (`git log --format= --name-only --since=6.months | sort | uniq -c`) + domain sensitivity (money, dates, auth, parsing).
5. **Hygiene** (quick): TODO/FIXME count, `print`/`debugPrint`/`NSLog`/`console.log` count in non-test code, and whether `learnings.md` is over ~100 entries.

## 3. Report

```
## tara health — <project name> (<stack>)
| Area | Status | Detail |
|---|---|---|
| Toolchain | OK/WARN/FAIL | … |
| Dependencies | … | n outdated (m major) |
| Analyzer | … | e errors · w warnings |
| Tests | … | x/y logic files tested |
| Hygiene | … | … |

### Recommended next actions
1. … (with the tara command when one fits, e.g. `/tara:deps <pkg>`, `/tara:test-gen <path>`)
```

FAIL = analyzer errors, a toolchain version that doesn't satisfy the project's constraints, or discontinued dependencies. WARN = analyzer warnings, major updates pending, or logic coverage under 50%.

End with a summary of at most 5 lines.

`--quiet`: output only this one line, with no progress notes or summary before it: `tara health: toolchain OK · deps 7 outdated (2 major) · analyzer 0e/12w · tests 14/40 logic files`
