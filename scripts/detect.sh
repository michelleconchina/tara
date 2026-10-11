#!/bin/sh
# tara detect — read-only project scan used by /tara:init.
# Usage: detect.sh [path] [--root <app-root relative to path>]
# Prints facts as "key: value" lines under "## section" headers. Never writes anything.
# With several app roots and no --root, prints only the app list so init can ask.

target=.
root_override=""
while [ $# -gt 0 ]; do
  case "$1" in
    --root)
      [ $# -ge 2 ] || { echo "error: --root needs an app root path"; exit 1; }
      root_override=$2; shift 2 ;;
    *) target=$1; shift ;;
  esac
done

cd "$target" 2>/dev/null || { echo "error: cannot open $target"; exit 1; }
base=$(pwd -P)

PRUNE='-name node_modules -o -name Pods -o -name build -o -name .build -o -name .git -o -name .dart_tool -o -name DerivedData -o -name .gradle -o -name .fvm -o -name .symlinks -o -name vendor -o -name ephemeral -o -name .idea -o -name Carthage -o -name .expo -o -name .next'

# ffind <dir> <maxdepth> <find predicates...>  (prunes dependency/build dirs)
ffind() {
  d=$1; md=$2; shift 2
  # shellcheck disable=SC2086
  find "$d" -maxdepth "$md" \( -type d \( $PRUNE \) -prune \) -o \( "$@" \) -print 2>/dev/null
}

count() { d=$1; shift; ffind "$d" 12 "$@" 2>/dev/null | wc -l | tr -d ' '; }

EXCL='--exclude-dir=node_modules --exclude-dir=Pods --exclude-dir=build --exclude-dir=.build --exclude-dir=.git --exclude-dir=.dart_tool --exclude-dir=DerivedData --exclude-dir=.gradle --exclude-dir=.fvm --exclude-dir=.symlinks --exclude-dir=vendor --exclude-dir=ephemeral --exclude-dir=.idea --exclude-dir=Carthage --exclude-dir=.expo --exclude-dir=.next'

# grep_count <dir> <ERE> <name-glob...>: number of files whose content matches (one grep per call)
grep_count() {
  d=$1; re=$2; shift 2
  [ -d "$d" ] || { echo 0; return; }
  set -f
  inc=""
  for g in "$@"; do inc="$inc --include=$g"; done
  # shellcheck disable=SC2086
  n=$(grep -rlE $inc $EXCL -e "$re" "$d" 2>/dev/null | wc -l | tr -d ' ')
  set +f
  echo "$n"
}

rel() { # path relative to base
  p=$1
  case "$p" in
    "$base") echo . ;;
    "$base"/*) echo "${p#"$base"/}" ;;
    ./*) echo "${p#./}" ;;
    *) echo "$p" ;;
  esac
}

join() { tr '\n' ',' | sed -e 's/,$//' -e 's/,/, /g'; }

kv() { # print "key: value" only when value is non-empty
  [ -n "$2" ] && printf '%s: %s\n' "$1" "$2"; return 0
}

# ---------- app roots ----------

is_flutter_pubspec() { grep -Eq '^[[:space:]]+sdk:[[:space:]]*flutter' "$1" 2>/dev/null; }

candidates() {
  ffind . 4 -type f -name pubspec.yaml | while IFS= read -r f; do
    is_flutter_pubspec "$f" && dirname "$f"
  done
  ffind . 4 -type f -name package.json | while IFS= read -r f; do
    grep -Eq '"(react-native|expo)"[[:space:]]*:' "$f" && dirname "$f"
  done
  ffind . 4 -type f \( -name settings.gradle -o -name settings.gradle.kts \) | while IFS= read -r f; do dirname "$f"; done
  ffind . 4 -type d \( -name '*.xcodeproj' -o -name '*.xcworkspace' \) | while IFS= read -r f; do
    case "$f" in *.xcodeproj/*) continue ;; esac
    dirname "$f"
  done
  ffind . 4 -type f -name Package.swift | while IFS= read -r f; do dirname "$f"; done
}

roots=$(candidates | sed -e 's|^\./||' -e 's|^\.$|.|' | sort -u)
# drop platform folders of another root (ios/ and android/ of a Flutter or RN app, iosApp/ of KMP);
# keep separate apps nested under a workspace root
roots=$(printf '%s\n' "$roots" | awk '
  function first_seg(child, parent,   rest) {
    rest = (parent == ".") ? child : substr(child, length(parent) + 2)
    sub(/\/.*/, "", rest)
    return rest
  }
  NF { a[++n] = $0 }
  END {
    for (i = 1; i <= n; i++) {
      keep = 1
      for (j = 1; j <= n; j++) {
        if (i == j) continue
        if (a[j] == "." ? a[i] != "." : index(a[i], a[j] "/") == 1) {
          if (first_seg(a[i], a[j]) ~ /^(ios|android|macos|linux|windows|web|iosApp|androidApp|composeApp|shared|desktopApp)$/) { keep = 0; break }
        }
      }
      if (keep) print a[i]
    }
  }')

stack_of() { # prints "stack|signal"
  r=$1
  if [ -f "$r/pubspec.yaml" ] && is_flutter_pubspec "$r/pubspec.yaml"; then
    echo "flutter|pubspec.yaml (sdk: flutter)"; return
  fi
  if [ -f "$r/package.json" ] && grep -Eq '"expo"[[:space:]]*:' "$r/package.json"; then
    echo "expo|package.json (expo)"; return
  fi
  if [ -f "$r/package.json" ] && grep -Eq '"react-native"[[:space:]]*:' "$r/package.json"; then
    echo "react-native|package.json (react-native)"; return
  fi
  kmp=$(ffind "$r" 3 -type f \( -name '*.gradle' -o -name '*.gradle.kts' -o -name 'libs.versions.toml' \) \
    | while IFS= read -r f; do grep -Eiq 'kotlin\("multiplatform"\)|kotlin-multiplatform|kotlin\.multiplatform|kotlinMultiplatform' "$f" && echo "$f"; done | head -n 1)
  if [ -n "$kmp" ]; then echo "kmp|$(rel "$kmp") (kotlin multiplatform)"; return; fi
  x=$(find "$r" -maxdepth 1 \( -name '*.xcodeproj' -o -name '*.xcworkspace' -o -name Package.swift \) 2>/dev/null | head -n 1)
  if [ -n "$x" ]; then echo "ios|$(rel "$x")"; return; fi
  g=$(find "$r" -maxdepth 2 \( -name build.gradle -o -name build.gradle.kts \) 2>/dev/null | head -n 1)
  m=$(ffind "$r" 5 -type f -name AndroidManifest.xml | head -n 1)
  if [ -n "$g" ] && [ -n "$m" ]; then echo "android|$(rel "$g") + $(rel "$m")"; return; fi
  echo "none|"
}

app_kind() { # flutter app vs package
  r=$1
  if [ -f "$r/pubspec.yaml" ] && is_flutter_pubspec "$r/pubspec.yaml"; then
    if [ -d "$r/ios" ] || [ -d "$r/android" ] || ls "$r"/lib/main*.dart >/dev/null 2>&1; then echo app; else echo package; fi
  else
    echo app
  fi
}

n_roots=$(printf '%s\n' "$roots" | grep -c .)

echo "## scan"
kv path "$base"

if [ -z "$root_override" ]; then
  if [ "$n_roots" -eq 0 ]; then
    echo "apps: none"
    echo "note: no mobile project signals found (pubspec.yaml, package.json with react-native/expo, Gradle settings, Xcode project, Package.swift)"
    exit 0
  fi
  if [ "$n_roots" -gt 1 ]; then
    echo "apps: $n_roots"
    printf '%s\n' "$roots" | while IFS= read -r r; do
      s=$(stack_of "$r")
      printf -- '- %s · %s · %s · signal: %s\n' "$r" "${s%%|*}" "$(app_kind "$r")" "${s#*|}"
    done
    echo "note: several app roots found; rerun with --root <path> for details"
    exit 0
  fi
  root=$roots
else
  root=$root_override
  [ -d "$root" ] || { echo "error: no such root $root"; exit 1; }
fi

cd "$root" || exit 1
R=$(pwd -P)
s=$(stack_of .)
stack=${s%%|*}
signal=${s#*|}

kv root "$(rel "$R")"
kv stack "$stack"
kv signal "$signal"
kv kind "$(app_kind .)"
[ "$stack" = none ] && { echo "note: nothing detected at this root"; exit 0; }

# ---------- languages ----------

echo "## languages"
for e in dart swift m kt java ts tsx js jsx; do
  c=$(ffind . 12 -type f -name "*.$e" | grep -v -e '\.g\.dart$' -e '\.freezed\.dart$' -e '/generated/' | wc -l | tr -d ' ')
  [ "$c" -gt 0 ] && echo "$e: $c files"
done

# ---------- helpers per stack ----------

pubspec_deps() { # section name -> dependency names
  awk -v want="$1" '
    /^[^[:space:]#]/ { sec = $0; sub(/:.*/, "", sec); ind = 0; next }
    sec == want && /^[ ]+[A-Za-z0-9_]+:/ {
      match($0, /^[ ]+/)
      if (ind == 0) ind = RLENGTH          # first entry sets the indentation (2, 4, ...)
      if (RLENGTH == ind) { k = $1; sub(/:$/, "", k); print k }
    }
  ' pubspec.yaml 2>/dev/null
}

pkg_deps() { # package.json dependency names (deps + devDeps)
  if command -v jq >/dev/null 2>&1; then
    jq -r '(.dependencies // {}) + (.devDependencies // {}) | keys[]' package.json 2>/dev/null
  else
    sed -n '/"\(dev\)\{0,1\}[dD]ependencies"/,/}/p' package.json | sed -n 's/^[[:space:]]*"\([^"]*\)"[[:space:]]*:.*/\1/p' | grep -v -i dependencies
  fi
}

in_list() { printf '%s\n' "$2" | grep -Fxq "$1"; }

tree_dirs() { # tree_dirs <dir> <depth>
  [ -d "$1" ] || return 0
  ffind "$1" "$2" -type d | sed "s|^\./||" | grep -v -e '^\.$' -e "^$1\$" | sort | head -n 40
}

android_flavors() {
  for f in "$1/build.gradle" "$1/build.gradle.kts"; do
    [ -f "$f" ] || continue
    awk '
      /productFlavors[[:space:]]*\{/ { inb = 1; depth = 1; next }
      inb {
        line = $0
        if (depth == 1 && line ~ /^[[:space:]]*(create\(")?[A-Za-z0-9_]+("\))?[[:space:]]*\{/) {
          n = line; gsub(/create\("|"\)|\{|[[:space:]]/, "", n); print n
        }
        o = gsub(/\{/, "{", line); c = gsub(/\}/, "}", line)
        depth += o - c
        if (depth <= 0) inb = 0
      }
    ' "$f"
  done
}

xc_schemes() {
  ffind "${1:-.}" 6 -type f -name '*.xcscheme' | sed -e 's|.*/||' -e 's|\.xcscheme$||' | sort -u
}

simulator() {
  command -v xcrun >/dev/null 2>&1 || return 0
  xcrun simctl list devices available 2>/dev/null | grep -m 1 -E '^[[:space:]]+iPhone' \
    | sed -e 's/^[[:space:]]*//' -e 's/ ([0-9A-F-]\{36\}).*//'
}

# ---------- dependencies & state ----------

echo "## dependencies"
deps=""
case "$stack" in
  flutter)
    deps=$(pubspec_deps dependencies)
    dev=$(pubspec_deps dev_dependencies)
    kv deps "$(printf '%s\n' "$deps" | grep -v '^flutter$' | join)"
    kv dev_deps "$(printf '%s\n' "$dev" | grep -v '^flutter_test$' | join)"
    kv sdk "$(sed -n 's/^[[:space:]]*sdk:[[:space:]]*\(["'"'"'^>=<0-9].*\)/\1/p' pubspec.yaml | head -n 1)"
    in_list build_runner "$dev" && echo "codegen: build_runner (dart run build_runner build --delete-conflicting-outputs)"
    ;;
  expo|react-native)
    deps=$(pkg_deps)
    kv deps "$(printf '%s\n' "$deps" | head -n 60 | join)"
    ;;
  ios)
    [ -f Podfile ] && kv pods "$(sed -n "s/^[[:space:]]*pod[[:space:]]*['\"]\([^'\"]*\)['\"].*/\1/p" Podfile | sort -u | join)"
    pr=$(ffind . 6 -type f -name Package.resolved | head -n 1)
    [ -n "$pr" ] && kv spm "$(sed -n 's/.*"identity"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$pr" | sort -u | join)"
    [ -f Package.swift ] && kv package_swift_deps "$(sed -n 's/.*\.package(.*url:[[:space:]]*"\([^"]*\)".*/\1/p' Package.swift | sed 's|.*/||; s|\.git$||' | join)"
    deps=$( {
      [ -f Podfile ] && sed -n "s/^[[:space:]]*pod[[:space:]]*['\"]\([^'\"]*\)['\"].*/\1/p" Podfile
      [ -n "$pr" ] && sed -n 's/.*"identity"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$pr"
      [ -f Package.swift ] && sed -n 's/.*\.package(.*url:[[:space:]]*"\([^"]*\)".*/\1/p' Package.swift | sed 's|.*/||; s|\.git$||'
    } | sort -u)
    ;;
  android|kmp)
    gf=$(ffind . 3 -type f \( -name '*.gradle' -o -name '*.gradle.kts' -o -name 'libs.versions.toml' \))
    kv libs "$(printf '%s\n' "$gf" | while IFS= read -r f; do
      grep -Eoh 'hilt|koin|dagger|compose|room|retrofit|ktor|coroutines|orbit|mavericks|sqldelight|kotlinx-serialization|navigation' "$f" 2>/dev/null
    done | sort -u | join)"
    # artifact names from "group:artifact:version" strings and version-catalog `module = "group:artifact"`
    deps=$(printf '%s\n' "$gf" | while IFS= read -r f; do
      grep -Eoh '"[A-Za-z0-9_.-]+:[A-Za-z0-9_.-]+(:[^"]*)?"' "$f" 2>/dev/null
    done | sed -e 's/"//g' | awk -F: '{print $2}' | sort -u)
    kv deps "$(printf '%s\n' "$deps" | head -n 60 | join)"
    ;;
esac

echo "## state"
case "$stack" in
  flutter)
    known="flutter_bloc bloc hydrated_bloc bloc_concurrency riverpod flutter_riverpod hooks_riverpod riverpod_annotation provider get get_it injectable mobx flutter_mobx redux flutter_redux stacked signals flutter_hooks"
    kv state_packages "$(printf '%s\n' "$deps" | grep -Fx -e "$(printf '%s\n' $known)" 2>/dev/null | join)"
    kv blocs_cubits "$(grep_count lib 'extends[[:space:]]+(Cubit|Bloc)<' '*.dart') files"
    kv riverpod_usage "$(grep_count lib 'ConsumerWidget|ConsumerStatefulWidget|@riverpod|StateNotifierProvider|NotifierProvider' '*.dart') files"
    kv change_notifier "$(grep_count lib 'extends[[:space:]]+ChangeNotifier|with[[:space:]]+ChangeNotifier' '*.dart') files"
    kv getx_controllers "$(grep_count lib 'extends[[:space:]]+GetxController' '*.dart') files"
    kv set_state "$(grep_count lib 'setState\(' '*.dart') files"
    ;;
  expo|react-native)
    known="redux @reduxjs/toolkit react-redux zustand mobx mobx-react-lite jotai recoil @tanstack/react-query swr xstate"
    kv state_packages "$(printf '%s\n' "$deps" | grep -Fx -e "$(printf '%s\n' $known)" 2>/dev/null | join)"
    ;;
  ios)
    kv observable_macro "$(grep_count . '@Observable' '*.swift') files"
    kv observable_object "$(grep_count . 'ObservableObject' '*.swift') files"
    kv combine "$(grep_count . '^import Combine' '*.swift') files"
    kv tca "$(grep_count . '^import ComposableArchitecture' '*.swift') files"
    ;;
  android|kmp)
    kv viewmodels "$(grep_count . ':[[:space:]]*ViewModel\(' '*.kt') files"
    kv state_flow "$(grep_count . 'StateFlow<' '*.kt') files"
    ;;
esac

# ---------- UI ----------

echo "## ui"
sw_ui=0; uk_ui=0; sb=0; compose=0; xml=0
case "$stack" in ios|flutter|expo|react-native|kmp)
sw_ui=$(grep_count . '^import SwiftUI' '*.swift')
uk_ui=$(grep_count . '^import UIKit' '*.swift')
sb=$(count . -type f \( -name '*.storyboard' -o -name '*.xib' \)) ;;
esac
case "$stack" in android|kmp|flutter|expo|react-native)
compose=$(grep_count . '@Composable' '*.kt')
xml=$(ffind . 8 -type f -path '*/res/layout*/*.xml' | wc -l | tr -d ' ') ;;
esac
case "$stack" in
  flutter) echo "ui: Widgets" ;;
  expo|react-native) echo "ui: RN" ;;
esac
[ "$sw_ui" -gt 0 ] && echo "swiftui_files: $sw_ui"
[ "$uk_ui" -gt 0 ] && echo "uikit_files: $uk_ui"
[ "$sb" -gt 0 ] && echo "storyboards_xibs: $sb"
[ "$compose" -gt 0 ] && echo "compose_files: $compose"
[ "$xml" -gt 0 ] && echo "xml_layouts: $xml"

# ---------- secondary native code (inside cross-platform apps) ----------

case "$stack" in
  flutter|expo|react-native)
    echo "## secondary"
    ns=$(ffind ios 8 -type f -name '*.swift' 2>/dev/null | grep -v -e 'AppDelegate.swift$' -e 'SceneDelegate.swift$' -e 'GeneratedPluginRegistrant' -e '/RunnerTests/' | wc -l | tr -d ' ')
    nk=$(ffind android 10 -type f \( -name '*.kt' -o -name '*.java' \) 2>/dev/null | grep -v -e 'MainActivity\.' -e 'MainApplication\.' -e 'GeneratedPluginRegistrant' | wc -l | tr -d ' ')
    echo "native_ios_files: ${ns:-0} (excluding AppDelegate/SceneDelegate/generated)"
    echo "native_android_files: ${nk:-0} (excluding MainActivity/MainApplication/generated)"
    pc=$(grep_count . 'MethodChannel|EventChannel|FlutterMethodChannel|NativeModules|TurboModule|ReactContextBaseJavaModule|RCT_EXPORT_MODULE|RCTBridgeModule' '*.dart' '*.swift' '*.kt' '*.java' '*.m' '*.mm' '*.ts' '*.tsx' '*.js' '*.jsx')
    [ "$pc" -gt 0 ] && echo "platform_channel_files: $pc"
    ;;
esac

# ---------- architecture ----------

echo "## folders"
case "$stack" in
  flutter) tree_dirs lib 3 ;;
  expo|react-native) for d in src app; do tree_dirs "$d" 3; done ;;
  ios)
    ffind . 3 -type d | sed 's|^\./||' | grep -v -e '^\.$' -e '\.xcodeproj' -e '\.xcworkspace' -e '\.xcassets' -e '\.lproj' -e '^\.' -e '/\.' | sort | head -n 40 ;;
  android|kmp)
    ffind . 9 -type d \( -path '*/src/main/java/*' -o -path '*/src/main/kotlin/*' -o -path '*/src/commonMain/kotlin/*' \) \
      | sed 's|^\./||' | sort | head -n 40 ;;
esac

# ---------- flavors / schemes / environments ----------

echo "## environments"
case "$stack" in
  flutter|expo|react-native)
    kv android_flavors "$(android_flavors android/app | join)"
    kv ios_schemes "$(xc_schemes ios | join)"
    [ "$stack" = flutter ] && kv flutter_entrypoints "$(ls lib/main*.dart 2>/dev/null | join)"
    ;;
  ios) kv schemes "$(xc_schemes . | join)" ;;
  android|kmp) kv android_flavors "$(for d in app androidApp composeApp; do android_flavors "$d"; done | join)" ;;
esac
kv env_files "$(ffind . 3 -name '.env*' | sed 's|^\./||' | sort | join)"
kv dart_define_files "$(ffind . 3 -type f -name '*.json' -path '*env*' | sed 's|^\./||' | head -n 10 | join)"
case "$stack" in ios|flutter|expo|react-native|kmp) kv simulator "$(simulator)" ;; esac

# ---------- services ----------

echo "## services"
kv firebase_config "$(ffind . 6 -type f \( -name google-services.json -o -name GoogleService-Info.plist -o -name firebase.json -o -name 'firebase_options*.dart' \) | sed 's|^\./||' | sort | join)"
kv firebase_packages "$( { printf '%s\n' "$deps"; [ -f Podfile ] && grep -o "Firebase[A-Za-z]*" Podfile; } | grep -i -e firebase -e crashlytics | sort -u | join)"
kv backend_packages "$(printf '%s\n' "$deps" | grep -i -e supabase -e amplify -e appwrite -e graphql -e apollo -e dio -e retrofit -e chopper -e '^http$' -e axios | sort -u | join)"

# ---------- tests ----------

echo "## tests"
case "$stack" in
  flutter)
    echo "unit_widget_tests: $(count test -type f -name '*_test.dart') files in test/"
    [ -d integration_test ] && echo "integration_tests: $(count integration_test -type f -name '*_test.dart') files in integration_test/"
    ;;
  expo|react-native)
    echo "js_tests: $(ffind . 8 -type f \( -name '*.test.*' -o -name '*.spec.*' \) | wc -l | tr -d ' ') files"
    kv test_config "$(ls jest.config.* vitest.config.* detox.config.* .detoxrc* 2>/dev/null | join)"
    ;;
esac
case "$stack" in
  ios|flutter|expo|react-native|kmp)
    xt=$(ffind . 8 -type f -name '*.swift' -path '*Tests/*' | grep -v '/RunnerTests/RunnerTests.swift$' | wc -l | tr -d ' ')
    [ "$xt" -gt 0 ] && echo "swift_test_files: $xt"
    ;;
esac
at=$(ffind . 10 -type f \( -path '*/src/test/*' -o -path '*/src/androidTest/*' -o -path '*/src/commonTest/*' \) \( -name '*.kt' -o -name '*.java' \) | wc -l | tr -d ' ')
[ "$at" -gt 0 ] && echo "jvm_test_files: $at"

# ---------- tooling ----------

echo "## tooling"
kv lint_format_config "$(for f in analysis_options.yaml .swiftlint.yml .swiftformat .editorconfig .eslintrc .eslintrc.js .eslintrc.json eslint.config.js eslint.config.mjs .prettierrc .prettierrc.json prettier.config.js detekt.yml config/detekt/detekt.yml .ktlint ios/.swiftlint.yml ios/.swiftformat; do [ -e "$f" ] && echo "$f"; done | join)"
[ -f analysis_options.yaml ] && kv analysis_include "$(sed -n 's/^include:[[:space:]]*//p' analysis_options.yaml | head -n 1)"
if [ -f .fvmrc ] || [ -f .fvm/fvm_config.json ]; then
  echo "fvm: yes (prefix flutter/dart commands with 'fvm')"
fi
[ -f melos.yaml ] && kv melos_scripts "$(awk '/^scripts:/ {on=1; next} /^[^[:space:]]/ {on=0} on && /^  [A-Za-z0-9_:-]+:/ {k=$1; sub(/:$/,"",k); print k}' melos.yaml | join)"
[ -f Makefile ] && kv make_targets "$(grep -Eo '^[A-Za-z0-9_.-]+:' Makefile | grep -v '^\.' | sed 's/:$//' | sort -u | head -n 30 | join)"
[ -f justfile ] && kv just_recipes "$(grep -Eo '^[A-Za-z0-9_-]+' justfile | sort -u | head -n 30 | join)"
if [ -f package.json ]; then
  if command -v jq >/dev/null 2>&1; then
    kv npm_scripts "$(jq -r '.scripts // {} | to_entries[] | "\(.key)=\(.value)"' package.json 2>/dev/null | head -n 20 | join)"
  fi
fi
for f in yarn.lock pnpm-lock.yaml package-lock.json bun.lockb; do [ -f "$f" ] && echo "package_manager_lock: $f"; done
kv ci "$(ls .github/workflows/*.y*ml codemagic.yaml bitrise.yml .gitlab-ci.yml 2>/dev/null | join)"
[ -d fastlane ] || [ -d ios/fastlane ] || [ -d android/fastlane ] && echo "fastlane: yes"
kv gradle_wrapper "$(ls gradlew android/gradlew 2>/dev/null | join)"

# ---------- protected candidates ----------

echo "## protected_candidates"
kv signing_files "$(ffind . 6 -type f \( -name '*.jks' -o -name '*.keystore' -o -name 'key.properties' -o -name '*.p12' -o -name '*.mobileprovision' -o -name '*.p8' \) | sed 's|^\./||' | sort | join)"
kv generated "$( {
  [ "$(count . -type f \( -name '*.g.dart' -o -name '*.freezed.dart' -o -name '*.gr.dart' -o -name '*.mocks.dart' \))" -gt 0 ] && echo '*.g.dart / *.freezed.dart etc. (present)'
  for d in lib/generated lib/gen lib/l10n/generated .dart_tool/flutter_gen; do [ -d "$d" ] && echo "$d/"; done
} | join)"

# ---------- existing knowledge & git ----------

echo "## knowledge"
kv project_md "$( [ -f docs/tara-knowledge/project.md ] && echo "exists (schema: $(sed -n 's/.*tara-schema:[[:space:]]*\([0-9]*\).*/\1/p' docs/tara-knowledge/project.md | head -n 1))" || echo missing)"
kv learnings_md "$( [ -f docs/tara-knowledge/learnings.md ] && echo "exists ($(grep -c '^- [0-9]' docs/tara-knowledge/learnings.md) entries)" || echo missing)"
kv plans "$( [ -d docs/tara-knowledge/plans ] && echo "$(ls docs/tara-knowledge/plans/*.md 2>/dev/null | wc -l | tr -d ' ') files" || echo missing)"
if [ -f CLAUDE.md ]; then
  grep -q 'docs/tara-knowledge/project.md' CLAUDE.md && echo "claude_md: exists, has tara line" || echo "claude_md: exists, no tara line"
else
  echo "claude_md: missing"
fi

echo "## git"
if git rev-parse --git-dir >/dev/null 2>&1; then
  echo "repo: yes (top: $(git rev-parse --show-toplevel))"
  kv branch "$(git branch --show-current 2>/dev/null)"
  kv default_branch "$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed 's|^origin/||')"
  git check-ignore -q docs/tara-knowledge/plans/x.md 2>/dev/null && echo "plans_gitignored: yes"
else
  echo "repo: no"
fi
exit 0
