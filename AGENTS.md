# AGENTS.md

## Flutter conventions

- Use Flutter and Dart idiomatic style with `flutter_lints`.
- Use Riverpod for app state, providers belong in `lib/` and app bootstraps with `ProviderScope`.
- Keep Digital Atelier token usage centralized in theme code and consume via `ThemeData`.
- Prefer small widgets and test widget behavior with `flutter_test` using `pumpWidget` + `expect`.

## Mission note

- `TRANSFORMFIT-DOCTRINE.md` (added in M1) is required binding reading for all agents.

## Commit convention

- Use concise, milestone-prefixed commit messages, for example: `M0: ...`, `M1: ...`.
