---
description: Send a release build to testers via Firebase App Distribution or TestFlight, using the project's existing pipeline, with explicit approval before any upload
argument-hint: "<firebase | testflight> [android | ios] [--groups <names>] [--quiet]"
allowed-tools: Read, Read(/${CLAUDE_PLUGIN_ROOT}/skills/**), Grep, Glob, Bash(git status *), Bash(git log *), Bash(git describe *)
---

# /tara:distribute

Arguments: `$ARGUMENTS`

Precedence when instructions conflict: (1) the user's current message, (2) project `CLAUDE.md` + `docs/tara-knowledge/project.md`, (3) `docs/tara-knowledge/learnings.md`, (4) plugin skills.

Human gates: **nothing is uploaded without an explicit "yes" to the exact command shown.** Never create, change, or export signing credentials, certificates, provisioning profiles, keystores, or API keys. Never store tokens in files. If authentication is missing, tell the user how to log in themselves (e.g. `! firebase login`) and stop.

## 1. Load knowledge and preconditions

- Find the app root: the nearest directory, from the current directory up to the git top level, that contains `docs/tara-knowledge/project.md`. All `docs/tara-knowledge/` paths below are relative to it. If none is found but app roots below the current directory have one (monorepo), list them and ask which app to use. If there is none at all: print `Run /tara:init first` and stop.
- Read that `project.md`.
- Read `docs/tara-knowledge/learnings.md`; apply `[release]`/`[distribute]` entries.
- Working tree clean, and HEAD tagged or matching the version from `/tara:release`. If not, warn and ask whether to continue.
- Recommend running `/tara:store-check` first if it hasn't been run for this version. For TestFlight, P1 findings there should be fixed before uploading.

## 2. Prefer the project's existing pipeline

Look for an existing distribution path and use it rather than inventing one:
- fastlane lanes (`fastlane/Fastfile`, `ios/fastlane`, `android/fastlane`), e.g. `beta`, `firebase`, `testflight`;
- CI workflows that distribute (`.github/workflows`, `codemagic.yaml`, `bitrise.yml`). If distribution happens in CI, say so and offer to explain how to trigger it instead of uploading locally;
- npm scripts or Makefile targets (`distribute`, `beta`), or Expo `eas submit` / `eas build --profile preview` configs (`eas.json`).

Show what you found and which path you'll use.

## 3. Build

If no suitable artifact exists for this version, run the release build through `/tara:build <platform> --release` (it asks before using signing). Firebase needs an `.apk`/`.aab` or `.ipa`; TestFlight needs an `.ipa` exported for App Store distribution. If export requires signing that isn't configured, explain and stop.

## 4. Prepare the upload command

- **Firebase App Distribution:** `firebase appdistribution:distribute <artifact> --app <firebase-app-id> --release-notes-file <tmpfile> --groups "<groups>"`. Read the app ID from `google-services.json` (`mobilesdk_app_id`) or `GoogleService-Info.plist` (`GOOGLE_APP_ID`); read-only, never edit those files. Or use the fastlane `firebase_app_distribution` lane if present. Check `firebase --version` and that the user is logged in (`firebase login:list`).
- **TestFlight:** the fastlane lane (`pilot`/`upload_to_testflight`) if present. Otherwise give the user the manual route: Xcode Organizer → Distribute App, or the Transporter app. Only run a CLI upload if the project already has App Store Connect API key auth configured outside the repo.
- Release notes: from the changelog section for this version, or the commits since the last tag. Keep them short, user-facing, and free of internal ticket noise.

## 5. Approve and upload

Show: the artifact (path, version, build number, size), the destination (app ID / App Store Connect app), testers/groups, the release notes, and the **exact command**. Ask: **"Upload now?"**

On yes, run it and report the result (release URL/console link, processing status). On failure, show the error, explain it, and stop. Don't retry with different credentials or flags without asking.

## 6. Summary

End with at most 5 lines: what was distributed (platform, version+build), where, to whom, link, next step (e.g. "TestFlight processing takes a while; check App Store Connect").

`--quiet`: still show the upload details and ask; skip the closing summary and end with only: `tara distribute: <platform> X.Y.Z+N → <firebase|testflight> · <uploaded|cancelled|failed>`
