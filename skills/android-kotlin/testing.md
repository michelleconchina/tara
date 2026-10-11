# Android — testing

Source: developer.android.com/training/testing. Run tests with the `test` command in `project.md`.

- **Local unit tests** (`src/test`, JVM) are the bulk: ViewModels, use cases, repositories, mappers.
- **Instrumented tests** (`src/androidTest`) for code that needs Android framework behavior, plus a few UI flows.
- **Fakes over mocks** at layer boundaries (fake repository, fake data source); mock only what you can't fake.
- **Coroutines:** `runTest` from `kotlinx-coroutines-test`; inject a `StandardTestDispatcher`/`UnconfinedTestDispatcher`; replace `Dispatchers.Main` with `Dispatchers.setMain` in a rule or extension, and reset it after.
- **Flows:** collect in `backgroundScope`, or use Turbine if the project already does; assert emitted UI states in order (loading → content/error).
- **Compose UI tests:** `createComposeRule()`; find nodes by semantics (`onNodeWithText`, `onNodeWithContentDescription`, `onNodeWithTag`); assert states for loading/empty/error/content.
- **Robolectric** only if the project already uses it.
- Name tests by behavior; test failure and edge paths, not only the happy path.
- When fixing a failing test: read the failure and code first, decide whether test or code is wrong, never weaken assertions to go green, re-run the single test (`--tests <pattern>`) then the suite.
