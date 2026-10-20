---
name: flutter-patterns
description: Use when building Flutter apps with widget composition, state management, navigation, animations, or platform channels.
---

# Flutter Patterns

## When to Use This Skill
- Building UIs with composable widgets
- Managing state with Riverpod or Bloc
- Navigating between screens with named routes
- Adding animations and transitions
- Communicating with native code via platform channels

## Workflow
1. Create a project: `flutter create my_app`
2. Build the UI: compose widgets from small, reusable components
3. Add state management: `flutter_riverpod` or `flutter_bloc`
4. Set up navigation: `Navigator.push` or named routes with `GoRouter`
5. Add animations: `AnimationController` with `Tween` for custom animations
6. For native code: create platform channels to call iOS/Android APIs
7. Test: `flutter test` for unit and widget tests
8. Build: `flutter build apk` for Android, `flutter build ios` for iOS

## Rules
- Keep widgets small and focused — one widget, one responsibility
- Use `const` constructors for performance
- Prefer composition over inheritance — small widgets combined, not large monoliths
- Use `setState` only for local state — Riverpod or Bloc for app-wide state
- Test on real devices, not just simulators
- Handle platform differences with media queries and platform checks
