---
description: Read-only pre-submission audit covering iOS privacy manifest and usage strings, Play data safety, permissions, icons, and other common store-rejection causes
argument-hint: "[ios | android | all] [--quiet]"
allowed-tools: Read, Read(/${CLAUDE_PLUGIN_ROOT}/skills/**), Grep, Glob
---

# /tara:store-check

Arguments: `$ARGUMENTS`

Precedence when instructions conflict: (1) the user's current message, (2) project `CLAUDE.md` + `docs/tara-knowledge/project.md`, (3) `docs/tara-knowledge/learnings.md`, (4) plugin skills.

Read-only: report findings and fixes; don't edit. Store policies change. When a check depends on a current threshold (Play `targetSdk` minimum, Xcode/SDK requirement for uploads), state the value found and tell the user to confirm it against the current policy page; don't claim a specific year's number as fact.

## 1. Load knowledge

- Find the app root: the nearest directory, from the current directory up to the git top level, that contains `docs/tara-knowledge/project.md`. All `docs/tara-knowledge/` paths below are relative to it. If none is found but app roots below the current directory have one (monorepo), list them and ask which app to use. If there is none at all: print `Run /tara:init first` and stop.
- Read that `project.md`.
- Read `docs/tara-knowledge/learnings.md`.
- Platform: from the argument, default `all` that apply to the stack.
- Build the **capability map** first: which sensitive capabilities the app uses, from code and dependencies. For example: camera, photo library, location (when-in-use/always), microphone, contacts, calendar, Bluetooth, Face ID/biometrics, motion, notifications, tracking/advertising ID, health, background modes, and analytics/crash/ads SDKs. Flutter/RN plugins imply native capabilities (`image_picker` → camera + photos, `geolocator` → location, `firebase_analytics` → analytics data).

## 2. iOS checks

- **Usage strings:** every capability in the map has its `NS…UsageDescription` in the app's Info.plist (and in extensions that use it). Strings must be specific to the app's purpose ("to scan receipts"), not generic or empty. Missing → P1 (crash on access + rejection).
- **Privacy manifest:** `PrivacyInfo.xcprivacy` exists in the app target. Required-reason APIs used by the app's code (e.g. `UserDefaults`, file timestamp APIs, system boot time, disk space, active keyboard) are declared with valid reason codes. Collected data types and tracking domains match the capability map. Third-party SDKs on Apple's commonly-used-SDK list need their own manifests (check the versions in use ship one).
- **Tracking:** if IDFA/ad SDKs are present, `NSUserTrackingUsageDescription` exists and an ATT prompt appears before tracking.
- **Account deletion:** if the app lets users create an account, it must offer in-app account deletion.
- **Sign in with Apple:** if third-party social login is offered, check whether Sign in with Apple (or an equivalent permitted option) is required.
- **Encryption:** `ITSAppUsesNonExemptEncryption` set (avoids the export-compliance prompt on every upload).
- **ATS:** no `NSAllowsArbitraryLoads` without justification.
- **Icons and launch:** a 1024×1024 App Store icon in the asset catalog without alpha channel; all required sizes or single-size; a launch screen configured.
- **Versions:** `MARKETING_VERSION`/build number set and incremented vs the last tag (see `/tara:release`).
- **Background modes** declared in Info.plist are actually used (unused modes get rejected).

## 3. Android checks

- **targetSdk / compileSdk:** report the values; remind the user to check them against Play's current minimum target API requirement.
- **Permissions:** every manifest permission (including those merged from libraries) maps to a capability actually used. Flag sensitive ones that need a Play declaration or are restricted: `ACCESS_BACKGROUND_LOCATION`, `READ_MEDIA_IMAGES`/`READ_MEDIA_VIDEO` (the photo picker is preferred for occasional access), `QUERY_ALL_PACKAGES`, `MANAGE_EXTERNAL_STORAGE`, SMS/call log, `SCHEDULE_EXACT_ALARM`/`USE_EXACT_ALARM`, foreground service types (each `FOREGROUND_SERVICE_*` needs a declared type and justification).
- **Runtime permissions:** dangerous permissions are requested at runtime with a rationale; `POST_NOTIFICATIONS` requested on Android 13+ if notifications are used.
- **Data safety:** list what the app and its SDKs collect or share (from the capability map: analytics, crash reports, location, identifiers, contacts, photos, purchase history) so the Play Console data safety form can be filled in accurately. Mismatches between the form and actual behavior cause rejection.
- **Account deletion:** if accounts can be created, an in-app deletion path and a web deletion link are required.
- **Manifest:** `android:exported` explicit on components with intent filters; `android:debuggable` not set; `usesCleartextTraffic` not `true` without a network security config; `allowBackup` considered for sensitive data.
- **Icons:** adaptive icon (foreground + background, monochrome for themed icons) present; a 512×512 store icon exists for the listing.
- **Versions:** `versionCode` incremented vs the last release; `versionName` set.
- **App bundle:** release builds produce `.aab` for Play (APK only for other channels).

## 4. Report

Same format as `/tara:review`:

```
## tara store-check — <platforms>
Capabilities: camera, photos, location (when in use), analytics (firebase_analytics) …

### P1  (will crash or be rejected)
- `ios/Runner/Info.plist` — missing NSCameraUsageDescription (image_picker) → add a purpose string
### P2  (likely review friction / policy risk)
### P3  (polish)

### Data safety / privacy summary
- Collected: … · Shared: … · Tracking: yes/no
```

End with at most 5 lines: P1/P2/P3 counts per platform, the top fix, and what needs manual confirmation (policy thresholds, store console forms).

`--quiet`: output only this one line, with no progress notes or summary before it: `tara store-check: ios <n> P1 · <n> P2 · android <n> P1 · <n> P2`
