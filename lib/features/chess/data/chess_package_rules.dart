import 'package:chess/chess.dart' as lib;

import '../../../core/engine/engine_models.dart';
import '../domain/chess_models.dart';
import '../domain/chess_rules.dart';

/// [ChessRules] over the `chess` package (port of chess.js).
///
/// Game end must never use the package's `in_draw` / `game_over`: they treat
/// the 50-move rule and threefold repetition as automatic draws (OB-024).
class ChessPackageRules implements ChessRules {
  /// Standard start position, or [fen] for tests.
  ChessPackageRules({String? fen})
    : _startFen = fen,
      _chess = fen == null ? lib.Chess() : lib.Chess.fromFEN(fen) {
    if (fen != null && lib.Chess.validate_fen(fen)['valid'] != true) {
      throw ArgumentError.value(fen, 'fen', 'Invalid FEN');
    }
    _onPositionChanged();
    _positionKeys.add(_positionKey());
  }

  final String? _startFen;
  lib.Chess _chess;

  final List<ChessMove> _played = [];
  final List<String> _positionKeys = [];

  late List<lib.Move> _rawMoves;
  late List<ChessMove> _legalMoves;

  @override
  List<ChessMove> get legalMoves => _legalMoves;

  @override
  ChessPiece? pieceAt(ChessSquare square) {
    final piece = _chess.board[_index(square)];
    if (piece == null) return null;
    return ChessPiece(_color(piece.color), _kind(piece.type));
  }

  @override
  PieceColor get sideToMove => _color(_chess.turn);

  @override
  bool get isCheck => _chess.in_check;

  @override
  bool get isCheckmate => isCheck && _legalMoves.isEmpty;

  @override
  bool get isStalemate => !isCheck && _legalMoves.isEmpty;

  @override
  bool get hasInsufficientMaterial => _chess.insufficient_material;

  @override
  int get repetitionCount {
    final current = _positionKeys.last;
    return _positionKeys.where((key) => key == current).length;
  }

  @override
  int get halfmoveClock => _chess.half_moves;

  @override
  String get fen => _chess.fen;

  @override
  int get moveCount => _played.length;

  @override
  void apply(ChessMove move) {
    final index = _legalMoves.indexOf(move);
    if (index < 0) {
      throw ArgumentError.value(move, 'move', 'Not a legal move');
    }
    _chess.make_move(_rawMoves[index]);
    _played.add(move);
    _onPositionChanged();
    _positionKeys.add(_positionKey());
  }

  @override
  ChessMove? undo() {
    if (_played.isEmpty) return null;
    _chess.undo_move();
    _positionKeys.removeLast();
    _onPositionChanged();
    return _played.removeLast();
  }

  @override
  void reset() {
    _chess = _startFen == null ? lib.Chess() : lib.Chess.fromFEN(_startFen);
    _played.clear();
    _positionKeys.clear();
    _onPositionChanged();
    _positionKeys.add(_positionKey());
  }

  @override
  EnginePosition toEnginePosition() {
    final moves = [for (final move in _played) move.uci];
    final startFen = _startFen;
    return startFen == null
        ? EnginePosition.startPos(moves: moves)
        : EnginePosition.fen(startFen, moves: moves);
  }

  @override
  ChessMove? moveFromUci(String uci) {
    for (final move in _legalMoves) {
      if (move.uci == uci) return move;
    }
    return null;
  }

  void _onPositionChanged() {
    _rawMoves = _chess.generate_moves();
    _legalMoves = List.unmodifiable(_rawMoves.map(_toChessMove));
  }

  /// FEN without the move counters. The package always records the en
  /// passant square after a double pawn push; FIDE repetition only counts it
  /// when an en passant capture is actually legal.
  String _positionKey() {
    final fields = _chess.fen.split(' ');
    final hasEnPassant = _legalMoves.any((move) => move.isEnPassant);
    return [
      fields[0],
      fields[1],
      fields[2],
      if (hasEnPassant) fields[3] else '-',
    ].join(' ');
  }

  static ChessMove _toChessMove(lib.Move move) {
    final flags = move.flags;
    final isEnPassant = flags & lib.Chess.BITS_EP_CAPTURE != 0;
    return ChessMove(
      from: _square(move.from),
      to: _square(move.to),
      promotion: move.promotion == null ? null : _kind(move.promotion!),
      isCapture: flags & lib.Chess.BITS_CAPTURE != 0 || isEnPassant,
      castling: flags & lib.Chess.BITS_KSIDE_CASTLE != 0
          ? CastlingSide.kingside
          : flags & lib.Chess.BITS_QSIDE_CASTLE != 0
          ? CastlingSide.queenside
          : null,
      isEnPassant: isEnPassant,
    );
  }

  /// 0x88 board index: rank 8 is row 0.
  static int _index(ChessSquare square) => (7 - square.rank) * 16 + square.file;

  static ChessSquare _square(int index) =>
      ChessSquare(index & 15, 7 - (index >> 4));

  static PieceColor _color(lib.Color color) =>
      color == lib.Color.WHITE ? PieceColor.white : PieceColor.black;

  static PieceKind _kind(lib.PieceType type) => switch (type.name) {
    'p' => PieceKind.pawn,
    'n' => PieceKind.knight,
    'b' => PieceKind.bishop,
    'r' => PieceKind.rook,
    'q' => PieceKind.queen,
    'k' => PieceKind.king,
    _ => throw StateError('Unknown piece type ${type.name}'),
  };
}
