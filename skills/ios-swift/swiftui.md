# SwiftUI

Check the deployment target in `project.md`/build settings before using newer APIs (`@Observable` needs iOS 17; `NavigationStack` iOS 16). Use `if #available` for newer APIs when the target is lower.

## State ownership

- `@State` for local, private view state; always `private`. Owns `@Observable` models created by the view (iOS 17+).
- `@StateObject` (pre-iOS 17 `ObservableObject`) when the view creates the model; `@ObservedObject` only when it's passed in. Never create a model with `@ObservedObject var vm = VM()` (recreated on every parent update).
- `@Binding` to let a child edit parent state; `@Bindable` for bindings into `@Observable` models.
- `@Environment` for app-wide dependencies; don't pass the same object through five initializers.
- One source of truth: don't copy model data into `@State` and let it drift.

## Body and performance

- `body` is cheap and pure: no network calls, no formatting with new `DateFormatter`s, no sorting large arrays. Precompute in the model.
- Split large views into small subviews so changes invalidate less.
- With `ObservableObject`, every `@Published` change invalidates all observers; with `@Observable`, only views that read the changed property. Read only what you need.
- `List` / `LazyVStack` / `LazyVGrid` for long collections; `ForEach` needs stable, unique `id`s (never `\.self` on non-unique values or array indices for mutable data).
- Avoid `AnyView`; use `@ViewBuilder` or `Group`.
- Use `.task {}` for async work tied to a view's lifetime (auto-cancelled), not `onAppear { Task { } }`.

## Navigation

- `NavigationStack` with value-based `navigationDestination` and a path in the model for programmatic navigation.
- Sheets and alerts driven by optional/identifiable state, not multiple booleans.

## Accessibility and appearance

- Semantic fonts (`.body`, `.headline`) and `@ScaledMetric` for custom sizes; test at the largest accessibility sizes.
- Semantic colors (`.primary`, `Color(.systemBackground)`, asset catalog colors with dark variants).
- `accessibilityLabel` on icon-only buttons and images; `accessibilityHidden(true)` on decorative images; group related elements with `accessibilityElement(children: .combine)`.
- Minimum 44×44 pt tap targets.

## Previews

- Keep previews compiling; use mock data, never real network or credentials.
