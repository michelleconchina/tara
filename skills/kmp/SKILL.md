---
name: kmp
description: Generic Kotlin Multiplatform best practices for shared code structure, expect/actual, coroutines across platforms, Swift interop, and testing. Use when reading, writing, or reviewing commonMain/androidMain/iosMain source sets or KMP Gradle configuration.
paths: "**/commonMain/**, **/androidMain/**, **/iosMain/**, **/commonTest/**, **/*.gradle.kts, **/libs.versions.toml"
user-invocable: false
---

# Kotlin Multiplatform

Precedence: user's message > project `CLAUDE.md` + `docs/tara-knowledge/project.md` > `docs/tara-knowledge/learnings.md` > this skill.
This skill is generic and follows the official docs (kotlinlang.org/docs/multiplatform, Compose Multiplatform docs). Platform UI code also follows `android-kotlin` and `ios-swift`. If `project.md` names a module layout or library, follow it.

## Core rules

- Put as much logic as is sensible in `commonMain` (models, repositories, use cases, view-model logic). Keep platform source sets thin: only what needs platform APIs.
- Prefer interfaces in common code with platform implementations injected (DI) over `expect`/`actual`; use `expect`/`actual` for small platform primitives (e.g. a UUID, platform name, file path helpers).
- Only multiplatform libraries in `commonMain` (Ktor, kotlinx.serialization, kotlinx.coroutines, kotlinx-datetime, SQLDelight/Room KMP, Koin, etc.). Never Android or JVM-only APIs (`java.*`, `android.*`) in common code.
- Coroutines: inject dispatchers; `Dispatchers.IO` isn't available in common code on every target, so use `Dispatchers.Default` or an injected dispatcher. Expose `StateFlow` for UI state.
- Swift interop: suspend functions and Flows are awkward from Swift. Use the project's chosen bridge (e.g. SKIE or KMP-NativeCoroutines) or expose callback wrappers; design public APIs of the shared module with Swift callers in mind (no default-argument reliance, clear names, no generics-heavy signatures).
- Keep the shared module's public API small and stable; mark internals `internal`.
- iOS framework size and build time: avoid exporting unnecessary dependencies to the framework.
- Versions: Kotlin, Compose Multiplatform, and library versions must be compatible. Change them together and check the compatibility tables.
- Secrets and tokens: platform secure storage (Keychain/Keystore) via platform implementations, never in common constants.

## Testing

- Tests for shared logic go in `commonTest` with `kotlin.test` and `kotlinx-coroutines-test` (`runTest`); they run on every target.
- Platform-specific behavior: `androidUnitTest`/`iosTest`.
- Fakes over mocks (JVM mocking libraries don't work on Native).

## Review checklist (for tara reviewer agents)

- P1: JVM/Android APIs in `commonMain`; uncaught exceptions crossing into Swift (crash; annotate with `@Throws`); main-thread blocking on iOS; secrets in common code.
- P2: logic duplicated in platform code instead of shared; heavy `expect`/`actual` surfaces; Flow/suspend APIs unusable from Swift; incompatible library versions.
- P3: overly public shared APIs; unused targets/source sets.
