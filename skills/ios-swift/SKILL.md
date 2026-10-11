---
name: ios-swift
description: Generic iOS and Swift best practices for SwiftUI, UIKit, Swift concurrency, and XCTest/Swift Testing. Use when reading, writing, or reviewing .swift files, Package.swift, Info.plist, or Xcode project settings in an iOS app (including native iOS modules inside Flutter or React Native apps).
paths: "**/*.swift, **/Package.swift, **/Info.plist, **/*.xcconfig, **/*.entitlements, **/*.xcprivacy"
user-invocable: false
---

# iOS / Swift

Precedence: user's message > project `CLAUDE.md` + `docs/tara-knowledge/project.md` > `docs/tara-knowledge/learnings.md` > this skill.
This skill is generic. If `project.md` names an architecture, UI framework, or command, follow it.

## Core rules

- Use the project's build/test commands from `project.md` (scheme, destination, test plan). Don't guess `xcodebuild` flags.
- Respect the project's Swift language mode and strict-concurrency setting; fix new warnings in code you touch.
- No force unwraps (`!`), `try!`, or `as!` on data from the network, disk, user input, or Objective-C APIs. Use `guard let` / `if let` and handle the failure.
- UI updates on the main actor only. Mark view models and UI types `@MainActor`.
- Prefer `async/await` and structured concurrency over completion handlers and `DispatchQueue` for new code. Read `concurrency.md` before touching tasks, actors, or `Sendable`.
- Break retain cycles: `[weak self]` in escaping closures stored by `self` (Combine sinks, NotificationCenter, timers, callbacks).
- Value types (`struct`, `enum`) by default; `class` when identity or reference semantics are needed. Mark classes `final` unless designed for subclassing.
- Keep business logic out of views and view controllers; views render state and send intents.
- Model screen state explicitly: loading, content, empty, error. Every screen handles all four.
- Secrets and tokens go in the Keychain, never `UserDefaults`, plist files, or source.
- Every privacy-sensitive API needs its `Info.plist` usage string (`NS…UsageDescription`) and an entry in `PrivacyInfo.xcprivacy` for required-reason APIs.
- Support Dynamic Type, Dark Mode, and VoiceOver: semantic fonts and colors, accessibility labels on icon-only controls.
- Don't edit `.pbxproj` by hand unless unavoidable; never touch signing settings, provisioning profiles, or entitlements without explicit approval.
- Use `Logger` (os) with privacy annotations; never log tokens or personal data with `.public`.

## Read more only when needed

- async/await, Task, actors, Sendable, MainActor, Combine → read `concurrency.md`
- SwiftUI views, state (`@State`, `@Observable`, `@Binding`, environment), navigation → read `swiftui.md`
- UIKit view controllers, table/collection views, Auto Layout → read `uikit.md`
- Writing or fixing XCTest, Swift Testing, or UI tests → read `testing.md`

## Review checklist (for tara reviewer agents)

- P1: force unwrap/`try!` on external data; UI mutation off the main actor; retain cycles in long-lived closures; secrets in `UserDefaults` or source; missing usage string or privacy manifest entry (store rejection); data races flagged by strict concurrency.
- P2: heavy work on the main actor; unstructured `Task {}` without cancellation; view body doing work; logic in views; missing loading/error states; no Dynamic Type support.
- P3: non-final classes; leftover `print`; unused code.
