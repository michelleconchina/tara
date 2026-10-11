# Swift — concurrency

Check the project's Swift version and strict-concurrency mode (build settings / `Package.swift` `swiftSettings`) before changing isolation. Follow the project's existing approach; don't migrate a codebase mid-feature.

## Isolation

- Types that drive UI (view models, coordinators, view controllers) are `@MainActor`.
- Shared mutable state lives in an `actor` or behind a `@MainActor` type; never in a global `var` or a class touched from several tasks.
- `nonisolated` only for members that genuinely don't touch isolated state.
- Don't block the main actor: no synchronous file I/O, large decoding, image processing, or `Thread.sleep`. Move it to a non-isolated `async` function or a detached/background context.
- Avoid `DispatchQueue.main.async` inside async code; use `await MainActor.run` or main-actor-isolated functions.
- Never mix locks/semaphores with `await` (`DispatchSemaphore.wait()` in async code can deadlock the cooperative pool).

## Tasks

- Prefer structured concurrency: `async let`, `withTaskGroup`, `withThrowingTaskGroup`.
- Unstructured `Task { }` inherits the actor; keep a handle and cancel it when the owner goes away (`.task {}` in SwiftUI does this for you).
- `Task.detached` only when you deliberately need no inherited isolation or priority.
- Long loops check `try Task.checkCancellation()` or `Task.isCancelled`.
- Capture `self` weakly in long-lived tasks owned by `self`, or cancel the task in `deinit`/`onDisappear`.
- Actor reentrancy: state can change across an `await` inside an actor; re-check invariants after suspension points.

## Sendable

- Values crossing isolation boundaries must be `Sendable`. Prefer making types `Sendable` (immutable structs, actors) over `@unchecked Sendable`.
- `@unchecked Sendable` requires real internal synchronization and a comment explaining it.
- `@preconcurrency import` is a migration tool, not a fix; leave a note.

## Bridging old APIs

- Wrap completion-handler APIs with `withCheckedThrowingContinuation`; resume exactly once on every path (including errors and cancellation).
- Prefer the system's async variants (`URLSession.data(for:)`, etc.) when available.

## Combine

- Store `AnyCancellable`s in a `Set` owned by the subscriber; use `[weak self]` in `sink`.
- `receive(on: DispatchQueue.main)` (or `RunLoop.main`) before touching UI.
- For new code, prefer `AsyncSequence` / `@Observable` unless the project standardizes on Combine.
