/// FFI bindings for `native/fairy_stockfish_shim/fairy_stockfish_shim.h`.
///
/// The library is compiled and bundled by `hook/build.dart`.
@DefaultAsset('package:spookymoove/fairy_stockfish')
library;

import 'dart:ffi';

import 'package:ffi/ffi.dart';

const int fsOk = 0;
const int fsAlreadyRunning = 1;
const int fsThreadError = 2;
const int fsNotRunning = 3;

const String fsExitSentinel = 'fs_exit';
const String fsErrorPrefix = 'info string fs_error: ';

typedef FsLineCallback = Void Function(Pointer<Utf8> line);

@Native<Int32 Function(Pointer<NativeFunction<FsLineCallback>>)>(
  symbol: 'fs_start',
)
external int fsStart(Pointer<NativeFunction<FsLineCallback>> onLine);

@Native<Void Function(Pointer<Utf8>)>(symbol: 'fs_send')
external void fsSend(Pointer<Utf8> line);

@Native<Void Function(Pointer<Utf8>)>(symbol: 'fs_free')
external void fsFree(Pointer<Utf8> line);

@Native<Int32 Function()>(symbol: 'fs_join')
external int fsJoin();
