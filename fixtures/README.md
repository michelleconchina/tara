# Testing tara

Fixture projects live in `fixtures/` locally and are **not committed** (see `.gitignore`).

## Fixtures

1. **Flutter**
   ```sh
   cd fixtures && flutter create fixture_flutter && cd fixture_flutter && git init -q && git add -A && git commit -qm init
   ```
2. **iOS SwiftUI.** In Xcode: File → New → Project → iOS App, Interface: SwiftUI, saved as `fixtures/fixture_ios`. Then `git init` and commit.
3. **Real project.** Any real app you own, e.g. a receipt calculator. Don't copy it here; point Claude Code at it in place.

To give `review` something to find, make a change on a branch after the initial commit. For example, add a `TextEditingController` that is never disposed, or a `print` of a token, or a force unwrap on decoded JSON.

## Running

Load the plugin from this repo without installing it:

```sh
cd fixtures/fixture_flutter
claude --plugin-dir /path/to/tara
```

Inside the session, run `/tara:review`, `/tara:review lib/`, or `/tara:review --quiet`. After editing the plugin, run `/reload-plugins`.

Validate the manifest from the plugin root: `claude plugin validate .`

## Acceptance per change

- [ ] `claude plugin validate .` passes.
- [ ] `review` runs on fixtures 1 and 2 and every finding matches `P1|P2|P3 · file:line · issue · fix`, or the output is `No issues`.
- [ ] `review --quiet` prints one line.
- [ ] Hooks fire: editing a `.dart` file reformats it; editing `.env` or `*.jks` is blocked with a reason.
- [ ] Hooks fail soft: editing a `.swift` file with `swiftformat` not installed causes no error.
- [ ] Phase 2+: `init` detects the stack correctly on all three fixtures.

## Hook smoke test without Claude

```sh
P=$PWD/fixtures/fixture_flutter
printf '{"tool_name":"Edit","cwd":"%s","tool_input":{"file_path":"%s/.env"}}' "$P" "$P" \
  | CLAUDE_PROJECT_DIR="$P" sh hooks/scripts/guard.sh; echo "exit=$?"   # expect exit=2
printf '{"tool_name":"Bash","cwd":"%s","tool_input":{"command":"git push --force"}}' "$P" \
  | CLAUDE_PROJECT_DIR="$P" sh hooks/scripts/guard.sh; echo "exit=$?"   # expect exit=2
```
