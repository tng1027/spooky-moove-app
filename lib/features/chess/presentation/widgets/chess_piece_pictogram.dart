import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../domain/chess_models.dart';

/// Monochrome piece pictogram from the bundled Cburnett set (no letters).
class ChessPiecePictogram extends StatelessWidget {
  const ChessPiecePictogram(this.piece, {super.key});

  final ChessPiece piece;

  static String assetFor(ChessPiece piece) {
    final color = piece.color == PieceColor.white ? 'w' : 'b';
    final kind = piece.kind.uciLetter.toUpperCase();
    return 'assets/pieces/cburnett/$color$kind.svg';
  }

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      assetFor(piece),
      fit: BoxFit.contain,
      excludeFromSemantics: true,
    );
  }
}
