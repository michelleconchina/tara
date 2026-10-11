#!/bin/sh
# tara format — PostToolUse hook for Edit|Write.
# Formats only the edited file, picking the formatter by extension.
# Fail soft: unknown extension, missing formatter, or formatter error -> exit 0, no output.

input=$(cat)

if command -v jq >/dev/null 2>&1; then
  file=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty' 2>/dev/null)
else
  file=$(printf '%s' "$input" | sed -n 's/.*"file_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n 1)
fi
[ -n "$file" ] || exit 0

project_dir=${CLAUDE_PROJECT_DIR:-$(pwd)}
case "$file" in
  /*) ;;
  *) file="$project_dir/$file" ;;
esac
[ -f "$file" ] || exit 0

# Only format files inside the project.
case "$file" in
  "$project_dir"/*) ;;
  *) exit 0 ;;
esac

# Run from the project root so formatters pick up project config.
cd "$project_dir" 2>/dev/null || exit 0

run() {
  command -v "$1" >/dev/null 2>&1 || exit 0
  "$@" >/dev/null 2>&1
  exit 0
}

case "$file" in
  *.dart) run dart format "$file" ;;
  *.swift) run swiftformat --quiet "$file" ;;
  *.kt|*.kts) run ktlint --format "$file" ;;
  *.ts|*.tsx|*.js|*.jsx)
    if [ -x node_modules/.bin/prettier ]; then
      node_modules/.bin/prettier --write "$file" >/dev/null 2>&1
      exit 0
    fi
    run prettier --write "$file"
    ;;
esac

exit 0
