# Jetpack Compose

Source: developer.android.com/develop/ui/compose (state, performance, lists, accessibility).

## State

- Hoist state: stateless composables take `value` + `onValueChange`. The screen-level composable gets state from the ViewModel and passes plain values down.
- `remember` for state that survives recomposition; `rememberSaveable` for state that must survive configuration change/process death.
- Never pass the ViewModel deep into the tree; pass state and lambdas.
- Use `derivedStateOf` when a value derived from fast-changing state (scroll position) changes less often than its input.
- Side effects only in effect handlers: `LaunchedEffect(key)`, `DisposableEffect` (with `onDispose`), `rememberCoroutineScope` for event-driven launches. Never launch coroutines or mutate state directly in composition.

## Performance

- Composition must be cheap and side-effect free: no I/O, sorting, formatting, or object allocation that could be remembered.
- Keep parameters stable: immutable data classes, `kotlinx.collections.immutable` or `@Immutable`/`@Stable` where appropriate. Unstable params (e.g. `List` from a mutable source) defeat skipping.
- Defer state reads: pass lambdas (`{ scrollState.value }`) and use lambda-based modifiers (`Modifier.offset { }`, `graphicsLayer { }`) for frequently changing values.
- Lists: `LazyColumn`/`LazyRow`/`LazyVerticalGrid` with stable `key = { it.id }` and `contentType`. Never `Column` + `forEach` over dynamic data, and never nest same-direction scrollables.
- Check performance in release builds with Baseline Profiles. Debug builds are much slower.

## UI quality

- Accessibility: `contentDescription` on meaningful images/icons (`null` for decorative); `Modifier.semantics` for custom controls; 48×48 dp minimum touch targets.
- Text in `sp`; test with large font scale; avoid fixed heights that clip text.
- Colors and typography from `MaterialTheme`; support dark theme.
- Handle insets (`WindowInsets`, `Modifier.safeDrawingPadding()`/`imePadding()`), especially with edge-to-edge enforced on recent Android versions.
- Previews with fake data; no real network in `@Preview`.
