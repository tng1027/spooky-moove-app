import 'package:flutter/material.dart';

import '../theme/app_dimens.dart';
import '../theme/app_typography.dart';
import 'app_key.dart';

/// Three-slot screen header (OB-050 BR-001): a key in each corner and a
/// label centred between them, in a [AppDimens.topBarHeight] row.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({this.leading, this.middle, this.trailing, super.key});

  /// Each corner key may take at most this share of the header, so the label
  /// keeps room at large text scales (the key labels scale down instead).
  static const double maxKeyWidthFraction = 0.3;

  final Widget? leading;
  final Widget? middle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final leading = this.leading;
    final trailing = this.trailing;
    return SizedBox(
      height: AppDimens.topBarHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxKeyWidth = constraints.maxWidth * maxKeyWidthFraction;
          return NavigationToolbar(
            leading: leading == null ? null : _cornerKey(leading, maxKeyWidth),
            middle: middle,
            trailing: trailing == null
                ? null
                : _cornerKey(trailing, maxKeyWidth),
            middleSpacing: AppDimens.spacing,
          );
        },
      ),
    );
  }

  /// AppKey fills bounded widths, so the key is sized to its content, capped
  /// at [maxWidth].
  static Widget _cornerKey(Widget key, double maxWidth) => ConstrainedBox(
    constraints: BoxConstraints(maxWidth: maxWidth),
    child: IntrinsicWidth(child: key),
  );
}

/// A text key for a [ScreenHeader] corner: the label scales down instead of
/// wrapping.
class HeaderKey extends StatelessWidget {
  const HeaderKey({
    required this.label,
    required this.semanticsLabel,
    required this.onTap,
    super.key,
  });

  final String label;

  /// What a screen reader says; upper-case labels would be spelled out.
  final String semanticsLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppKey(
      onTap: onTap,
      child: Semantics(
        label: semanticsLabel,
        excludeSemantics: true,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(label, style: AppTypography.primary),
        ),
      ),
    );
  }
}
