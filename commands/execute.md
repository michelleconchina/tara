---
description: Implement an approved tara plan one phase at a time, verifying each phase with analyze and tests and ticking it off in the plan file
argument-hint: "[plan-slug | path] [--quiet]"
allowed-tools: Read(/${CLAUDE_PLUGIN_ROOT}/skills/**)
---

# /tara:execute

Arguments: `$ARGUMENTS`

Precedence when instructions conflict: (1) the user's current message, (2) project `CLAUDE.md` + `docs/tara-knowledge/project.md`, (3) `docs/tara-knowledge/learnings.md`, (4) plugin skills.

Human gates: never commit, push, sign, or upload. Never edit protected files. The plan file is the source of truth for progress, so another session can resume from it after `/clear`.

## 1. Load knowledge

- Find the app root: the nearest directory, from the current directory up to the git top level, that contains `docs/tara-knowledge/project.md`. All `docs/tara-knowledge/` paths below are relative to it. If none is found but app roots below the current directory have one (monorepo), list them and ask which app to use. If there is none at all: print `Run /tara:init first` and stop.
- Read that `project.md`.
- Skill folder for the stack: flutter → `flutter`, ios → `ios-swift`, android → `android-kotlin`, react-native/expo → `react-native`, kmp → `kmp` (plus `android-kotlin`/`ios-swift` for platform code; kmp testing guidance is in its `SKILL.md`, there is no `kmp/testing.md`).
- Read `docs/tara-knowledge/learnings.md` if present and apply it.
- Load the platform skill for the stack (`${CLAUDE_PLUGIN_ROOT}/skills/<flutter|ios-swift|android-kotlin|react-native|kmp>/SKILL.md`) and the detail files relevant to each phase.
- Take the `analyze/lint` and `test` commands from `project.md`. Never substitute your own.

## 2. Pick the plan

- Argument given: `docs/tara-knowledge/plans/<arg>.md`, or the path itself.
- No argument: list plans whose `Status:` is `approved` or `in-progress`. One → use it. Several → ask which (show slug, status, next unchecked phase). None → say `No approved plan. Run /tara:plan <feature>, or approve a draft.` and stop.
- Status `draft`: show the plan's phases and ask the user to approve it first. Proceed only on explicit approval (then set `Status: approved`).
- Status `done`: say so and stop.

## 3. Resume check

- Set `Status: in-progress` (only that line) if it isn't already.
- The next phase is the first `- [ ]` phase. Earlier `- [x]` phases are done; don't redo them.
- If the plan has a `Blocked:` note on the next phase, or `git status` shows uncommitted changes in that phase's files, inspect the current state of those files first and continue from there rather than starting the phase over.

## 4. For each remaining phase, in order

1. **Announce** the phase goal and files (one line).
2. **Implement** only what the phase needs. Stay within its listed files. If another file is required, make the change and add a bullet under `## Decisions`: `- Phase N also changed <path>: <reason>`.
3. **Verify:** run the analyze command, then the test command from `project.md`. If the project's test command accepts a path, run the tests for this phase first, then the full suite. Check the phase's Acceptance line explicitly (e.g. the named test exists and passes).
4. **Pass:** tick the box (`- [ ] Phase N` → `- [x] Phase N`) and add an indented line under that phase:
   `  - Done: <YYYY-MM-DD> · evidence: <analyze command> clean, <test command> <n> passed`
   Then continue to the next phase.
5. **Fail** (analyze errors, failing tests, or unmet acceptance):
   - If the failure is a trivial slip in code you just wrote (typo, missing import), fix it once and re-verify.
   - Otherwise stop. Under the phase, add `  - Blocked: <YYYY-MM-DD> · <failing command> · <one-line cause>`, leave the box unchecked, and report. Suggest `/tara:test <slug>` to diagnose and fix.

New analyzer warnings introduced by your changes count as failures. Pre-existing warnings don't, but mention their count.

## 5. Finish

When every phase is ticked: set `Status: done` and suggest `/tara:review` (and `/tara:test <slug>` to capture learnings).

## 6. Summary

End with at most 5 lines: plan, phases done this run / total, verification evidence, files changed, next step (or the blocker).

`--quiet`: output only this one line, with no progress notes, findings, or summary before it (questions that need an answer still appear): `tara execute: <slug> · <done>/<total> phases · <done | in-progress | blocked at phase N>`
