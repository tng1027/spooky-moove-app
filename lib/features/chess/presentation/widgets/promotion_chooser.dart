import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../domain/chess_models.dart';
import 'chess_piece_pictogram.dart';

/// Covers the board with a barrier and offers the four promotion pieces,
/// queen first. Tapping the barrier cancels.
class PromotionChooser extends StatelessWidget {
  const PromotionChooser({
    required this.color,
    required this.keySize,
    required this.onChosen,
    required this.onCancel,
    this.highlighted,
    super.key,
  });

  static const Key barrierKey = Key('promotion.barrier');

  static Key choiceKey(PieceKind kind) => Key('promotion.${kind.name}');

  final PieceColor color;

  /// Side of one key; never below the 48 dp key minimum.
  final double keySize;
  final ValueChanged<PieceKind> onChosen;
  final VoidCallback onCancel;

  /// Pre-highlighted piece, e.g. the suggested promotion.
  final PieceKind? highlighted;

  @override
  Widget build(BuildContext context) {
    final size = math.max(keySize, AppDimens.minKeyHeight);
    return Stack(
      fit: StackFit.expand,
      children: [
        GestureDetector(
          key: barrierKey,
          behavior: HitTestBehavior.opaque,
          onTap: onCancel,
          child: ColoredBox(color: AppColors.bgDark.withValues(alpha: 0.7)),
        ),
        Center(
          child: ColoredBox(
            color: AppColors.surfaceDark,
            child: Padding(
              padding: const EdgeInsets.all(AppDimens.spacing),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: AppDimens.spacing,
                children: [
                  for (final kind in PieceKind.promotionChoices)
                    _ChoiceKey(
                      key: choiceKey(kind),
                      piece: ChessPiece(color, kind),
                      size: size,
                      isHighlighted: kind == highlighted,
                      onTap: () => onChosen(kind),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ChoiceKey extends StatelessWidget {
  const _ChoiceKey({
    required this.piece,
    required this.size,
    required this.isHighlighted,
    required this.onTap,
    super.key,
  });

  final ChessPiece piece;
  final double size;
  final bool isHighlighted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        padding: const EdgeInsets.all(AppDimens.spacingSmall),
        decoration: BoxDecoration(
          color: isHighlighted ? AppColors.accentActive : AppColors.keyNormal,
          borderRadius: const BorderRadius.all(
            Radius.circular(AppDimens.radius),
          ),
        ),
        child: ChessPiecePictogram(piece),
      ),
    );
  }
}
