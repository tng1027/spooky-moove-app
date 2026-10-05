# NOTICE

SpookyMoove
Copyright (C) 2026 SpookyMoove authors

This program is free software: you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation, either version 3 of the License, or (at your option) any later
version. See [LICENSE](LICENSE).

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

Source code: https://github.com/tng1027/spooky-moove-app (tag matching the
released version, e.g. `v1.0.0`). Build instructions: [BUILDING.md](BUILDING.md).

## Fairy-Stockfish (GPLv3)

- Copyright (C) 2004-2021 The Stockfish developers and the Fairy-Stockfish
  authors; see `third_party/fairy-stockfish/AUTHORS`.
- License: GNU GPL v3 or later (`third_party/fairy-stockfish/Copying.txt`).
- Upstream: https://github.com/fairy-stockfish/Fairy-Stockfish
- Mirror used by this app: https://github.com/tng1027/Fairy-Stockfish
- Version: tag `fairy_sf_14_0_1_xq`, commit
  `433d4115a31ebcf0d9c0e4238b12915b70a0b7c1` (git submodule
  `third_party/fairy-stockfish`).

### Modifications (GPLv3 section 5a)

Upstream files are used unmodified. SpookyMoove modifies how the engine is
built and run, on 2026-10-05 and earlier:

- `native/fairy_stockfish_shim/fairy_stockfish_main.cpp` compiles upstream
  `src/main.cpp` with `main` renamed to `fs_main`, so the engine runs on a
  thread inside the app process instead of as a separate executable.
- `native/fairy_stockfish_shim/fairy_stockfish_shim.cpp` / `.h` redirect
  `std::cin`/`std::cout`/`std::cerr` to in-memory queues and expose a C API
  (`fs_start`, `fs_send`, `fs_join`) used from Dart FFI.
- `hook/build.dart` compiles a subset of upstream sources into a dynamic
  library with the defines `IS_64BIT`, `USE_PTHREADS`, `USE_POPCNT`,
  `LARGEBOARDS`, `PRECOMPUTED_MAGICS`, `NNUE_EMBEDDING_OFF`, and `USE_NEON`
  (arm64) or `USE_SSE2` (x64). No NNUE network file is bundled.

## Bundled assets

- JetBrains Mono — Copyright 2020 The JetBrains Mono Project Authors, SIL Open
  Font License 1.1 (`assets/fonts/OFL.txt`).
- Noto Serif TC (Xiangqi glyphs) — SIL Open Font License 1.1
  (`assets/pieces/xiangqi/OFL.txt`).
- Cburnett chess pieces — Copyright (c) Colin M.L. Burnett, BSD license, black
  outline recolored (`assets/pieces/cburnett/LICENSE`).

## Dart and Flutter packages

Packages listed in `pubspec.lock` (including `chess`, `flutter_riverpod`,
`flutter_svg`, `ffi`, `shared_preferences`, `logging`) and the Flutter engine
are under BSD, MIT or Apache-2.0 licenses. Their full texts are shown in the app
under Settings → About & Licenses → Open-source packages.
