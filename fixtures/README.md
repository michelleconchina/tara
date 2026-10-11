# Testing tara

Fixture projects are created locally and never committed. **Keep them outside the plugin folder**, e.g. in `../tara-fixtures/`. Claude Code treats files under a loaded plugin's directory as sensitive, so `init`/`execute` can't write to fixtures placed inside `tara/`.

## Fixtures

```sh
mkdir -p ../tara-fixtures && cd ../tara-fixtures
```

1. **Flutter:** `flutter create fixture_flutter && cd fixture_flutter && git init -q && git add -A && git commit -qm init`
2. **iOS SwiftUI:** Xcode → File → New → Project → iOS App (SwiftUI), saved as `fixture_ios`; `git init` + commit.
3. **Real project:** any app you own (e.g. a receipt calculator). Use it in place; don't copy it.
4. **Phase 5 samples (optional):** small Android (Compose), React Native, and KMP projects. A buildable app isn't needed for `init`/`review`; the right files are: `settings.gradle.kts` + `app/build.gradle.kts` + `AndroidManifest.xml`; `package.json` with `react-native`; a Gradle module applying `kotlin("multiplatform")`.

To give `review` something to find, branch after the initial commit and add flawed code: an undisposed controller, a logged token, a force unwrap on JSON, `GlobalScope`, a hardcoded secret.

## Running

```sh
cd ../tara-fixtures/fixture_flutter
claude --plugin-dir ../../tara
```

Headless (for scripted checks), confirming init by resuming its session:

```sh
sid=$(claude -p "/tara:init --quiet" --plugin-dir ../../tara --output-format json | jq -r .session_id)
claude -p "Confirmed. Commit plans." --resume "$sid" --plugin-dir ../../tara --permission-mode acceptEdits
```

## Acceptance per change

- [ ] `claude plugin validate .` passes.
- [ ] `sh scripts/detect.sh <fixture>` reports the right stack for each fixture; a folder with several apps lists them.
- [ ] `init` detects correctly on fixtures 1–3, shows findings, asks, and writes nothing before confirmation.
- [ ] `review` returns findings as `P1|P2|P3 · file:line · issue · fix`, or `No issues`; `--quiet` prints one line.
- [ ] `plan` → approve → `execute` in a fresh session resumes from the plan file; `test` proposes learnings only with evidence; a second `plan` cites them.
- [ ] Hooks fire: editing `.dart` reformats it; editing `.env`/`*.jks` is blocked with a reason; a missing formatter causes no error.
- [ ] Gated commands (`pr`, `release`, `distribute`, `deps`) stop at their approval questions.

## Hook smoke test without Claude

```sh
P=$PWD/../tara-fixtures/fixture_flutter
printf '{"tool_name":"Edit","cwd":"%s","tool_input":{"file_path":"%s/.env"}}' "$P" "$P" \
  | CLAUDE_PROJECT_DIR="$P" sh hooks/scripts/guard.sh; echo "exit=$?"   # expect exit=2
printf '{"tool_name":"Bash","cwd":"%s","tool_input":{"command":"git push --force"}}' "$P" \
  | CLAUDE_PROJECT_DIR="$P" sh hooks/scripts/guard.sh; echo "exit=$?"   # expect exit=2
```
