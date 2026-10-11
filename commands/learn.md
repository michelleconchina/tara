---
description: Add one evidenced lesson to docs/tara-knowledge/learnings.md, or prune and consolidate the file
argument-hint: "<lesson> | --prune [--quiet]"
model: haiku
allowed-tools: Read, Read(/${CLAUDE_PLUGIN_ROOT}/skills/**), Grep, Glob, Bash(git cat-file *), Bash(git log *)
---

# /tara:learn

Arguments: `$ARGUMENTS`

Precedence when instructions conflict: (1) the user's current message, (2) project `CLAUDE.md` + `docs/tara-knowledge/project.md`, (3) `docs/tara-knowledge/learnings.md`, (4) plugin skills.

Learnings are verified knowledge. No entry without evidence.

## 1. Load knowledge

- Find the app root: the nearest directory, from the current directory up to the git top level, that contains `docs/tara-knowledge/project.md`. All `docs/tara-knowledge/` paths below are relative to it. If none is found but app roots below the current directory have one (monorepo), list them and ask which app to use. If there is none at all: print `Run /tara:init first` and stop.
- Read that `project.md`.
- Read `docs/tara-knowledge/learnings.md`. If it's missing, create it with the header that `/tara:init` uses:

```markdown
<!-- tara-schema: 1 -->
# Learnings
<!-- One line per lesson: - YYYY-MM-DD · [area] · lesson · evidence: <test / command / commit> -->
<!-- Added by /tara:test and /tara:learn after verification. No entry without evidence. Prune with /tara:learn --prune. -->
```

## 2. Add a lesson: `/tara:learn <lesson>`

1. **Evidence.** If the arguments don't include it, ask: "What proves this? A test name, a command that passed or failed, or a commit." Don't write until you have it.
2. **Check the evidence lightly.** A commit hash should exist (`git cat-file -e <hash>`). A test name should be findable with Grep. A file path should exist. If it doesn't check out, say so and ask again.
3. **Area.** Pick a short tag from the lesson (`[state]`, `[ios]`, `[build]`, `[testing]`, `[firebase]`, a feature name). Reuse an existing tag when one fits.
4. **One line.** Rewrite the lesson as one specific, actionable line (≤ 160 chars). Keep the user's meaning.
5. **Duplicates.** If an existing entry says the same thing, show it and offer to update that entry instead of adding one.
6. Append: `- <today YYYY-MM-DD> · [area] · <lesson> · evidence: <evidence>`. Then show the line written.

## 3. Prune: `/tara:learn --prune`

1. Find:
   - **Duplicates or overlaps:** merge them into one line, keeping the newest date and all evidence (`evidence: a; b`).
   - **Stale:** entries whose evidence or referenced file/symbol no longer exists (check with Glob/Grep), or that `project.md` now contradicts.
   - **Superseded:** an older entry contradicted by a newer one; keep the newer.
   - **Malformed:** lines without evidence. Flag them; don't silently delete.
   - **Over ~100 entries:** propose dropping the least useful (generic, superseded) until under 100.
2. Show the proposed result as a diff (removed lines `-`, added lines `+`), with a one-line reason per change.
3. Ask: "Apply these changes? (all / pick / none)". Write only what was approved. Keep the header and sort entries by date (oldest first).

## 4. Summary

End with at most 5 lines: what was added/merged/removed, total entries now, next step if any.

`--quiet`: output only this one line, with no progress notes, findings, or summary before it (questions that need an answer still appear): `tara learn: added 1 · <total> entries` or `tara learn: pruned <removed> · merged <merged> · <total> entries`
