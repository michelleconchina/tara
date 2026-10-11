# Flutter — testing

Run tests with the `test` command in `project.md`. Match the project's existing test folder layout and mocking library (`mocktail`, `mockito`, fakes).

## What to test

- Logic layer (blocs, notifiers, use cases, repositories): unit tests, the bulk of the suite.
- Widgets: loading, empty, error, and data states render; user actions dispatch the right events.
- Integration (`integration_test/`): a few critical flows only (login, checkout, core happy path).
- Golden tests only if the project already uses them; they are platform-sensitive.

## Unit tests

- One behavior per test; name it as the behavior (`'emits error when repository throws'`).
- Fake or mock at the repository/data-source boundary, not deep inside.
- Bloc: use `blocTest` (bloc_test) with `build`, `act`, `expect`, and `verify`.
- Riverpod: use `ProviderContainer` with `overrides`, and `addTearDown(container.dispose)`.
- Test error and edge paths (empty list, null, timeout, 401), not just the happy path.
- No real network, clock, or randomness: inject `http.Client`, a clock, and seeds.

## Widget tests

- Wrap the widget under test in the app's real theme/localization setup (`MaterialApp` + delegates), or the project's test helper if one exists.
- Provide state via the project's state library overrides, not by reaching into private fields.
- `pump()` advances one frame; `pumpAndSettle()` waits for animations but hangs on infinite animations (e.g. `CircularProgressIndicator`). Use `pump(duration)` there.
- Find by `Key`, semantics label, or text. Avoid `find.byType` on generic widgets.
- Verify accessibility basics when relevant: `expect(tester, meetsGuideline(textContrastGuideline))`, `labeledTapTargetGuideline`, `androidTapTargetGuideline`.

## Async gotchas

- Use `fakeAsync` or `tester.pump(duration)` for timers and debounces; never real `Future.delayed` waits.
- Close streams and controllers created in tests (`addTearDown`).
- A test that passes only with `--concurrency=1` has shared state; fix the leak.

## When fixing a failing test

1. Read the failure and the code under test before editing either.
2. Decide whether the test or the code is wrong. Don't weaken assertions just to go green.
3. Re-run only the failing file first, then the full suite.
