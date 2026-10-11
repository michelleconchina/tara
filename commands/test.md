---
description: Run analyze and tests, fix failures (max 3 attempts), and propose verified learnings with evidence
argument-hint: "[plan-slug] [--quiet]"
allowed-tools: Read(/${CLAUDE_PLUGIN_ROOT}/skills/**)
---

# /tara:test

Arguments: `$ARGUMENTS`

Precedence when instructions conflict: (1) the user's current message, (2) project `CLAUDE.md` + `docs/tara-knowledge/project.md`, (3) `docs/tara-knowledge/learnings.md`, (4) plugin skills.

Human gates: never commit or push. Learnings are saved only after everything passes, only with evidence, and only after the user says yes.

## 1. Load knowledge

- Find the app root: the nearest directory, from the current directory up to the git top level, that contains `docs/tara-knowledge/project.md`. All `docs/tara-knowledge/` paths below are relative to it. If none is found but app roots below the current directory have one (monorepo), list them and ask which app to use. If there is none at all: print `Run /tara:init first` and stop.
- Read that `project.md`.
- Skill folder for the stack: flutter → `flutter`, ios → `ios-swift`, android → `android-kotlin`, react-native/expo → `react-native`, kmp → `kmp` (plus `android-kotlin`/`ios-swift` for platform code; kmp testing guidance is in its `SKILL.md`, there is no `kmp/testing.md`).
- Read `docs/tara-knowledge/learnings.md` if present.
- Load the platform skill's `testing.md` (`${CLAUDE_PLUGIN_ROOT}/skills/<flutter|ios-swift|android-kotlin|react-native|kmp>/testing.md`).
- Commands: `analyze/lint`, `test`, and `build-*` from `project.md`, used verbatim.
- Plan given: read `docs/tara-knowledge/plans/<slug>.md` and use its Files as the focus.

## 2. Scope (diff-first)

Focus files: the plan's Files, else changed files vs the main branch (`git diff --name-only $(git merge-base HEAD <base>)` plus untracked; on the base branch, `git diff --name-only HEAD`). Find tests for those files (mirrored paths, e.g. `lib/a/b.dart` → `test/a/b_test.dart`; `Foo.swift` → `FooTests.swift`; or tests that import them).

## 3. Run

1. Analyze command. Record errors and the warning count.
2. Focused tests first (if the test command accepts paths), then the full test command.
3. Record evidence: exact commands, pass/fail counts, failing test names.

### No tests in the project

If there are no test files or `test:` is `—`/empty: run analyze and the debug build command(s) instead, then give a manual test checklist of 5–8 concrete steps for the changed behavior (screens, inputs, edge cases, offline/error, dark mode, large text). Report `not tested automatically`; never claim success. Offer to set up a first test (e.g. `/tara:test-gen`).

## 4. Fix failures (max 3 attempts)

For each attempt:
1. Read the failure and the code under test. Decide whether the code or the test is wrong, and say which and why in one line.
2. Make the smallest fix. Never delete, skip, or loosen a test (`skip:`, removing assertions, widening tolerances) to make it pass, unless the user agrees the test is wrong.
3. Re-run the failing tests, then the full suite.

**Escalation:** attempt 1 is yours. If it still fails, and you are not already running on Opus, do attempts 2 and 3 through a `general-purpose` subagent with `model: opus`. Give it the failing output, the files involved, what attempt 1 tried, and the rules above, and have it report its diagnosis and changes. Verify its result yourself by re-running the tests.

After 3 failed attempts: stop. Report the failing tests, the error output (trimmed), what each attempt tried, and your best hypothesis. If a plan is in progress, add `  - Blocked: <YYYY-MM-DD> · <command> · <cause>` under its current phase. Propose no learnings.

## 5. Propose learnings (only when everything passes)

A learning is a non-obvious, reusable, project-specific lesson that this run proved, such as the root cause of a failure you fixed, a project quirk, or a command flag that's required. Not generic advice the skill already says, and not a summary of the change.

- 0–3 candidates. Zero is fine; don't invent.
- Format: `- <YYYY-MM-DD> · [area] · <lesson in one line> · evidence: <test name / command / commit>`. Area is short: `[state]`, `[ios]`, `[build]`, `[testing]`, `[firebase]`, a feature name, etc.
- Skip candidates that duplicate an existing entry (or propose updating that entry instead).
- Show them and ask: "Save these learnings? (all / pick numbers / none)". Append only the approved ones to `learnings.md`. If the file has more than ~100 entries, suggest `/tara:learn --prune`.

## 6. Summary

End with at most 5 lines: analyze result, tests (passed/failed/total, or "no tests: manual checklist given"), attempts used, learnings saved, next step.

`--quiet`: output only this one line, with no progress notes, findings, or summary before it (questions that need an answer still appear): `tara test: <pass | fail | no tests> · <passed>/<total> · <n> learnings proposed`
