---
name: flutter
description: Generic Flutter and Dart best practices for widgets, state management, performance, and testing. Use when reading, writing, or reviewing .dart files, pubspec.yaml, or analysis_options.yaml in a Flutter app.
paths: "**/*.dart, **/pubspec.yaml, **/analysis_options.yaml"
user-invocable: false
---

# Flutter

Precedence: user's message > project `CLAUDE.md` + `docs/tara-knowledge/project.md` > `docs/tara-knowledge/learnings.md` > this skill.
This skill is generic. If `project.md` names a state library, architecture, or command, follow it.

## Core rules

- Use the project's commands from `project.md` (test, analyze, format). Don't assume `flutter test` or `dart analyze` flags.
- Fix new analyzer warnings in code you touch; don't silence lints with `// ignore:` unless asked.
- Prefer small `StatelessWidget` classes over helper methods that return widgets (better rebuild scoping and `const`).
- Use `const` constructors wherever possible.
- Keep `build()` pure: no I/O, no allocations of controllers/streams, no `setState`, no navigation.
- Create controllers (`TextEditingController`, `AnimationController`, `ScrollController`, `StreamSubscription`, `FocusNode`) in `initState` or the state library's lifecycle, and dispose them.
- After any `await` in a `State`, check `if (!mounted) return;` before using `context` or calling `setState`. In other widgets, check `context.mounted`.
- Never put business logic, HTTP calls, or parsing in widgets. Widgets render state and forward events.
- Model async UI as explicit states: loading, data, empty, error. Every screen handles all four.
- Use `ListView.builder` / `SliverList` / `GridView.builder` for lists that can grow; never `Column` + `map` over unbounded data.
- Don't block the UI isolate: JSON decoding of large payloads, image processing, and crypto go through `compute` / `Isolate.run`.
- Respect text scaling (`MediaQuery.textScalerOf`) and semantics; never hardcode heights that clip text.
- Get theme colors from `Theme.of(context).colorScheme`, never hardcoded `Colors.*` (breaks dark mode).
- Platform channels: validate arguments on both sides; handle `MissingPluginException` and `PlatformException`.
- Generated files (`*.g.dart`, `*.freezed.dart`, `*.gr.dart`) are never edited by hand. Rerun the generator.
- Secrets never live in Dart source or assets; they ship in the binary. Use `flutter_secure_storage` for tokens, not `shared_preferences`.

## Read more only when needed

- Writing or reviewing state management code (Bloc, Riverpod, Provider, GetX, MobX, setState) → read `state.md`
- Performance work, jank, large lists, images, animations, memory → read `performance.md`
- Writing or fixing unit, widget, golden, or integration tests → read `testing.md`

## Review checklist (for tara reviewer agents)

- P1: `setState`/`context` after `await` without `mounted` check; undisposed controllers or subscriptions; secrets in source; force-unwrap `!` on nullable data from network/storage; missing error state that leaves the user stuck.
- P2: heavy work in `build()` or on the UI isolate; non-builder lists over dynamic data; missing `const`; logic in widgets; hardcoded colors or text sizes.
- P3: helper methods returning widgets; dead code; unused imports the analyzer would not auto-fix.
