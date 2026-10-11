# UIKit

## View controllers

- Keep view controllers thin: layout, binding, and forwarding events. Logic and networking live in a view model, presenter, or interactor per the project's architecture.
- Do setup in `viewDidLoad`; layout-dependent work in `viewDidLayoutSubviews` (it runs many times, so keep it idempotent).
- Don't start work in `viewWillAppear` that isn't cancelled in `viewWillDisappear`.
- Child view controllers: `addChild` → add view → `didMove(toParent:)`, and the reverse on removal.
- Check for leaks: a dismissed controller should hit `deinit`. Common causes are closures capturing `self`, strong delegates, timers, and NotificationCenter block observers.
- Delegates are `weak var delegate: SomeDelegate?` with an `AnyObject`-constrained protocol.

## Lists

- `UICollectionView` / `UITableView` with diffable data sources and compositional layout for new code.
- Diffable item identifiers must be stable and unique; apply snapshots on the main thread.
- Reuse cells; reset state in `prepareForReuse`; cancel per-cell image loads there.
- No synchronous image decoding or heavy work in `cellForRowAt` / cell configuration.

## Auto Layout

- `translatesAutoresizingMaskIntoConstraints = false` for views laid out in code; activate constraints in batches (`NSLayoutConstraint.activate`).
- No ambiguous or conflicting constraints; check the console for "Unable to simultaneously satisfy constraints".
- Use layout margins and safe area guides; avoid hardcoded device sizes.
- Prefer `UIStackView` for linear layouts.

## Accessibility and appearance

- `UIFont.preferredFont(forTextStyle:)` with `adjustsFontForContentSizeCategory = true`, or `UIFontMetrics` for custom fonts; let labels wrap (`numberOfLines = 0`).
- System/semantic colors (`.label`, `.systemBackground`) or asset colors with dark variants; react to `traitCollectionDidChange` / trait registration when using `CGColor`s.
- `isAccessibilityElement`, `accessibilityLabel`, and traits on custom controls; minimum 44×44 pt targets.

## Interop

- Hosting SwiftUI in UIKit: `UIHostingController`, added as a proper child view controller.
- Storyboards/XIBs: keep outlets `weak` (except top-level objects), and don't rename classes or outlets without updating the IB file.
