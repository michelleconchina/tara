#!/bin/sh
# tara guard — PreToolUse hook for Edit|Write|Bash.
# Blocks (exit 2, reason on stderr):
#   - Edit/Write of protected files (signing, env, Firebase config, project.md "Protected files")
#   - rm -rf whose target is outside the project (or can't be verified)
#   - git push --force / -f / +refspec (--force-with-lease is allowed)
#   - git commit whose changes add a likely secret or a signing/env file
# Anything it can't parse is allowed (exit 0). Mark a deliberate line with `tara:allow-secret`.

input=$(cat)

has_jq=0
command -v jq >/dev/null 2>&1 && has_jq=1

json_get() { # $1 = jq path, e.g. .tool_input.file_path
  if [ "$has_jq" = 1 ]; then
    printf '%s' "$input" | jq -r "$1 // empty" 2>/dev/null
  else
    key=${1##*.}
    printf '%s' "$input" | sed -n "s/.*\"$key\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p" | head -n 1
  fi
}

block() {
  printf 'tara guard: blocked — %s\n' "$1" >&2
  exit 2
}

physical() { # resolve symlinks for an existing directory, else echo as-is
  (cd "$1" 2>/dev/null && pwd -P) || printf '%s\n' "$1"
}

normalize() { # lexical cleanup of an absolute path: //, ., ..
  printf '%s\n' "$1" | awk -F/ '{
    n = 0
    for (i = 1; i <= NF; i++) {
      s = $i
      if (s == "" || s == ".") continue
      if (s == "..") { if (n > 0) n--; continue }
      st[++n] = s
    }
    out = ""
    for (i = 1; i <= n; i++) out = out "/" st[i]
    if (out == "") out = "/"
    print out
  }'
}

tool=$(json_get .tool_name)
cwd=$(json_get .cwd)
[ -n "$cwd" ] || cwd=$(pwd)
project_dir=${CLAUDE_PROJECT_DIR:-$cwd}
project_dir=$(physical "$project_dir")
cwd=$(physical "$cwd")

# ---------- protected files ----------

knowledge_root() { # $1 = absolute path; nearest dir (up to project_dir) holding docs/tara-knowledge/project.md
  d=${1%/*}
  while :; do
    [ -f "$d/docs/tara-knowledge/project.md" ] && { echo "$d"; return 0; }
    case "$d" in "$project_dir"|/|"") break ;; esac
    d=${d%/*}
    [ -n "$d" ] || d=/
  done
  echo "$project_dir"
}

project_patterns() { # $1 = app root; "Protected files" bullets from its project.md
  pm="$1/docs/tara-knowledge/project.md"
  [ -f "$pm" ] || return 0
  awk '
    /^#+[[:space:]]+Protected files/ { on = 1; next }
    /^#/ { on = 0 }
    on && /^[[:space:]]*[-*][[:space:]]+/ {
      sub(/^[[:space:]]*[-*][[:space:]]+/, "")
      gsub(/`/, "")
      if ($1 != "" && substr($1, 1, 1) != "(") print $1
    }
  ' "$pm"
}

protected_reason() { # $1 = path; prints reason if protected
  p=$1
  case "$p" in /*) ;; *) p="$cwd/$p" ;; esac
  base=${p##*/}
  case "$base" in
    .env.example|.env.sample|.env.template|.env.dist) ;;
    *.jks|*.keystore|*.p12|*.mobileprovision|.env|.env*|google-services.json|GoogleService-Info.plist)
      echo "$base is a protected file (signing, secrets, or service config)"
      return 0 ;;
  esac
  p=$(normalize "$p")
  kr=$(knowledge_root "$p")
  rel=${p#"$kr"/}   # patterns in project.md are relative to the app root that holds it
  set -f  # patterns may contain globs; don't expand them against cwd
  for pat in $(project_patterns "$kr"); do
    case "$pat" in */) pat="${pat}*" ;; esac
    # shellcheck disable=SC2254
    case "$rel" in $pat) echo "$rel matches Protected files in project.md ($pat)"; return 0 ;; esac
    case "$pat" in
      */*) ;;
      *) case "$base" in $pat) echo "$base matches Protected files in project.md ($pat)"; return 0 ;; esac ;;
    esac
  done
  set +f
  return 1
}

if [ "$tool" = Edit ] || [ "$tool" = Write ]; then
  file=$(json_get .tool_input.file_path)
  [ -n "$file" ] || exit 0
  if reason=$(protected_reason "$file"); then
    block "$reason. Edit it yourself, or remove it from Protected files in docs/tara-knowledge/project.md."
  fi
  exit 0
fi

[ "$tool" = Bash ] || exit 0

if [ "$has_jq" = 1 ]; then
  cmd=$(json_get .tool_input.command)
else
  # extract the JSON string value of "command", then unescape \" \\ and \n
  cmd=$(printf '%s' "$input" | tr '\n' ' ' \
    | sed -nE 's/.*"command"[[:space:]]*:[[:space:]]*"(([^"\\]|\\.)*)".*/\1/p' \
    | sed -e 's/\\"/"/g' -e 's/\\n/ ; /g' -e 's/\\\\/\\/g')
fi
[ -n "$cmd" ] || exit 0

# ---------- rm -rf ----------

check_rm_target() { # $1 = target word; prints reason if outside/unverifiable
  t=$(printf '%s' "$1" | tr -d "\"'")
  [ -n "$t" ] || return 1
  case "$t" in
    "~"|"~/"*) t="$HOME${t#\~}" ;;
    '$HOME'|'$HOME/'*) t="$HOME${t#\$HOME}" ;;
    '${HOME}'|'${HOME}/'*) t="$HOME${t#\$\{HOME\}}" ;;
    '$PWD'|'$PWD/'*) t="$cwd${t#\$PWD}" ;;
    '$CLAUDE_PROJECT_DIR'|'$CLAUDE_PROJECT_DIR/'*) t="$project_dir${t#\$CLAUDE_PROJECT_DIR}" ;;
  esac
  case "$t" in
    *'$'*|*'`'*) echo "rm -rf target '$1' can't be verified (variable or substitution)"; return 0 ;;
    "~"*) echo "rm -rf target '$1' is outside the project"; return 0 ;;
  esac
  case "$t" in /*) ;; *) t="$rcwd/$t" ;; esac
  t=$(normalize "$t")
  parent=${t%/*}
  [ -n "$parent" ] || parent=/
  [ -d "$parent" ] && t="$(physical "$parent")/${t##*/}" && t=$(normalize "$t")
  case "$t" in
    "$project_dir"/?*) return 1 ;;
    "$project_dir") echo "rm -rf target '$1' is the project root"; return 0 ;;
  esac
  echo "rm -rf target '$1' resolves to $t, outside the project ($project_dir)"
  return 0
}

# ---------- git ----------

secret_file_reason() { # signing / env files that must never be committed
  base=${1##*/}
  case "$base" in
    .env.example|.env.sample|.env.template|.env.dist) return 1 ;;
    *.jks|*.keystore|*.p12|*.mobileprovision|.env|.env.*) echo "commit would include $1 (signing or env file)"; return 0 ;;
  esac
  return 1
}

secret_kind() { # stdin = added lines; prints label of first likely secret
  data=$(grep -v 'tara:allow-secret')
  [ -n "$data" ] || return 1
  m() { printf '%s\n' "$data" | grep -Eq -e "$1"; }
  m '-----BEGIN ([A-Z]+ )?PRIVATE KEY-----' && { echo "private key"; return 0; }
  m 'AKIA[0-9A-Z]{16}' && { echo "AWS access key"; return 0; }
  m '(sk|rk)_live_[0-9A-Za-z]{16,}' && { echo "Stripe live key"; return 0; }
  m 'gh[pousr]_[A-Za-z0-9]{36,}|github_pat_[A-Za-z0-9_]{40,}' && { echo "GitHub token"; return 0; }
  m 'xox[abposr]-[A-Za-z0-9-]{10,}' && { echo "Slack token"; return 0; }
  m 'sk-(ant-|proj-)?[A-Za-z0-9_-]{32,}' && { echo "API secret key"; return 0; }
  printf '%s\n' "$data" | grep -Eiq -e \
    '(secret|passw(or)?d|api[_-]?key|access[_-]?token|auth[_-]?token|private[_-]?key|client[_-]?secret)["'"'"']?[[:space:]]*[:=]+[[:space:]]*["'"'"'][^"'"'"'[:space:]]{12,}["'"'"']' \
    && { echo "hardcoded credential"; return 0; }
  return 1
}

check_commit() { # $1 = git dir, $2 = include unstaged tracked (0/1), $3 = include untracked (0/1)
  gd=$1
  git -C "$gd" rev-parse --git-dir >/dev/null 2>&1 || return 1
  {
    git -C "$gd" diff --cached --name-only --diff-filter=ACMR 2>/dev/null | sed 's/^/S /'
    [ "$2" = 1 ] && git -C "$gd" diff --name-only --diff-filter=ACMR 2>/dev/null | sed 's/^/W /'
    [ "$3" = 1 ] && git -C "$gd" ls-files --others --exclude-standard 2>/dev/null | head -n 200 | sed 's/^/U /'
  } > "$tmp_list"
  while IFS= read -r line; do
    kind=${line%% *}
    name=${line#? }
    [ -n "$name" ] || continue
    if r=$(secret_file_reason "$name"); then echo "$r"; return 0; fi
    case "$kind" in
      S) added=$(git -C "$gd" diff --cached -U0 --no-color -- "$name" 2>/dev/null | grep '^+' | grep -v '^+++') ;;
      W) added=$(git -C "$gd" diff -U0 --no-color -- "$name" 2>/dev/null | grep '^+' | grep -v '^+++') ;;
      U)
        f="$gd/$name"
        [ -f "$f" ] || continue
        [ "$(wc -c < "$f")" -le 1048576 ] || continue
        grep -Iq . "$f" 2>/dev/null || continue
        added=$(cat "$f") ;;
    esac
    if k=$(printf '%s\n' "$added" | secret_kind); then
      echo "possible $k in $name. Remove it, or mark an intended line with 'tara:allow-secret'"
      return 0
    fi
  done < "$tmp_list"
  return 1
}

tmp_list=$(mktemp "${TMPDIR:-/tmp}/tara-guard.XXXXXX") || exit 0
trap 'rm -f "$tmp_list"' EXIT

# ---------- walk simple commands ----------

rcwd=$cwd
saw_add=0
segments=$(printf '%s\n' "$cmd" | tr ';&|()' '\n\n\n\n\n')

while IFS= read -r seg; do
  set -f
  # shellcheck disable=SC2086
  set -- $seg
  set +f
  while [ $# -gt 0 ]; do
    case "$1" in
      sudo|command|builtin|exec|nohup|time|*=*) shift ;;
      *) break ;;
    esac
  done
  [ $# -gt 0 ] || continue
  prog=${1##*/}
  shift

  case "$prog" in
    cd)
      d=$(printf '%s' "${1:-$HOME}" | tr -d "\"'")
      case "$d" in "~"*) d="$HOME${d#\~}" ;; esac
      case "$d" in /*) ;; *) d="$rcwd/$d" ;; esac
      rcwd=$(normalize "$d")
      ;;
    rm)
      rec=0; force=0; targets=""
      for a in "$@"; do
        case "$a" in
          --recursive) rec=1 ;;
          --force) force=1 ;;
          --*) ;;
          -*)
            case "$a" in *[rR]*) rec=1 ;; esac
            case "$a" in *f*) force=1 ;; esac ;;
          *) targets="$targets
$a" ;;
        esac
      done
      if [ "$rec" = 1 ] && [ "$force" = 1 ]; then
        old_ifs=$IFS
        IFS='
'
        for t in $targets; do
          if r=$(check_rm_target "$t"); then
            IFS=$old_ifs
            block "$r. Run it yourself with '! <command>' if intended."
          fi
        done
        IFS=$old_ifs
      fi
      ;;
    git)
      gd=$rcwd
      while [ $# -gt 0 ]; do
        case "$1" in
          -C) d=$(printf '%s' "$2" | tr -d "\"'"); case "$d" in /*) gd=$d ;; *) gd="$rcwd/$d" ;; esac; shift 2 ;;
          -c) shift 2 ;;
          -*) shift ;;
          *) break ;;
        esac
      done
      sub=${1:-}
      [ $# -gt 0 ] && shift
      case "$sub" in
        add) saw_add=1 ;;
        push)
          for a in "$@"; do
            case "$a" in
              --force-with-lease*|--force-if-includes) ;;
              --force) block "git push --force rewrites remote history. Use --force-with-lease, or push yourself." ;;
              --*) ;;
              -*f*) block "git push -f rewrites remote history. Use --force-with-lease, or push yourself." ;;
              +*) block "git push with a +refspec force-pushes. Push yourself if intended." ;;
            esac
          done
          ;;
        commit)
          all=0
          for a in "$@"; do
            case "$a" in
              --all) all=1 ;;
              --*) ;;
              -*a*) all=1 ;;
            esac
          done
          unstaged=$all
          [ "$saw_add" = 1 ] && unstaged=1
          if r=$(check_commit "$gd" "$unstaged" "$saw_add"); then
            block "$r"
          fi
          ;;
      esac
      ;;
  esac
done <<EOF
$segments
EOF

exit 0
