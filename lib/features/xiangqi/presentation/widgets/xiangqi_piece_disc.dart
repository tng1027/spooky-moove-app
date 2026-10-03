import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/game/player_side.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/xiangqi_models.dart';

/// A Xiangqi piece: `keyNormal` disc with the side's rim and its Chinese
/// character from the bundled Noto Serif TC glyphs (OB-044 XQ1, XQ2).
/// Fills the box it is given.
class XiangqiPieceDisc extends StatelessWidget {
  const XiangqiPieceDisc(this.piece, {super.key});

  static const double rimWidth = 2;

  /// Share of the disc the glyph occupies.
  static const double glyphFraction = 0.62;

  final XiangqiPiece piece;

  static String assetFor(XiangqiPiece piece) {
    final side = piece.side == PlayerSide.first ? 'r' : 'b';
    return 'assets/pieces/xiangqi/$side${piece.kind.fenLetter.toUpperCase()}.svg';
  }

  static Color glyphColor(PlayerSide side) =>
      side == PlayerSide.first ? AppColors.pieceRed : AppColors.textPrimary;

  static Color rimColor(PlayerSide side) =>
      side == PlayerSide.first ? AppColors.pieceRed : AppColors.textSecondary;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.keyNormal,
        shape: BoxShape.circle,
        border: Border.all(color: rimColor(piece.side), width: rimWidth),
      ),
      child: FractionallySizedBox(
        widthFactor: glyphFraction,
        heightFactor: glyphFraction,
        child: SvgPicture.asset(
          assetFor(piece),
          fit: BoxFit.contain,
          colorFilter: ColorFilter.mode(
            glyphColor(piece.side),
            BlendMode.srcIn,
          ),
          excludeFromSemantics: true,
        ),
      ),
    );
  }
}
