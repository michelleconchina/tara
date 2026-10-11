---
description: Write tests for untested code, riskiest first, and make sure they pass against the current behavior
argument-hint: "[path] [--max <n>] [--quiet]"
allowed-tools: Read, Read(/${CLAUDE_PLUGIN_ROOT}/skills/**), Grep, Glob, Bash(git log *), Bash(git ls-files *)
---

# /tara:test-gen

Arguments: `$ARGUMENTS`

Precedence when instructions conflict: (1) the user's current message, (2) project `CLAUDE.md` + `docs/tara-knowledge/project.md`, (3) `docs/tara-knowledge/learnings.md`, (4) plugin skills.

Writes test files only. Never changes production code without asking. Never commits.

## 1. Load knowledge

- Find the app root: the nearest directory, from the current directory up to the git top level, that contains `docs/tara-knowledge/project.md`. All `docs/tara-knowledge/` paths below are relative to it. If none is found but app roots below the current directory have one (monorepo), list them and ask which app to use. If there is none at all: print `Run /tara:init first` and stop.
- Read that `project.md`.
- Skill folder for the stack: flutter → `flutter`, ios → `ios-swift`, android → `android-kotlin`, react-native/expo → `react-native`, kmp → `kmp` (plus `android-kotlin`/`ios-swift` for platform code; kmp testing guidance is in its `SKILL.md`, there is no `kmp/testing.md`).
- Read `docs/tara-knowledge/learnings.md`; apply `[testing]` entries.
- Load the platform skill's `testing.md` (`${CLAUDE_PLUGIN_ROOT}/skills/<flutter|ios-swift|android-kotlin|react-native|kmp>/testing.md`; for kmp, the Testing section of its `SKILL.md`).
- Learn the project's test conventions from 2–3 existing tests: location and naming, framework, mocking/fakes library, helpers, setup. Follow them exactly. If there are no tests yet, use the skill's defaults and say which ones you chose.
- Test command from `project.md`. If it's missing, ask for it before writing anything.

## 2. Find untested code

Scope: the given path, or the whole source tree. For each source file, check whether a test exists (mirrored path, or a test that imports it). Skip generated code, UI-only layout files without logic, `main`/app bootstrap, and DI wiring.

## 3. Rank by risk (riskiest first)

Score each untested file:
- **Logic layer** (state classes/view models/blocs, use cases, repositories, services, parsers, formatters, validators) > UI.
- **Domain sensitivity:** money and rounding, dates and time zones, auth/session, parsing external data, persistence and migrations, permissions.
- **Complexity:** branches, error paths, async flows.
- **Churn:** `git log --since=6.months --format= --name-only` frequency; files touched by recent fix commits.

Show the top files (default 5, or `--max`) with one line each on why, plus the test cases you'll write for each (behavior names, including error and edge cases). Ask: **"Write these tests? (all / pick / none)"**.

## 4. Write and run

For each approved file:
1. Write focused tests through the public API: happy path, edge cases (empty, null, boundaries, rounding), and failure paths (exceptions, network errors, timeouts). Fakes at boundaries, no real network, clock, or randomness.
2. Run the new test file. Then:
   - **Passes:** keep it.
   - **Fails because the test is wrong** (setup, wrong assumption about intended behavior): fix the test.
   - **Fails because the code looks buggy:** don't change production code and don't bend the test to the bug. Leave the case out of the file (or mark it skipped with a reason, if the project's framework supports it) and report it as a **suspected bug** with `file:line` and the failing input.
3. After all files: run the analyze command and the full suite once.

## 5. Summary

End with at most 5 lines: test files added, test cases (passed), suspected bugs found, logic files still untested, next step (e.g. `/tara:debug` for a suspected bug).

`--quiet`: still show the proposed list and ask; skip the closing summary and end with only: `tara test-gen: <files> files · <cases> tests passing · <n> suspected bugs`
