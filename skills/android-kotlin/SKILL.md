---
name: android-kotlin
description: Generic Android and Kotlin best practices for Jetpack Compose, Views, ViewModel/state, coroutines and Flow, and testing. Use when reading, writing, or reviewing .kt/.java files, Gradle build files, or AndroidManifest.xml in an Android app (including native Android code inside Flutter or React Native apps).
paths: "**/*.kt, **/*.kts, **/*.java, **/AndroidManifest.xml, **/build.gradle, **/libs.versions.toml, **/res/layout/*.xml"
user-invocable: false
---

# Android / Kotlin

Precedence: user's message > project `CLAUDE.md` + `docs/tara-knowledge/project.md` > `docs/tara-knowledge/learnings.md` > this skill.
This skill is generic and follows the official Android guidance (developer.android.com: Guide to app architecture, Compose, Kotlin coroutines best practices, Testing). If `project.md` names an architecture, DI library, or command, follow it.

## Core rules

- Use the Gradle tasks from `project.md`; don't guess module or variant names.
- Layers: UI (Compose/Views + ViewModel) → optional domain (use cases) → data (repositories + data sources). UI never calls data sources directly.
- Unidirectional data flow: the ViewModel exposes immutable UI state (`StateFlow<UiState>`); the UI sends events as function calls. Don't expose `MutableStateFlow`/`MutableLiveData`.
- Model screen state explicitly (loading, content, empty, error), usually as a data class or sealed interface.
- Collect flows lifecycle-aware: `collectAsStateWithLifecycle()` in Compose, `repeatOnLifecycle(STARTED)` in Views. Never `lifecycleScope.launch { flow.collect {} }` without it.
- Coroutines: `viewModelScope` for UI work; inject dispatchers; never `GlobalScope`; never block the main thread (`runBlocking`, disk/network on `Main`). Read `coroutines.md`.
- Survive configuration change and process death: state in the ViewModel, small UI state in `SavedStateHandle`/`rememberSaveable`.
- Don't hold `Context`, `Activity`, `View`, or `Fragment` references in ViewModels or singletons (leaks). Use `applicationContext` only where it's required.
- Inject dependencies (Hilt/Koin/manual per project); no `object` singletons that hide state.
- Secrets never in source, `BuildConfig` fields committed to the repo, or `strings.xml`. Tokens go in encrypted storage (Keystore-backed).
- Manifest hygiene: `android:exported` set explicitly on components with intent filters; only the permissions you use; runtime permission requests with rationale.
- Strings in `strings.xml` (localization), dimensions in `dp`/`sp`, colors from the theme (`MaterialTheme.colorScheme`), never hardcoded.

## Read more only when needed

- Compose UI, recomposition, state hoisting, lists → read `compose.md`
- Coroutines, Flow, threading, cancellation → read `coroutines.md`
- Unit, instrumented, or Compose UI tests → read `testing.md`

## Review checklist (for tara reviewer agents)

- P1: main-thread I/O or `runBlocking` on UI paths; leaked Activity/Context; `!!` on external data; exported components without permission; secrets in source; missing runtime permission handling (crash); collecting flows without lifecycle awareness that updates destroyed UI.
- P2: unstable Compose parameters causing recomposition storms; work in composition; non-lazy lists over dynamic data; logic in Activities/Fragments/composables; missing loading/error states; hardcoded strings/colors/sizes.
- P3: unused resources; `GlobalScope` in non-critical code; leftover `Log.d`.
