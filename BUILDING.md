# Building SpookyMoove

This is the complete corresponding source for the released app, including the
Fairy-Stockfish engine (git submodule) and its build configuration.

## Toolchain used for release 1.0.0+1

| Tool | Version |
|---|---|
| Flutter | 3.47.6 stable, framework revision `5fc346839b5d0eef006ed8404392afb4dfae428d` |
| Dart | 3.13.5 |
| Xcode | 27.0 (27A266a) |
| macOS | 26.6.2 (25G83) |

Dart package versions are pinned in `pubspec.lock`. Update this table for every
release.

## Get the source

```sh
git clone --recurse-submodules https://github.com/tng1027/spooky-moove-app.git
cd spooky-moove-app
git checkout v1.0.0+2   # the tag of the build you installed: v<version>+<build>
git submodule update --init --recursive
```

The engine must be at commit `433d4115a31ebcf0d9c0e4238b12915b70a0b7c1`
(`git submodule status`).

## Build

The engine is compiled automatically by the Dart build hook `hook/build.dart`
together with `native/fairy_stockfish_shim/`.

```sh
flutter pub get
flutter test
flutter build ipa --release      # iOS
flutter build apk --release      # Android
```

## Install a modified build on your own iPhone

1. Open `ios/Runner.xcworkspace` in Xcode.
2. In Runner → Signing & Capabilities, select your own team (a free personal
   Apple ID works) and change the bundle identifier to a unique value.
3. Connect the iPhone, enable Developer Mode on it, and run
   `flutter run --release` (or Product → Run in Xcode).

Builds signed with a free Apple ID expire after 7 days and can be reinstalled
the same way.
