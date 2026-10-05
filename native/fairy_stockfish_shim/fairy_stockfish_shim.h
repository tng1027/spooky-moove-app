// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 SpookyMoove authors. Part of SpookyMoove; derived from
// Fairy-Stockfish (see NOTICE.md).

#ifndef FAIRY_STOCKFISH_SHIM_H
#define FAIRY_STOCKFISH_SHIM_H

#ifdef __cplusplus
extern "C" {
#endif

#define FS_EXPORT __attribute__((visibility("default")))

#define FS_OK 0
#define FS_ALREADY_RUNNING 1
#define FS_THREAD_ERROR 2
#define FS_NOT_RUNNING 3

// Emitted as the last line after the engine loop has returned.
#define FS_EXIT_SENTINEL "fs_exit"
// Prefix of the line emitted when the engine thread throws.
#define FS_ERROR_PREFIX "info string fs_error: "

// Called from the engine thread once per output line, without the trailing
// newline. The callee owns `line` and must release it with fs_free().
typedef void (*fs_line_callback)(char* line);

// Starts the engine on a dedicated native thread. Only one engine can run per
// process because Fairy-Stockfish keeps its state in globals.
FS_EXPORT int fs_start(fs_line_callback on_line);

// Queues one command line for the engine. Never blocks on a running search.
FS_EXPORT void fs_send(const char* line);

FS_EXPORT void fs_free(char* line);

// Waits for the engine thread to finish (send "quit" first) and restores the
// original standard streams. After it returns, fs_start() may be called again.
FS_EXPORT int fs_join(void);

#ifdef __cplusplus
}
#endif

#endif
