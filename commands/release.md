---
description: Bump the app version in every platform file, update the changelog, and tag, with approval before commit and tag
argument-hint: "<version | major | minor | patch> [--build <n>] [--quiet]"
allowed-tools: Read, Read(/${CLAUDE_PLUGIN_ROOT}/skills/**), Grep, Glob, Bash(git status *), Bash(git log *), Bash(git describe *), Bash(git tag --list*), Bash(git diff *)
---

# /tara:release

Arguments: `$ARGUMENTS`

Precedence when instructions conflict: (1) the user's current message, (2) project `CLAUDE.md` + `docs/tara-knowledge/project.md`, (3) `docs/tara-knowledge/learnings.md`, (4) plugin skills.

Human gates: version edits are shown before writing; **commit and tag each need explicit approval**; pushing the tag is a third approval. Never build for distribution, sign, or upload here (use `/tara:build --release`, then `/tara:distribute`).

## 1. Load knowledge and check state

- Find the app root: the nearest directory, from the current directory up to the git top level, that contains `docs/tara-knowledge/project.md`. All `docs/tara-knowledge/` paths below are relative to it. If none is found but app roots below the current directory have one (monorepo), list them and ask which app to use. If there is none at all: print `Run /tara:init first` and stop.
- Read that `project.md`.
- Read `docs/tara-knowledge/learnings.md`; apply `[release]`/`[build]` entries.
- Working tree must be clean except for files this command will change. Otherwise list the changes and stop.
- Warn if not on the base/release branch the project uses (check recent tags' branches and CI config).

## 2. Find every version source

Read the current version from each place that applies; all must agree (report mismatches):

| Stack | Marketing version | Build number |
|---|---|---|
| flutter | `pubspec.yaml` `version: X.Y.Z+N` (the native projects read it via `FLUTTER_BUILD_NAME/NUMBER` and `flutter.versionName/Code`; don't edit them separately unless they're hardcoded) | `+N` |
| ios | `MARKETING_VERSION` in `project.pbxproj`/`.xcconfig` (or `CFBundleShortVersionString` in Info.plist if hardcoded) | `CURRENT_PROJECT_VERSION` (or `CFBundleVersion`) |
| android | `versionName` in the app module's `build.gradle(.kts)` or version catalog | `versionCode` |
| react-native | `package.json` `version` + iOS and Android native values as above | native build numbers |
| expo | `app.json`/`app.config.*` `expo.version` (+ `package.json` if kept in sync) | `ios.buildNumber`, `android.versionCode` (unless EAS remote versioning is configured, in which case don't touch them) |
| kmp | Android app module + iOS app as above | as above |

## 3. Compute the new version

- `major|minor|patch`: bump semver from the current version. An explicit `X.Y.Z` must be greater than the current one.
- Build number: `--build <n>` if given, else current + 1. It must be greater than the current one (stores reject reuse).
- Changelog: commits since the last tag (`git describe --tags --abbrev=0`, `git log <tag>..HEAD --oneline`), grouped as Features / Fixes / Other (use Conventional Commit prefixes if present). Drop merge noise and chore-only commits unless nothing else exists.

## 4. Show, then write

Show: the old and new version/build per file (with exact lines), and the new `CHANGELOG.md` section (`## X.Y.Z (YYYY-MM-DD)`). Create `CHANGELOG.md` if missing, or match the existing format. Ask: **"Apply these version changes?"**

On yes:
- Edit only the version lines. In `project.pbxproj`, change only `MARKETING_VERSION`/`CURRENT_PROJECT_VERSION` values (every build configuration of the app targets, and extension targets that must match). Touch nothing else in that file.
- Run the analyze command, then the debug build command for one platform (from `project.md`), as a sanity check that the version formats parse. Report results.
- Show `git diff --stat`.

## 5. Commit and tag (separate approvals)

1. Ask: **"Commit as `chore(release): X.Y.Z`?"** (match the repo's commit style). On yes, stage only the changed version files and the changelog, then commit.
2. Ask: **"Create annotated tag `vX.Y.Z`?"** (match existing tag format, e.g. with or without `v`). On yes: `git tag -a vX.Y.Z -m "Release X.Y.Z"`.
3. Ask: **"Push the commit and tag to origin?"** On yes: `git push origin <branch>` and `git push origin vX.Y.Z`. Never `--force`, never `--tags` (it pushes every local tag).

Stop at any "no".

## 6. Summary

End with at most 5 lines: version old → new, build number, files changed, commit/tag/push status, next step (`/tara:store-check`, `/tara:build --release`, `/tara:distribute`).

`--quiet`: still show the edits and ask the approval questions; skip the closing summary and end with only: `tara release: X.Y.Z+N · committed <hash|no> · tagged <vX.Y.Z|no> · pushed <yes|no>`
