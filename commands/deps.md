---
description: Upgrade dependencies one at a time. Check breaking changes, migrate, run analyze and tests, and revert any upgrade that fails
argument-hint: "[package] [--major] [--quiet]"
allowed-tools: Read, Read(/${CLAUDE_PLUGIN_ROOT}/skills/**), Grep, Glob, WebFetch, Bash(git status *), Bash(git diff *)
---

# /tara:deps

Arguments: `$ARGUMENTS`

Precedence when instructions conflict: (1) the user's current message, (2) project `CLAUDE.md` + `docs/tara-knowledge/project.md`, (3) `docs/tara-knowledge/learnings.md`, (4) plugin skills.

**One dependency at a time.** Each upgrade is verified on its own before the next starts. Never commit.

## 1. Load knowledge and check state

- Find the app root: the nearest directory, from the current directory up to the git top level, that contains `docs/tara-knowledge/project.md`. All `docs/tara-knowledge/` paths below are relative to it. If none is found but app roots below the current directory have one (monorepo), list them and ask which app to use. If there is none at all: print `Run /tara:init first` and stop.
- Read that `project.md`.
- Read `docs/tara-knowledge/learnings.md`; apply `[deps]`/`[build]` entries (e.g. known pins).
- The working tree must be clean (so each upgrade can be reverted cleanly). If it isn't, list the changes and stop.
- Run the analyze and test commands once to get a baseline. If the baseline fails, stop: upgrades can't be verified on a red build.

## 2. List candidates

Use the stack's listing: `flutter pub outdated` / `dart pub outdated`, `npm|yarn|pnpm outdated` (Expo: `npx expo install --check`), `pod outdated`, Gradle version catalog vs latest (only via an existing task such as `dependencyUpdates`; otherwise check the catalog entries one by one).

- With a `package` argument: only that one.
- Otherwise: direct dependencies only (not transitive), minor/patch first. **Major** upgrades only with `--major` or explicit approval per package.
- Expo/React Native: SDK-coupled packages move with the Expo SDK / RN version; upgrade those through the SDK upgrade path, not individually. Say so.
- Show the list (current → target, major?, why it matters) and ask which to do, in what order.

## 3. For each approved dependency

1. **Breaking changes:** read the changelog/release notes between current and target (pub.dev changelog, GitHub releases, the library's migration guide; use WebFetch). Summarize what affects this project and grep for affected APIs.
2. **Upgrade only this one:** edit the version constraint, then run the package manager's install/get so the lockfile updates (`flutter pub get`, `npm install`, `pod install`, Gradle sync via the build).
3. **Migrate** code for the breaking changes found.
4. **Verify:** the analyze command, the test command, and for native-heavy upgrades (Firebase, camera, maps, plugins with native code) the debug build for each platform.
5. **Pass:** record `<pkg> current → target ✓ (evidence: analyze clean, n tests passed, build ok)`. Continue.
6. **Fail:** try one targeted fix if the cause is clear from the error and the migration notes. If it still fails, **revert this dependency's changes** (restore the manifest/lockfile and any migrated files with `git checkout -- <files>` / `git restore`, after showing what will be reverted), record `✗ <reason>`, and move to the next one.

## 4. Learnings

For non-obvious findings (a required pin, a migration gotcha), propose one learning each:
`- <YYYY-MM-DD> · [deps] · <lesson> · evidence: <command/test>`. Ask before saving.

## 5. Summary

End with at most 5 lines: upgraded ✓ list, failed/reverted ✗ list with reasons, skipped majors, final verification, next step (review the diff, then `/tara:pr`).

`--quiet`: still ask the selection questions; skip the closing summary and end with only: `tara deps: ✓ <n> upgraded · ✗ <m> reverted · <k> skipped`
