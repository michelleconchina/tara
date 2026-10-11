# Changelog

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
