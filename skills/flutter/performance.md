# Flutter — performance

Measure before optimizing: profile mode (`--profile`) + DevTools (Performance, CPU, Memory). Debug mode timing is meaningless.

## Rebuilds

- Push state down: the widget that calls `setState`/watches a provider should be as small as possible.
- `const` widgets are skipped during rebuild; add `const` aggressively.
- Pass `child:` to `AnimatedBuilder`, `ValueListenableBuilder`, `Consumer`, etc. for the subtree that doesn't change.
- Avoid `MediaQuery.of(context)` in deep widgets; use `MediaQuery.sizeOf` / `paddingOf` etc. to depend on one field.
- Don't create new objects that are compared by identity in `build` (e.g. `Future`s passed to `FutureBuilder`, streams to `StreamBuilder`); create them in `initState` or the state layer.
- Give list items stable `Key`s when items can be reordered, inserted, or removed.

## Lists and scrolling

- Builders (`ListView.builder`, `SliverList.builder`, `GridView.builder`) for anything unbounded. Set `itemExtent` / `prototypeItem` when items have a fixed height.
- Don't nest scrollables with `shrinkWrap: true` over large data; use slivers (`CustomScrollView`).
- Paginate network data; don't load thousands of rows into memory.

## Rendering

- Avoid `Opacity` and `ClipRRect`/`ClipPath` on large or animated subtrees; prefer `AnimatedOpacity`/`FadeTransition` and pre-shaped decorations.
- `saveLayer` triggers (`ShaderMask`, `ColorFilter`, `Opacity` with children) are costly; use sparingly.
- Wrap independently animating regions in `RepaintBoundary` (verify with DevTools repaint rainbow).
- Images: size them (`cacheWidth`/`cacheHeight` or `ResizeImage`) to display size; use a cache for network images; precache hero images.

## Isolates and async

- Parse large JSON, process images, hash, or encrypt off the UI isolate (`compute`, `Isolate.run`).
- Don't `await` sequential independent futures; use `Future.wait`.
- Debounce search input and other high-frequency events.

## Memory and leaks

- Dispose every controller, `FocusNode`, `StreamSubscription`, `Timer`, `AnimationController`, and `ChangeNotifier` you create.
- Don't hold `BuildContext` or `State` in closures that outlive the widget (timers, stream listeners, singletons).
- Cancel subscriptions in `dispose`, not just on success paths.

## Startup

- Keep `main()` lean: defer non-critical init (analytics, remote config) until after first frame.
- Avoid large synchronous asset loads at startup; use deferred imports on web.
