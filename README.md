# spookymoove

Offline multi-board game advisor (Flutter).

## Setup

The Fairy-Stockfish engine source is a git submodule:

```sh
git submodule update --init
```

The engine is compiled by the Dart build hook in `hook/build.dart` (native
assets, enabled by default on Flutter stable). No CMake or Xcode project
changes are needed; `flutter run` / `flutter build` compile it automatically.
Host builds such as `flutter test` skip the engine.

## Tests

- Widget tests: `flutter test`
- Engine integration test (device or simulator only):
  `flutter test integration_test/fairy_stockfish_engine_test.dart -d <device>`
