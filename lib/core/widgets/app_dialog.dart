import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_typography.dart';
import 'app_block.dart';

/// Small centred dialog: a neutral `surfaceDark` isometric block with a
/// header title above [children]. The content scrolls, so large text scales
/// never overflow.
class AppDialog extends StatelessWidget {
  const AppDialog({
    required this.title,
    required this.spokenTitle,
    required this.children,
    super.key,
  });

  final String title;

  /// What a screen reader says; upper-case titles would be spelled out.
  final String spokenTitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: AppBlock(
        face: AppColors.surfaceDark,
        side: AppColors.surfaceSide,
        hasHighlight: true,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimens.spacingLarge),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppDimens.spacingLarge,
            children: [
              Semantics(
                header: true,
                label: spokenTitle,
                excludeSemantics: true,
                child: Text(title, style: AppTypography.primary),
              ),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}
