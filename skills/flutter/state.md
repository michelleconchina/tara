# Flutter — state management

Use the library and layering named in `project.md`. Don't introduce a second state library.

## All libraries

- One source of truth per piece of state. Don't copy the same state into a widget field and a store.
- State objects are immutable. Copy with `copyWith`, never mutate in place and re-emit the same instance (equality checks will skip the rebuild).
- Use value equality (`Equatable`, `freezed`, or `==`/`hashCode`) for states that are compared.
- UI → events/intents → logic layer → repository → data source. Widgets never call repositories or HTTP clients directly.
- Inject dependencies (constructor, provider, or service locator per project). Don't instantiate repositories inside widgets or blocs.
- Errors become state (an error variant or field), not uncaught exceptions or `print`.
- Scope state to the smallest subtree that needs it. App-wide stores are for app-wide data only.

## Bloc / Cubit (flutter_bloc)

- Close what you create: `BlocProvider(create:)` closes it; `BlocProvider.value` does not, so the owner must.
- Use `BlocBuilder` with `buildWhen` / `BlocSelector` to limit rebuilds; use `BlocListener` for one-off effects (navigation, snackbars), never `BlocBuilder`.
- Never `emit` after `close` (check `isClosed` after awaits in Cubits).
- Use event transformers (`droppable`, `restartable`, `sequential` from bloc_concurrency) for search and repeated taps instead of hand-rolled flags.
- No `BuildContext` inside a Bloc.

## Riverpod

- `ref.watch` in `build`, `ref.read` in callbacks, `ref.listen` for side effects. Never `ref.read` in `build` to avoid rebuilds.
- Use `autoDispose` (or generated providers, which default to it) for screen-scoped state; keep-alive only on purpose.
- Use `select` to watch one field of a large state.
- Handle `AsyncValue` with `when`/`switch` covering loading, error, and data.
- Don't store `ref` in long-lived objects; don't use `ref` after the provider is disposed (check `ref.mounted` where available).

## Provider / ChangeNotifier

- `ChangeNotifierProvider(create:)` disposes; `.value` does not.
- Use `context.select` or `Selector` instead of `context.watch` on big notifiers.
- Don't call `notifyListeners()` during `build` or after `dispose`.

## GetX / MobX

- GetX: avoid global `Get.put` for screen-scoped controllers; use bindings so controllers are deleted on route pop. Don't mix GetX navigation with Navigator 2 / go_router in the same flow.
- MobX: mutate observables only inside actions; dispose reactions (`ReactionDisposer`); regenerate `.g.dart` after store changes.

## setState

- Fine for local, ephemeral UI state (a toggle, a text field). Lift to the project's state library once two widgets need it or it survives navigation.
