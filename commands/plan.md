---
description: Explore the code and write a phased implementation plan to docs/tara-knowledge/plans/<slug>.md, then stop for approval
argument-hint: "<feature description> [--quiet]"
model: opus
allowed-tools: Read, Read(/${CLAUDE_PLUGIN_ROOT}/skills/**), Grep, Glob, Bash(git status *), Bash(git log *), Bash(git diff *), Bash(git ls-files *)
---

# /tara:plan

Arguments: `$ARGUMENTS`

Precedence when instructions conflict: (1) the user's current message, (2) project `CLAUDE.md` + `docs/tara-knowledge/project.md`, (3) `docs/tara-knowledge/learnings.md`, (4) plugin skills.

This command only writes one plan file. It never edits code, never runs builds, and never marks its own plan approved.

## 1. Load knowledge

- Find the app root: the nearest directory, from the current directory up to the git top level, that contains `docs/tara-knowledge/project.md`. All `docs/tara-knowledge/` paths below are relative to it. If none is found but app roots below the current directory have one (monorepo), list them and ask which app to use. If there is none at all: print `Run /tara:init first` and stop.
- Read that `project.md`.
- Skill folder for the stack: flutter → `flutter`, ios → `ios-swift`, android → `android-kotlin`, react-native/expo → `react-native`, kmp → `kmp` (plus `android-kotlin`/`ios-swift` for platform code; kmp testing guidance is in its `SKILL.md`, there is no `kmp/testing.md`).
- Read `docs/tara-knowledge/learnings.md` if present. Keep every entry whose area or lesson touches this feature. You must apply them and cite them in the plan (step 4).
- Load the platform skill for the stack (`${CLAUDE_PLUGIN_ROOT}/skills/<flutter|ios-swift|android-kotlin|react-native|kmp>/SKILL.md`) and the detail files relevant to the feature.
- No feature description in the arguments: ask for one and stop.

## 2. Slug and existing plans

- Slug: lowercase kebab-case of the feature, 3–5 words, max 40 chars (e.g. `receipt-split-by-item`).
- If `docs/tara-knowledge/plans/<slug>.md` exists: show its Status and ask whether to revise it or create `<slug>-2`. Don't overwrite silently. A plan with Status `in-progress` or `done` is never rewritten; propose a new plan.

## 3. Explore

Read what the feature touches, following the architecture and real paths in `project.md`:
- the closest existing feature (to copy its structure), the files that will change, their tests, routing/DI registration, models, and the state layer;
- stop exploring once you can name every file to create or change. Keep it under ~25 files read.

## 4. Write the plan

Write `docs/tara-knowledge/plans/<slug>.md` in exactly this format:

```markdown
# <Feature>
Status: draft
## Context
- <3–5 bullets: files read and what matters in them, with real paths>
- Learnings applied: <entry date · lesson → how this plan follows it>, or "none relevant"
## Phases
- [ ] Phase 1 — <goal>
  - Files: <paths to create/change>
  - Acceptance: <how we know it's done: a test name, an analyze/test command passing, or an observable behavior>
- [ ] Phase 2 — <goal>
  - Files:
  - Acceptance:
## Risks
- <what could break, platform gotchas, migration/data concerns>
## Decisions
- <choices made and why, including any assumption the user should confirm>
```

Rules for phases:
- 2–6 phases, each small enough to finish and verify on its own (roughly ≤ 6 files), ordered so every phase leaves the app compiling and tests passing.
- Tests are part of the phase that adds the behavior, not a final "write tests" phase.
- Acceptance must be checkable by `/tara:execute`: name the tests to add or the commands from `project.md` that must pass. "Works well" is not acceptance.
- Follow the project's conventions, state library, and folder layout; never introduce a new library or pattern without listing it under Decisions as needing approval.
- Never plan edits to protected files (signing, env, generated code; regenerate instead).

## 5. Stop for approval

Show the plan summary (phases with goals, key risks, open decisions) and the file path, then **stop** and ask:
"Approve this plan? Reply 'approve' to mark it approved, or tell me what to change."

- On explicit approval in this conversation: change `Status: draft` to `Status: approved` (only that line) and say `Run /tara:execute <slug>`.
- On changes: edit the plan, keep `Status: draft`, and ask again.
- Never set `approved` without an explicit user approval.

## 6. Summary

End with at most 5 lines: plan path, number of phases, learnings applied (count), open decisions, next step.

`--quiet`: output only this one line, with no progress notes, findings, or summary before it (questions that need an answer still appear): `tara plan: docs/tara-knowledge/plans/<slug>.md · <n> phases · draft`
