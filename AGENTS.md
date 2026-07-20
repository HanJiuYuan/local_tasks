# AI Agent Instructions for LocalTasks

This is a Flutter app with a local-first architecture. The app has no backend service and does not depend on cloud sync.

## What the project is

- Flutter / Dart mobile app.
- `lib/main.dart` launches the app and uses `lib/widget/app/app_shell.dart` for the navigation shell.
- Core feature modules are organized under `lib/widget/`:
  - `home/` — daily task management
  - `nutrition/` — nutrition logging
  - `departure/` — departure checklist
  - `workout/` — workout assistant
- Persistent storage is local SQLite via `sqflite`.
- Local notifications use `flutter_local_notifications`, `flutter_timezone`, and `timezone`.

## Build and test commands

- `flutter pub get`
- `flutter analyze`
- `flutter test`
- `flutter run`
- `flutter build apk --debug`

## Important conventions

- Use Flutter's recommended `analysis_options.yaml` rules; linting is inherited from `package:flutter_lints/flutter.yaml`.
- The app is configured as a private package with `publish_to: 'none'` in `pubspec.yaml`.
- Keep platform-specific generated files and local machine files out of version control.
- The README contains bilingual project context and safe commit guidance.

## Key files and directories

- `lib/main.dart` — app entry point
- `lib/widget/app/app_shell.dart` — main app shell / navigation
- `lib/widget/home/` — task management UI and logic
- `lib/widget/nutrition/` — nutrition tracking
- `lib/widget/departure/` — checklist logic and persistence
- `lib/widget/workout/` — workout assistant and progression logic
- `test/` — widget tests and algorithm tests for workout flow

## Notes for AI tasks

- Prefer editing existing code and feature modules instead of introducing unrelated new structure.
- Preserve existing app behavior around local storage and notification flow.
- When fixing bugs or adding features, validate with `flutter analyze` and `flutter test`.
- Do not modify generated native files such as `ios/Flutter/Generated.xcconfig`, `ios/Flutter/flutter_export_environment.sh`, or `android/local.properties`.

## Reference

- Project overview, feature descriptions, and quick start commands are defined in `README.md`.
