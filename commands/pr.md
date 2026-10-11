---
description: Draft a commit message and PR description from the diff, show them, and only commit, push, or open the PR after explicit approval
argument-hint: "[--draft] [--quiet]"
allowed-tools: Read, Read(/${CLAUDE_PLUGIN_ROOT}/skills/**), Grep, Glob, Bash(git status *), Bash(git diff *), Bash(git log *), Bash(git branch *), Bash(git rev-parse *), Bash(git symbolic-ref *), Bash(git merge-base *), Bash(git remote *)
---

# /tara:pr

Arguments: `$ARGUMENTS`

Precedence when instructions conflict: (1) the user's current message, (2) project `CLAUDE.md` + `docs/tara-knowledge/project.md`, (3) `docs/tara-knowledge/learnings.md`, (4) plugin skills.

Human gates: **show before committing or pushing.** Committing, pushing, and opening the PR are three separate approvals. Never force-push, never amend or rebase existing commits, never skip hooks (`--no-verify`).

## 1. Load knowledge

- Find the app root: the nearest directory, from the current directory up to the git top level, that contains `docs/tara-knowledge/project.md`. All `docs/tara-knowledge/` paths below are relative to it. If none is found but app roots below the current directory have one (monorepo), list them and ask which app to use. If there is none at all: print `Run /tara:init first` and stop.
- Read that `project.md`.
- Read `docs/tara-knowledge/learnings.md` if present.

## 2. Gather

- Base branch: `git symbolic-ref --short refs/remotes/origin/HEAD`, else `main`/`master`/`develop`.
- `git status`, `git diff HEAD --stat` (staged + unstaged vs the last commit), untracked files (`git ls-files --others --exclude-standard`; read the ones that belong to this change), commits on this branch since the merge base (`git log --oneline <mb>..HEAD`), and the full diff of the changed files (`git diff HEAD`).
- Commit style: read `git log --oneline -20` on the base branch and match it (Conventional Commits, ticket prefixes, tense, casing). Default to Conventional Commits if there is no clear style.
- Related plan: any `docs/tara-knowledge/plans/*.md` whose Files overlap the diff. Use its goal, phases, and `Done:` evidence lines.
- Verification evidence: from the plan's `Done:` lines or results of `/tara:test` in this conversation. If there's none, say "not verified in this session" and offer to run `/tara:test` (and `/tara:review`) first. Don't invent results.

## 3. Check before proposing

- **Branch:** if on the base branch, propose a branch name (`feat/<slug>`, `fix/<slug>`) and ask before creating it.
- **What to stage:** list the files to include. Exclude, and point out, files that look unrelated, build output, local config (`.env*`, `local.properties`, IDE files), protected files from `project.md`, and stray debug code. Never use `git add -A` / `git add .`; stage named files.
- **Secrets:** if the diff adds anything that looks like a credential, stop and point to the line. The guard hook would block the commit anyway.

## 4. Draft and show

Show all of this, then stop:

1. **Files to commit** (and files left out, with reasons).
2. **Commit message(s).** Usually one; split only if the diff has clearly separate concerns. Subject ≤ 72 chars, body says *why*.
3. **PR title + description:**

```markdown
## Summary
<1–3 sentences: what and why>
## Changes
- <grouped by area, with key files>
## Testing
- <commands run + results, or "not verified in this session">
- Manual: <steps for UI changes>
## Screenshots
<!-- required for UI changes: before / after, light & dark -->
## Risks / notes
- <migrations, flags, platform-specific concerns, follow-ups>
Plan: docs/tara-knowledge/plans/<slug>.md
```

Then ask: **"Commit these files with this message?"**

## 5. On approval, step by step

1. **Commit:** stage the named files, then commit. Show `git log -1 --stat`.
2. Ask: **"Push `<branch>` to origin?"** On yes: `git push -u origin <branch>` (never `--force`).
3. Ask: **"Open the PR?"** On yes: if `gh` is installed and authenticated, `gh pr create --base <base> --title … --body-file <tmpfile>` (add `--draft` if requested) and print the URL. Otherwise print the title and description ready to paste.

Stop at any "no" and leave the rest to the user.

## 6. Summary

End with at most 5 lines: branch, commit hash (or "not committed"), pushed yes/no, PR URL (or "not opened"), anything excluded.

`--quiet`: still show the draft and ask the approval questions; skip the closing summary and end with only: `tara pr: <committed abc1234 | not committed> · <pushed | not pushed> · <PR url | no PR>`
