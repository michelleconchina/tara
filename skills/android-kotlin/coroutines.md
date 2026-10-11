# Kotlin coroutines and Flow on Android

Source: developer.android.com/kotlin/coroutines/coroutines-best-practices, kotlinlang.org coroutines guide.

- **Inject dispatchers** (`CoroutineDispatcher` constructor params) instead of hardcoding `Dispatchers.IO`, so tests can swap them.
- **Main-safe suspend functions:** the data layer moves work off the main thread (`withContext(ioDispatcher)`); callers can call them from `Main` safely.
- **ViewModel creates coroutines** (`viewModelScope.launch`); lower layers expose `suspend` functions and `Flow`s. Don't launch from repositories unless the work must outlive the screen (then use an injected application-scoped `CoroutineScope`).
- **Never `GlobalScope`.** Never `runBlocking` outside tests and `main()`.
- **Cancellation is cooperative:** check `isActive`/`ensureActive()` in long loops; don't catch `CancellationException` (rethrow it if you catch `Exception`/`Throwable`).
- **Exceptions:** handle with `try/catch` in the coroutine or `catch` on Flows; use `supervisorScope` when one child's failure shouldn't cancel siblings.
- **Expose state as `StateFlow`**: `stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), initial)` for cold flows turned into UI state.
- **One-off events** (navigation, snackbar): prefer modeling them as state that the UI consumes and acknowledges; if using a `Channel`/`SharedFlow`, collect it lifecycle-aware.
- **Flow operators:** `flowOn` to change upstream context; `debounce`/`distinctUntilChanged` for search; `combine` for multiple sources. Avoid `collect` inside `collect` (use `flatMapLatest`).
- **Lifecycle-aware collection** in UI: `collectAsStateWithLifecycle()` (Compose) or `repeatOnLifecycle(Lifecycle.State.STARTED)` (Views).
