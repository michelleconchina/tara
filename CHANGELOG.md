# Changelog

## 0.9.1 — 2026-10-11

### Fixed
- `/tara:review` no longer prints progress notes ("Security reviewer finished…") while the reviewers run. `--quiet` now prints only its one result line, and a normal review prints only the final report.
  - Cause: the reviewer agents ran in the background, so each one that finished gave the main session a new turn, which it filled with a progress note. The four agents now set `background: false`. They still start together in one message and run in parallel, but `review` receives all their results in a single turn.

## 0.9.0 — 2026-10-11 (Phases 2–6)

All roadmap phases are built and pass the fixture smoke tests. The version stays below 1.0 until the real-use criteria in SPEC §13 are met: Phase 4 "used on one real task each" and Phase 6 "after 2 weeks of real use".

### Added
- **Phase 2:**
  - `/tara:init` with detect → confirm → write, monorepo selection, `--refresh` field diff, and the plans commit-or-ignore choice.
  - `scripts/detect.sh`: a read-only POSIX scanner. It reports facts only (stack per §6 order, app roots, deps, state usage counts, UI framework, folders, flavors/schemes, services, tests, tooling, protected candidates, existing knowledge, git), so `init` can run on a light model without guessing.
- **Phase 3:**
  - `/tara:plan`: §5.3 format, must cite the learnings it applies, approval gate.
  - `/tara:execute`: phase by phase; `Done:`/`Blocked:` evidence lines in the plan let a later session resume.
  - `/tara:test`: diff-first; 3 fix attempts with Opus escalation through a subagent; manual checklist when there are no tests; evidenced learnings on approval.
  - `/tara:learn`: add with evidence check, or `--prune` with a diff.
- **Phase 4:**
  - `/tara:build`: never touches signing.
  - `/tara:health`: read-only.
  - `/tara:pr`: separate approvals for commit, push, and PR; stages named files only.
  - `/tara:debug`: reproduce → failing test → fix → verify.
- **Phase 5:**
  - Skills `android-kotlin` (SKILL, compose, coroutines, testing), `react-native` (SKILL, performance, testing), and `kmp` (SKILL).
  - Detection for Android, RN/Expo, and KMP in `detect.sh` and `init`.
  - Reviewer agents load the skill matching the stack, including platform skills for native code inside cross-platform apps.
- **Phase 6:**
  - `/tara:release`: approvals for edits, commit, tag, and push.
  - `/tara:test-gen`: riskiest first; reports suspected bugs instead of bending tests.
  - `/tara:deps`: one at a time, reverts upgrades that fail.
  - `/tara:store-check`: read-only.
  - `/tara:distribute`: prefers the existing fastlane/CI/EAS pipeline; explicit yes before upload.

### Changed
- `/tara:review` now stops with "Run /tara:init first" when `project.md` is missing (SPEC §7.1). This ends the Phase 1 interim deviation.
- Every command pre-approves reading the plugin's own skill files (`Read(/${CLAUDE_PLUGIN_ROOT}/skills/**)`). Without this, reads outside the project prompted for permission, or were denied in headless runs.
- `--quiet` wording is the same in every command: one result line only. Commands with approval gates still ask their questions.
- `/tara:health` checks the JDK the build actually uses (`flutter doctor -v`, `JAVA_HOME`, Android Studio's JBR) instead of `java` on `PATH`, which gave a false warning.

### Distribution
- The repository is public and doubles as a marketplace (`.claude-plugin/marketplace.json`, plugin source `"."`). Install with `/plugin install tara --marketplace michelleconchina/tara`.
- `displayName` "Tara: Mobile Workflow", plus `homepage`, `repository`, and `license` in `plugin.json`. MIT `LICENSE` added.

### Fixed (from /code-review)
- **Monorepos:** commands now use the nearest `docs/tara-knowledge/project.md` from the current directory upward, and ask which app when they're run above several. `review` limits its scope to that app. The guard applies the Protected files of the app containing the edited file.
- **`detect.sh` bugs:**
  - A trailing `--root` hung; it now errors.
  - pubspecs indented with 4 spaces now parse.
  - Separate apps under a workspace root are no longer dropped. Only platform folders such as `ios/` and `android/` count as nested.
  - Native iOS and Android dependencies now feed services detection.
  - The native-module scan includes `.java`, `.m`, `.mm` and `.js`.
  - One `grep -r` per check instead of one per file, about 4× faster.
- **Skill folders:** commands map each stack to its folder. They no longer look for `kmp/testing.md`, which doesn't exist.
- **`init`:** the plans ignore rule goes in the app root's `.gitignore`.
- **`pr`:** reads `git diff HEAD` plus untracked files; staged changes were missed before.

### Differences from SPEC (to review)
- `scripts/detect.sh` is new; SPEC §4 doesn't list it.
- Fixtures must live **outside** the plugin folder. Claude Code blocks writes under a loaded plugin's directory as sensitive, so `fixtures/` now holds only the README, and the projects go in `../tara-fixtures/`.
- `kmp` has no separate `testing.md`; testing is a section of its `SKILL.md`.
- `test`'s "default → strong on 2nd failure" is done by delegating attempts 2–3 to an Opus subagent, because a command can't switch its own model mid-run.

## 0.1.0 — 2026-10-11 (Phase 1: skeleton)

### Added
- Plugin manifest (`.claude-plugin/plugin.json`). `claude plugin validate` passes.
- `/tara:review`: diff-first scope, parallel reviewer agents, merged P1/P2/P3 report with top 3 fixes, and `--quiet`.
- Agents: `perf-reviewer`, `security-reviewer`, `state-reviewer`, `ui-reviewer` (read-only: `Read, Grep, Glob`).
- Skills: `flutter` (SKILL, state, performance, testing) and `ios-swift` (SKILL, concurrency, swiftui, uikit, testing).
- Hooks: `format.sh` (PostToolUse, Edit|Write) and `guard.sh` (PreToolUse, Edit|Write|Bash).
- `fixtures/README.md` and `SPEC.md`.

### Differences from SPEC (docs win, §4)
Checked against code.claude.com/docs (plugins reference, plugin components, hooks, skills) using Claude Code 2.1.296.

- **`commands/` is the older format.** The docs now recommend writing new commands as skills. `commands/` is still fully supported, uses the same frontmatter, and gives the same `/tara:<name>` invocation, so it's kept as SPEC §4 specifies. Revisit if a future release deprecates it.
- **Skill frontmatter.** Skills use `paths` to limit automatic loading to platform files (the SPEC §9 "triggers on that platform's files only" requirement) and `user-invocable: false` so they don't appear as `/tara:flutter` slash commands.
- **Hook matchers.** `"Edit|Write"` is an exact-name list, not a regex. `MultiEdit` isn't in the current hook docs, so it isn't matched.
- **Hook blocking.** `guard.sh` blocks with exit code 2 and the reason on stderr (exit 1 doesn't block).
- **`hooks/hooks.json`** needs the top-level `"hooks"` wrapper. Scripts live in `hooks/scripts/` as the SPEC says. The docs' `scripts/` folder is only a convention.
- **Agent frontmatter.** Plugin agents ignore `permissionMode`, `hooks`, and `mcpServers`, so the agents use only `name`, `description`, `tools`, and `model: inherit`.

### Deliberate deviations from SPEC (to review)
- **`review` without `project.md`.** SPEC §7.1 says to stop with "Run /tara:init first", but Phase 1 acceptance needs `/tara:review` to work before `init` exists. Until then, `review` detects the stack read-only for that run using the §6 order, writes nothing, and recommends `/tara:init`. Decide in Phase 2 whether to keep this.
- **`guard.sh` edge cases:**
  - Env templates `.env.example`, `.env.sample`, `.env.template`, and `.env.dist` are not protected.
  - `git push --force-with-lease` is allowed. Only `--force`, `-f`, and `+refspec` are blocked.
  - `rm -rf` with an unexpandable variable target (e.g. `"$DIR"`) is blocked, because it can't be verified.
  - The commit check blocks staged signing/env files (`*.jks`, `*.keystore`, `*.p12`, `*.mobileprovision`, `.env*`) plus secret-looking content. Firebase config files and `AIza…` keys are not flagged, since they're public by design and usually committed.
  - A line containing `tara:allow-secret` is exempt from the secret scan.
- **`format.sh`** also handles `.kts` and `.jsx`, prefers the project's `node_modules/.bin/prettier`, and only formats files inside the project.
