---
name: react-native
description: Generic React Native and Expo best practices for components, state, performance, native modules, and testing. Use when reading, writing, or reviewing .ts/.tsx/.js/.jsx files, package.json, app.json/app.config, or metro/babel config in a React Native or Expo app.
paths: "**/*.tsx, **/*.ts, **/*.jsx, **/*.js, **/app.json, **/app.config.*, **/metro.config.*, **/babel.config.*"
user-invocable: false
---

# React Native / Expo

Precedence: user's message > project `CLAUDE.md` + `docs/tara-knowledge/project.md` > `docs/tara-knowledge/learnings.md` > this skill.
This skill is generic and follows the official docs (reactnative.dev: Performance, Optimizing FlatList, Security, Accessibility; react.dev; docs.expo.dev). If `project.md` names a state library, navigation, or command, follow it.

## Core rules

- Use the package manager and scripts from `project.md` (matching the lock file). In Expo projects, install native-dependent packages with `npx expo install` so versions match the SDK.
- Function components and hooks. Follow the Rules of Hooks; keep effect dependency arrays complete; clean up subscriptions, timers, and listeners in the effect's return.
- Components render state and call handlers; data fetching, persistence, and business rules live in hooks/services/stores.
- Model async UI explicitly (loading, empty, error, data), or use the project's query library states.
- Lists: `FlatList`/`SectionList` (or the project's list library) for anything that can grow, with a stable `keyExtractor`. Never `ScrollView` + `map` over dynamic data.
- Don't block the JS thread: no heavy sync work in render or handlers. Defer non-urgent work (`InteractionManager`, `requestAnimationFrame`) and use native-driven animations (Reanimated or `useNativeDriver: true`).
- Avoid inline objects/functions as props to memoized children in hot paths; use `useCallback`/`useMemo`/`React.memo` where profiling shows re-renders matter.
- Secrets never live in JS: the bundle is readable. Use `expo-secure-store`/Keychain/Keystore for tokens, never `AsyncStorage` for sensitive data.
- Validate deep-link params and push payloads before navigating or acting on them.
- Accessibility: `accessibilityLabel`/`accessibilityRole` on touchables and icons; respect font scaling (don't set `allowFontScaling={false}` without reason); 44pt/48dp targets.
- Theme colors from the project's theme or `useColorScheme`, not hardcoded hex values.
- Native code (`ios/`, `android/`): follow `ios-swift`/`android-kotlin` skills. With Expo prebuild/CNG, change native config through config plugins, not by hand-editing generated folders.
- Strict TypeScript: no `any` on external data; validate API responses at the boundary.

## Read more only when needed

- Re-renders, lists, startup, animations, memory → read `performance.md`
- Jest, React Native Testing Library, E2E → read `testing.md`

## Review checklist (for tara reviewer agents)

- P1: secrets in JS; tokens in AsyncStorage; unvalidated deep links; state updates after unmount from un-cleaned effects; crashes from unguarded native module calls or undefined data.
- P2: ScrollView over dynamic lists; heavy work on the JS thread; missing keys or unstable keys; missing loading/error states; logic in components; hardcoded colors; missing accessibility labels.
- P3: leftover `console.log`; unnecessary memoization; unused styles.
