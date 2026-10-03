import 'dart:typed_data';

import '../../../core/engine/engine_models.dart';
import '../../../core/game/player_side.dart';
import '../domain/xiangqi_models.dart';
import '../domain/xiangqi_rules.dart';

/// Hand-written [XiangqiRules] on a 9 x 10 mailbox (OB-043, XQ11).
///
/// Cells hold 0 for empty, `kind.index + 1` for Red and its negation for
/// Black. Index = rank * 9 + file, rank 0 on Red's side.
class DartXiangqiRules implements XiangqiRules {
  /// Standard start position, or [fen] for tests (the product always starts
  /// from the initial position, OB-001 Q3).
  DartXiangqiRules({String? fen}) : _startFen = fen {
    _load(fen ?? startFen);
  }

  static const String startFen =
      'rnbakabnr/9/1c5c1/p1p1p1p1p/9/9/P1P1P1P1P/1C5C1/9/RNBAKABNR w - - 0 1';

  static const int _files = XiangqiPoint.files;
  static const int _ranks = XiangqiPoint.ranks;

  static const int _general = 1;
  static const int _advisor = 2;
  static const int _elephant = 3;
  static const int _horse = 4;
  static const int _chariot = 5;
  static const int _cannon = 6;
  static const int _soldier = 7;

  static const List<(int, int)> _orthogonal = [
    (0, 1),
    (0, -1),
    (1, 0),
    (-1, 0),
  ];
  static const List<(int, int)> _diagonal = [
    (1, 1),
    (1, -1),
    (-1, 1),
    (-1, -1),
  ];

  final String? _startFen;
  final Int8List _board = Int8List(_files * _ranks);

  /// 1 = Red to move, -1 = Black.
  int _turn = 1;
  int _halfmoveClock = 0;
  int _startFullmove = 1;
  bool _startsWithBlack = false;

  final List<XiangqiMove> _played = [];
  final List<int> _halfmoveHistory = [];
  late List<XiangqiMove> _legalMoves;

  @override
  List<XiangqiMove> get legalMoves => _legalMoves;

  @override
  XiangqiPiece? pieceAt(XiangqiPoint point) =>
      _pieceOf(_board[_index(point.file, point.rank)]);

  @override
  PlayerSide get sideToMove =>
      _turn == 1 ? PlayerSide.first : PlayerSide.second;

  @override
  bool get isCheck => _isGeneralAttacked(_turn);

  @override
  bool get hasNoLegalMoves => _legalMoves.isEmpty;

  @override
  int get moveCount => _played.length;

  @override
  String get fen {
    final rows = <String>[];
    for (var rank = _ranks - 1; rank >= 0; rank--) {
      final row = StringBuffer();
      var empty = 0;
      for (var file = 0; file < _files; file++) {
        final cell = _board[_index(file, rank)];
        if (cell == 0) {
          empty++;
          continue;
        }
        if (empty > 0) row.write(empty);
        empty = 0;
        final letter = XiangqiPieceKind.values[cell.abs() - 1].fenLetter;
        row.write(cell > 0 ? letter.toUpperCase() : letter);
      }
      if (empty > 0) row.write(empty);
      rows.add(row.toString());
    }
    final plies = _played.length + (_startsWithBlack ? 1 : 0);
    final fullmove = _startFullmove + plies ~/ 2;
    final side = _turn == 1 ? 'w' : 'b';
    return '${rows.join('/')} $side - - $_halfmoveClock $fullmove';
  }

  @override
  void apply(XiangqiMove move) {
    if (!_legalMoves.contains(move)) {
      throw ArgumentError.value(move, 'move', 'Not a legal move');
    }
    final from = _index(move.from.file, move.from.rank);
    final to = _index(move.to.file, move.to.rank);
    _halfmoveHistory.add(_halfmoveClock);
    _halfmoveClock = _board[to] == 0 ? _halfmoveClock + 1 : 0;
    _board[to] = _board[from];
    _board[from] = 0;
    _turn = -_turn;
    _played.add(move);
    _onPositionChanged();
  }

  @override
  XiangqiMove? undo() {
    if (_played.isEmpty) return null;
    final move = _played.removeLast();
    final from = _index(move.from.file, move.from.rank);
    final to = _index(move.to.file, move.to.rank);
    _board[from] = _board[to];
    _board[to] = _cellOf(move.captured);
    _turn = -_turn;
    _halfmoveClock = _halfmoveHistory.removeLast();
    _onPositionChanged();
    return move;
  }

  @override
  void reset() => _load(_startFen ?? startFen);

  @override
  EnginePosition toEnginePosition() {
    final moves = [for (final move in _played) move.uci];
    final startFen = _startFen;
    return startFen == null
        ? EnginePosition.startPos(moves: moves)
        : EnginePosition.fen(startFen, moves: moves);
  }

  @override
  XiangqiMove? moveFromUci(String uci) {
    for (final move in _legalMoves) {
      if (move.uci == uci) return move;
    }
    return null;
  }

  /// Leaf-node count of the legal move tree, for validation against the
  /// engine's `go perft` and for timing. Leaves the position unchanged.
  int perft(int depth) {
    if (depth <= 0) return 1;
    final moves = _generateLegal();
    if (depth == 1) return moves.length;
    var nodes = 0;
    for (final move in moves) {
      final from = move >> 7;
      final to = move & 127;
      final captured = _board[to];
      _board[to] = _board[from];
      _board[from] = 0;
      _turn = -_turn;
      nodes += perft(depth - 1);
      _turn = -_turn;
      _board[from] = _board[to];
      _board[to] = captured;
    }
    return nodes;
  }

  void _load(String fen) {
    final fields = fen.trim().split(RegExp(r'\s+'));
    final rows = fields.first.split('/');
    if (rows.length != _ranks) {
      throw ArgumentError.value(fen, 'fen', 'Expected 10 ranks');
    }
    _board.fillRange(0, _board.length, 0);
    for (var row = 0; row < _ranks; row++) {
      final rank = _ranks - 1 - row;
      var file = 0;
      for (final char in rows[row].split('')) {
        final empty = int.tryParse(char);
        if (empty != null) {
          file += empty;
          continue;
        }
        final kind = XiangqiPieceKind.values.where(
          (k) => k.fenLetter == char.toLowerCase(),
        );
        if (kind.isEmpty || file >= _files) {
          throw ArgumentError.value(fen, 'fen', 'Invalid rank "${rows[row]}"');
        }
        final code = kind.single.index + 1;
        _board[_index(file, rank)] = char == char.toUpperCase() ? code : -code;
        file++;
      }
      if (file != _files) {
        throw ArgumentError.value(fen, 'fen', 'Invalid rank "${rows[row]}"');
      }
    }
    _turn = fields.length > 1 && fields[1] == 'b' ? -1 : 1;
    _startsWithBlack = _turn == -1;
    _halfmoveClock = fields.length > 4 ? int.tryParse(fields[4]) ?? 0 : 0;
    _startFullmove = fields.length > 5 ? int.tryParse(fields[5]) ?? 1 : 1;
    _played.clear();
    _halfmoveHistory.clear();
    _onPositionChanged();
  }

  void _onPositionChanged() {
    _legalMoves = List.unmodifiable([
      for (final move in _generateLegal())
        XiangqiMove(
          from: _point(move >> 7),
          to: _point(move & 127),
          captured: _pieceOf(_board[move & 127]),
        ),
    ]);
  }

  /// Legal moves of the side to move, encoded as `from << 7 | to`.
  List<int> _generateLegal() {
    final legal = <int>[];
    final side = _turn;
    for (final move in _generatePseudo(side)) {
      final from = move >> 7;
      final to = move & 127;
      final captured = _board[to];
      _board[to] = _board[from];
      _board[from] = 0;
      final isLegal = !_isGeneralAttacked(side);
      _board[from] = _board[to];
      _board[to] = captured;
      if (isLegal) legal.add(move);
    }
    return legal;
  }

  List<int> _generatePseudo(int side) {
    final moves = <int>[];
    for (var from = 0; from < _board.length; from++) {
      final cell = _board[from];
      if (cell == 0 || cell.sign != side) continue;
      final file = from % _files;
      final rank = from ~/ _files;

      void addIfFree(int toFile, int toRank) {
        if (!_onBoard(toFile, toRank)) return;
        final to = _index(toFile, toRank);
        if (_board[to].sign != side) moves.add(from << 7 | to);
      }

      switch (cell.abs()) {
        case _general:
          for (final (df, dr) in _orthogonal) {
            if (_inPalace(file + df, rank + dr, side)) {
              addIfFree(file + df, rank + dr);
            }
          }
        case _advisor:
          for (final (df, dr) in _diagonal) {
            if (_inPalace(file + df, rank + dr, side)) {
              addIfFree(file + df, rank + dr);
            }
          }
        case _elephant:
          for (final (df, dr) in _diagonal) {
            final toFile = file + 2 * df;
            final toRank = rank + 2 * dr;
            if (!_onBoard(toFile, toRank) || !_onOwnSide(toRank, side)) {
              continue;
            }
            if (_board[_index(file + df, rank + dr)] != 0) continue;
            addIfFree(toFile, toRank);
          }
        case _horse:
          for (final (df, dr) in _orthogonal) {
            if (!_onBoard(file + df, rank + dr)) continue;
            if (_board[_index(file + df, rank + dr)] != 0) continue;
            if (df == 0) {
              addIfFree(file + 1, rank + 2 * dr);
              addIfFree(file - 1, rank + 2 * dr);
            } else {
              addIfFree(file + 2 * df, rank + 1);
              addIfFree(file + 2 * df, rank - 1);
            }
          }
        case _chariot:
          for (final (df, dr) in _orthogonal) {
            var f = file + df;
            var r = rank + dr;
            while (_onBoard(f, r)) {
              final target = _board[_index(f, r)];
              if (target == 0) {
                moves.add(from << 7 | _index(f, r));
              } else {
                if (target.sign != side) moves.add(from << 7 | _index(f, r));
                break;
              }
              f += df;
              r += dr;
            }
          }
        case _cannon:
          for (final (df, dr) in _orthogonal) {
            var f = file + df;
            var r = rank + dr;
            var hasScreen = false;
            while (_onBoard(f, r)) {
              final target = _board[_index(f, r)];
              if (!hasScreen) {
                if (target == 0) {
                  moves.add(from << 7 | _index(f, r));
                } else {
                  hasScreen = true;
                }
              } else if (target != 0) {
                if (target.sign != side) moves.add(from << 7 | _index(f, r));
                break;
              }
              f += df;
              r += dr;
            }
          }
        case _soldier:
          addIfFree(file, rank + side);
          if (!_onOwnSide(rank, side)) {
            addIfFree(file + 1, rank);
            addIfFree(file - 1, rank);
          }
      }
    }
    return moves;
  }

  /// Whether [side]'s general is attacked by the other side, including the
  /// two generals facing each other on an open file ("flying general").
  bool _isGeneralAttacked(int side) {
    final general = _board.indexOf(side * _general);
    if (general < 0) return false;
    final file = general % _files;
    final rank = general ~/ _files;
    final enemy = -side;

    for (final (df, dr) in _orthogonal) {
      var f = file + df;
      var r = rank + dr;
      var screens = 0;
      while (_onBoard(f, r)) {
        final cell = _board[_index(f, r)];
        if (cell != 0) {
          if (screens == 0) {
            if (cell == enemy * _chariot) return true;
            if (df == 0 && cell == enemy * _general) return true;
            if (cell == enemy * _soldier &&
                (f - file).abs() + (r - rank).abs() == 1) {
              final forward = r + enemy == rank && f == file;
              final sideways = r == rank && !_onOwnSide(r, enemy);
              if (forward || sideways) return true;
            }
          } else if (screens == 1) {
            if (cell == enemy * _cannon) return true;
            break;
          }
          screens++;
        }
        f += df;
        r += dr;
      }
    }

    // A horse at (file + hf, rank + hr) reaches the general unless its leg,
    // one orthogonal step from the horse towards the general, is occupied.
    for (final (hf, hr) in const [
      (1, 2),
      (-1, 2),
      (1, -2),
      (-1, -2),
      (2, 1),
      (2, -1),
      (-2, 1),
      (-2, -1),
    ]) {
      final f = file + hf;
      final r = rank + hr;
      if (!_onBoard(f, r) || _board[_index(f, r)] != enemy * _horse) continue;
      final legFile = hf.abs() == 2 ? f - hf ~/ 2 : f;
      final legRank = hr.abs() == 2 ? r - hr ~/ 2 : r;
      if (_board[_index(legFile, legRank)] == 0) return true;
    }
    return false;
  }

  static bool _onBoard(int file, int rank) =>
      file >= 0 && file < _files && rank >= 0 && rank < _ranks;

  /// Red's half is ranks 0..4, Black's 5..9.
  static bool _onOwnSide(int rank, int side) =>
      side == 1 ? rank <= 4 : rank >= 5;

  static bool _inPalace(int file, int rank, int side) {
    if (file < 3 || file > 5) return false;
    return side == 1 ? rank >= 0 && rank <= 2 : rank >= 7 && rank <= 9;
  }

  static int _index(int file, int rank) => rank * _files + file;

  static XiangqiPoint _point(int index) =>
      XiangqiPoint(index % _files, index ~/ _files);

  static XiangqiPiece? _pieceOf(int cell) {
    if (cell == 0) return null;
    return XiangqiPiece(
      cell > 0 ? PlayerSide.first : PlayerSide.second,
      XiangqiPieceKind.values[cell.abs() - 1],
    );
  }

  static int _cellOf(XiangqiPiece? piece) {
    if (piece == null) return 0;
    final code = piece.kind.index + 1;
    return piece.side == PlayerSide.first ? code : -code;
  }
}
