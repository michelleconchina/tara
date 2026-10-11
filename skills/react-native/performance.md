# React Native — performance

Source: reactnative.dev/docs/performance, reactnative.dev/docs/optimizing-flatlist-configuration.

- **Measure in release builds** (or with the profiler in a production-like build). Dev mode is much slower. Use React DevTools Profiler for re-renders and the platform profilers for native work.
- **Re-renders:** keep state as low in the tree as possible; split contexts so frequent updates don't re-render everything; select narrow slices from stores (selectors in Redux/Zustand).
- **Lists:** `keyExtractor` with stable ids; memoized `renderItem` and item components; `getItemLayout` when rows have a fixed height; tune `windowSize`, `initialNumToRender`, `maxToRenderPerBatch` only after measuring; avoid anonymous functions in row props.
- **Images:** size images to their display size; cache network images (the project's image library); avoid huge local assets.
- **Animations:** run on the UI thread (Reanimated worklets, or `useNativeDriver: true` with `Animated`). Don't animate layout from JS every frame.
- **JS thread:** move heavy computation off render; debounce text input handlers; batch state updates.
- **Startup:** lazy-load screens (navigation lazy loading); keep the root component light; avoid large synchronous imports at startup; Hermes is the default engine, so don't disable it.
- **Memory leaks:** clear timers/intervals, remove event listeners and subscriptions in effect cleanup, cancel in-flight requests (`AbortController`) on unmount.
- **Console:** `console.log` in hot paths slows release builds unless stripped; remove it.
