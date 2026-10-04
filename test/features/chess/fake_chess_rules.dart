import 'package:spookymoove/core/engine/engine_models.dart';
import 'package:spookymoove/features/chess/domain/chess_models.dart';
import 'package:spookymoove/features/chess/domain/chess_rules.dart';

/// Scripted [ChessRules]: a fixed piece placement and legal-move list that
/// records applied moves without changing the position.
class FakeChessRules implements ChessRules {
  FakeChessRules({
    this.pieces = const {},
    this.legalMoves = const [],
    this.sideToMove = PieceColor.white,
    this.isCheck = false,
  });

  final Map<ChessSquare, ChessPiece> pieces;
  final List<ChessMove> applied = [];

  @override
  final List<ChessMove> legalMoves;

  @override
  final PieceColor sideToMove;

  @override
  final bool isCheck;

  @override
  ChessPiece? pieceAt(ChessSquare square) => pieces[square];

  @override
  bool get isCheckmate => isCheck && legalMoves.isEmpty;

  @override
  bool get isStalemate => !isCheck && legalMoves.isEmpty;

  @override
  bool get hasInsufficientMaterial => false;

  @override
  int get repetitionCount => 1;

  @override
  int get halfmoveClock => 0;

  @override
  String get fen => 'fake';

  @override
  int get moveCount => applied.length;

  @override
  void apply(ChessMove move) {
    if (!legalMoves.contains(move)) throw ArgumentError.value(move, 'move');
    applied.add(move);
  }

  @override
  ChessMove? undo() => applied.isEmpty ? null : applied.removeLast();

  @override
  void reset() => applied.clear();

  @override
  EnginePosition toEnginePosition() =>
      EnginePosition.startPos(moves: [for (final m in applied) m.uci]);

  @override
  ChessMove? moveFromUci(String uci) {
    for (final move in legalMoves) {
      if (move.uci == uci) return move;
    }
    return null;
  }
}
