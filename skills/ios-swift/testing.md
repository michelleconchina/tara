# iOS — testing

Run tests with the `test` command in `project.md` (scheme, destination, test plan). Match the project's framework: Swift Testing (`import Testing`, `@Test`, `#expect`) or XCTest. Don't mix them in one file.

## What to test

- View models, use cases, services, and parsers: unit tests, the bulk of the suite.
- Async code: test success, failure, and cancellation.
- UI tests (`XCUITest`): a few critical flows only; they're slow and flaky by nature.
- Snapshot tests only if the project already uses a snapshot library.

## Unit tests

- Inject dependencies through protocols or closures; use fakes/stubs, not real network or disk.
- Use a `URLProtocol` stub or an injected client for networking.
- One behavior per test; name it as the behavior.
- Test `@MainActor` types from `@MainActor` test functions or types.
- Swift Testing: `@Test(arguments:)` for parameterized cases; `#require` to unwrap and stop.
- XCTest: `async throws` test methods instead of `XCTestExpectation` when the code is async; `XCTUnwrap` instead of `!`.
- Control time and randomness: inject a clock (`Clock` protocol) and seeds.

## UI tests

- Locate elements by `accessibilityIdentifier`, not by visible text that changes with localization.
- Use launch arguments/environment to put the app in a known state (mock backend, skip onboarding).
- Wait with `waitForExistence(timeout:)`, never `sleep`.

## Leaks

- Add a helper that asserts an object is deallocated at the end of a test (`addTeardownBlock { [weak sut] in XCTAssertNil(sut) }`) for view models and controllers with closures.

## When fixing a failing test

1. Read the failure and the code under test before editing either.
2. Decide whether the test or the code is wrong. Don't weaken assertions just to go green.
3. Re-run only the failing test first (`-only-testing:`), then the full suite.
