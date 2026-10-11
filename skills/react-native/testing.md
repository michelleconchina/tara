# React Native — testing

Source: reactnative.dev/docs/testing-overview, callstack.github.io/react-native-testing-library. Run tests with the `test` command in `project.md`.

- **Unit tests (Jest)** for hooks, stores, reducers, services, and utils: the bulk of the suite.
- **Component tests (React Native Testing Library):** render with the app's providers (theme, store, query client, navigation container, or the project's test helper); query by role/label/text (`getByRole`, `getByLabelText`, `getByText`) as a user would; use `userEvent`/`fireEvent` for interactions; assert loading, empty, error, and data states.
- **Async:** use `findBy*`/`waitFor`; fake timers (`jest.useFakeTimers()`) for debounce/timeouts; no real network (mock fetch/axios at the boundary or use MSW if the project does).
- **Native modules:** mock them in Jest setup (`jest.mock`), following the library's documented mock when one exists.
- **E2E (Detox/Maestro)** only for a few critical flows, if the project already uses them.
- Avoid snapshot tests of large trees; they break on every change and catch little.
- When fixing a failing test: read the failure and code first, decide whether test or code is wrong, never weaken assertions to go green, re-run the single test file then the suite.
