---
description: Debug an error or stack trace. Reproduce it with a failing test, find the root cause, fix it, and verify
argument-hint: "<error message | stack trace | bug description> [--quiet]"
allowed-tools: Read, Read(/${CLAUDE_PLUGIN_ROOT}/skills/**), Grep, Glob, Bash(git log *), Bash(git diff *), Bash(git status *)
---

# /tara:debug

Arguments: `$ARGUMENTS`

Precedence when instructions conflict: (1) the user's current message, (2) project `CLAUDE.md` + `docs/tara-knowledge/project.md`, (3) `docs/tara-knowledge/learnings.md`, (4) plugin skills.

Order is fixed: **reproduce → failing test → fix → verify.** Don't fix before you can show the bug. Never commit.

## 1. Load knowledge

- Find the app root: the nearest directory, from the current directory up to the git top level, that contains `docs/tara-knowledge/project.md`. All `docs/tara-knowledge/` paths below are relative to it. If none is found but app roots below the current directory have one (monorepo), list them and ask which app to use. If there is none at all: print `Run /tara:init first` and stop.
- Read that `project.md`.
- Skill folder for the stack: flutter → `flutter`, ios → `ios-swift`, android → `android-kotlin`, react-native/expo → `react-native`, kmp → `kmp` (plus `android-kotlin`/`ios-swift` for platform code; kmp testing guidance is in its `SKILL.md`, there is no `kmp/testing.md`).
- Read `docs/tara-knowledge/learnings.md` and look for entries that match this error (same area, message, or file). A known cause saves time; say when you're using one.
- Load the platform skill and its `testing.md` (`${CLAUDE_PLUGIN_ROOT}/skills/<flutter|ios-swift|android-kotlin|react-native|kmp>/`).
- No error in the arguments: ask the user to paste the error, stack trace, or steps, and stop.

## 2. Understand

- Parse the trace. Separate project frames from framework/library frames, then open the top project frames and read the code around them.
- Restate the bug in one line: *when X, Y happens, expected Z*.
- Check recent changes to those files (`git log -5 -- <file>`, `git diff`), which are often the cause.
- List 1–3 hypotheses, most likely first.

## 3. Reproduce with a failing test

- Write the smallest test that triggers the bug through the public API of the unit (logic/state class first, widget/UI test only if the bug is in UI). Put it where the project keeps tests, named for the behavior (`'does not crash when the receipt has no items'`).
- Run only that test with the project's test command. It must **fail for the reported reason** (same exception or wrong value). If it fails for another reason, fix the test, not the code.
- **Can't reproduce in a test** (device-only, timing, platform channel, release-only): say why, give exact manual repro steps, and ask the user to confirm the bug still reproduces before changing code. Add logging only if needed, and remove it afterwards.

## 4. Root cause and fix

- State the root cause in 1–3 sentences with `file:line`. A fix that only hides the symptom (catch-and-ignore, null check without understanding why it's null) is not acceptable unless the user agrees.
- Make the smallest fix at the root cause. Max 3 attempts. If the first attempt fails and you aren't on Opus, run attempts 2–3 through a `general-purpose` subagent with `model: opus`, then verify its result yourself.
- Look for the same bug pattern elsewhere (Grep). Report other occurrences; fix them only if the user agrees.

## 5. Verify

1. The new test passes.
2. The analyze command from `project.md` is clean (no new warnings).
3. The full test suite passes.
If anything fails after 3 attempts: stop, report the evidence and hypotheses, and leave the failing test in place (tell the user).

## 6. Learning

If the root cause is non-obvious and likely to recur, propose one learning:
`- <YYYY-MM-DD> · [area] · <cause → fix pattern> · evidence: <new test name>`
Ask before saving it to `learnings.md`.

## 7. Summary

End with at most 5 lines: the bug, root cause (`file:line`), fix, evidence (test name + suite result), learning proposed/saved.

`--quiet`: output only this one line, with no progress notes or summary before it (questions that need an answer still appear): `tara debug: fixed <file:line> · test '<name>' · suite <passed>/<total>` or `tara debug: not reproduced · <reason>`
