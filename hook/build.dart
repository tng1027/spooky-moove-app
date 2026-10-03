import 'dart:io';

import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';
import 'package:logging/logging.dart';
import 'package:native_toolchain_c/native_toolchain_c.dart';

const _engineSourceDir = 'third_party/fairy-stockfish/src';
const _shimSourceDir = 'native/fairy_stockfish_shim';

/// Upstream engine sources, mirroring `SRCS` in the upstream Makefile minus
/// `main.cpp`, which is compiled through `fairy_stockfish_main.cpp`.
const _engineSources = [
  'benchmark.cpp',
  'bitbase.cpp',
  'bitboard.cpp',
  'endgame.cpp',
  'evaluate.cpp',
  'material.cpp',
  'misc.cpp',
  'movegen.cpp',
  'movepick.cpp',
  'pawns.cpp',
  'position.cpp',
  'psqt.cpp',
  'search.cpp',
  'thread.cpp',
  'timeman.cpp',
  'tt.cpp',
  'uci.cpp',
  'ucioption.cpp',
  'tune.cpp',
  'syzygy/tbprobe.cpp',
  'nnue/evaluate_nnue.cpp',
  'nnue/features/half_ka_v2.cpp',
  'nnue/features/half_ka_v2_variants.cpp',
  'partner.cpp',
  'parser.cpp',
  'piece.cpp',
  'variant.cpp',
  'xboard.cpp',
];

const _shimSources = [
  'fairy_stockfish_shim.cpp',
  'fairy_stockfish_main.cpp',
];

final _supportedTargets = {
  OS.android: {Architecture.arm64, Architecture.x64},
  OS.iOS: {Architecture.arm64, Architecture.x64},
};

void main(List<String> args) async {
  await build(args, (input, output) async {
    if (!input.config.buildCodeAssets) return;

    final logger = Logger.detached('fairy_stockfish')
      ..level = Level.INFO
      ..onRecord.listen((record) => stderr.writeln(record.message));

    final code = input.config.code;
    final os = code.targetOS;
    final architecture = code.targetArchitecture;
    final supportedArchitectures = _supportedTargets[os];

    // Host builds (e.g. `flutter test` on macOS) run widget tests only and
    // do not need the engine; skipping keeps them fast.
    if (supportedArchitectures == null) {
      logger.info('Skipping Fairy-Stockfish build for unsupported OS $os.');
      return;
    }
    if (!supportedArchitectures.contains(architecture)) {
      throw UnsupportedError(
        'Fairy-Stockfish is not built for $os/$architecture. '
        'Supported: $supportedArchitectures.',
      );
    }

    final builder = CBuilder.library(
      name: 'fairy_stockfish',
      assetName: 'fairy_stockfish',
      language: Language.cpp,
      std: 'c++17',
      linkModePreference: LinkModePreference.dynamic,
      cppLinkStdLib: os == OS.android ? 'c++_static' : null,
      sources: [
        for (final source in _engineSources) '$_engineSourceDir/$source',
        for (final source in _shimSources) '$_shimSourceDir/$source',
      ],
      includes: [_engineSourceDir, _shimSourceDir],
      defines: {
        'IS_64BIT': null,
        'USE_PTHREADS': null,
        'USE_POPCNT': null,
        'LARGEBOARDS': null,
        'PRECOMPUTED_MAGICS': null,
        'NNUE_EMBEDDING_OFF': null,
        if (architecture == Architecture.arm64) 'USE_NEON': null,
        if (architecture == Architecture.x64) 'USE_SSE2': null,
      },
      flags: [
        '-fvisibility=hidden',
        '-fvisibility-inlines-hidden',
        '-ffunction-sections',
        '-fdata-sections',
        if (architecture == Architecture.x64) ...['-msse4.2', '-mpopcnt'],
        '-Wno-deprecated-declarations',
      ],
    );

    await builder.run(input: input, output: output, logger: logger);
  });
}
