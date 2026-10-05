// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 SpookyMoove authors. Part of SpookyMoove; derived from
// Fairy-Stockfish (see NOTICE.md).

// Compiles upstream main.cpp with its entry point renamed to fs_main. Every
// header main.cpp uses is included first, so the rename only touches main().

#include <iostream>

#include "bitboard.h"
#include "endgame.h"
#include "position.h"
#include "psqt.h"
#include "search.h"
#include "syzygy/tbprobe.h"
#include "thread.h"
#include "tt.h"
#include "uci.h"

#include "piece.h"
#include "variant.h"
#include "xboard.h"

#define main fs_main
#include "main.cpp"
#undef main
