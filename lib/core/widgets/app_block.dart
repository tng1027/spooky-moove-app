import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';

/// Isometric block (OB-052 DS-2): a [face] over a solid [side] band
/// [AppDimens.blockDepth] high, both inside the block's own box, so the
/// depth never changes layout. Solid fills only: no blur, shadow or gradient.
///
/// With [onTap] the block is a key: the face sinks onto its base while held
/// (instant under reduce motion). A null [side] draws the block lowered with
/// no extrusion (disabled keys).
class AppBlock extends StatefulWidget {
  const AppBlock({
    required this.face,
    required this.side,
    required this.child,
    this.hasHighlight = false,
    this.radius = AppDimens.radius,
    this.onTap,
    super.key,
  });

  final Color face;
  final Color? side;

  /// A 1 dp `edgeHighlight` top edge, for neutral faces only.
  final bool hasHighlight;

  /// Corner radius of the face and the side; 4 dp except the new-game panel.
  final double radius;

  final VoidCallback? onTap;
  final Widget child;

  @override
  State<AppBlock> createState() => _AppBlockState();
}

class _AppBlockState extends State<AppBlock> {
  bool _isPressed = false;

  void _setPressed(bool isPressed) {
    if (_isPressed != isPressed) setState(() => _isPressed = isPressed);
  }

  @override
  void didUpdateWidget(AppBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Disabling mid-press drops the recognizer without an onTapCancel.
    if (widget.onTap == null) _isPressed = false;
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.all(Radius.circular(widget.radius));
    final side = widget.side;
    final onTap = widget.onTap;
    final isSunk = side == null || (_isPressed && onTap != null);
    final disableAnimations =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final block = TweenAnimationBuilder<double>(
      tween: Tween(end: isSunk ? AppDimens.blockDepth : 0),
      duration: disableAnimations ? Duration.zero : AppDimens.pressSinkDuration,
      curve: AppDimens.pressSinkCurve,
      child: DecoratedBox(
        decoration: BoxDecoration(color: widget.face, borderRadius: radius),
        child: widget.child,
      ),
      builder: (context, sink, face) => Stack(
        fit: StackFit.passthrough,
        // Always the same three children, so toggling a state never rebuilds
        // the face's subtree.
        children: [
          Positioned.fill(
            top: sink,
            child: DecoratedBox(
              decoration: BoxDecoration(color: side, borderRadius: radius),
            ),
          ),
          Transform.translate(
            offset: Offset(0, sink),
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppDimens.blockDepth),
              child: face,
            ),
          ),
          Positioned(
            top: sink,
            left: widget.radius,
            right: widget.radius,
            height: 1,
            child: ColoredBox(
              color: widget.hasHighlight && side != null
                  ? AppColors.edgeHighlight
                  : const Color(0x00000000),
            ),
          ),
        ],
      ),
    );
    final isEnabled = onTap != null;
    return GestureDetector(
      behavior: isEnabled
          ? HitTestBehavior.opaque
          : HitTestBehavior.deferToChild,
      onTap: onTap,
      onTapDown: isEnabled ? (_) => _setPressed(true) : null,
      onTapUp: isEnabled ? (_) => _setPressed(false) : null,
      onTapCancel: isEnabled ? () => _setPressed(false) : null,
      child: block,
    );
  }
}
