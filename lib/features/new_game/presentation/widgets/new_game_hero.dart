import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/game/player_side.dart';
import '../../domain/game_kind.dart';
import '../game_registry.dart';

/// Top-face pattern of the hero slab, picked per game in `game_registry.dart`.
enum HeroPattern { checker, intersectionGrid }

/// Decorative isometric board on the new-game screen (OB-052 DS-8): a flat
/// 2:1 slab in the game's accent pair with the two sides' pieces standing on
/// it. Solid fills only (no glow, blur, gradient or layers), static, and
/// excluded from semantics. [height] comes from the screen's visibility rule.
class NewGameHero extends StatelessWidget {
  const NewGameHero({required this.game, required this.height, super.key});

  /// Hero visibility (OB-052 DS-8), shared by the Home hero (DS-9).
  static const double minBodyHeight = 700;
  static const double maxTextScale = 1.3;

  /// Heroes only fit tall screens at normal text sizes, so the screen's main
  /// content stays visible without scrolling. [bodyHeight] is the height
  /// inside the `SafeArea`.
  static bool isShown(BuildContext context, double bodyHeight) =>
      bodyHeight >= minBodyHeight &&
      MediaQuery.textScalerOf(context).scale(1) <= maxTextScale;

  final GameKind game;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        height: height,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final geometry = _HeroGeometry(constraints.biggest);
            return Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _SlabPainter(
                      face: game.accent,
                      side: game.accentSide,
                      pattern: GameWidgets.heroPattern(game),
                    ),
                  ),
                ),
                for (final side in PlayerSide.values)
                  Positioned.fromRect(
                    rect: geometry.pieceRect(side),
                    child: GameWidgets.sidePictogram(game, side),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Shared by the painter and the piece layout. The top face is a diamond
/// `w` wide and `w / 2` high; the side faces hang `0.1 × w` below it.
class _HeroGeometry {
  _HeroGeometry(Size size)
    : width = math.min(0.75 * size.width, 1.6 * size.height),
      center = Offset(
        size.width / 2,
        size.height / 2 - 0.05 * math.min(0.75 * size.width, 1.6 * size.height),
      );

  final double width;

  /// Centre of the top face; the slab plus its depth is centred in the box.
  final Offset center;

  double get depth => 0.1 * width;
  double get pieceSize => 0.22 * width;

  Offset get top => center.translate(0, -width / 4);
  Offset get right => center.translate(width / 2, 0);
  Offset get bottom => center.translate(0, width / 4);
  Offset get left => center.translate(-width / 2, 0);

  /// A point of the top face: [u] runs from the top corner to the right
  /// corner, [v] from the top corner to the left corner, both 0–1.
  Offset onFace(double u, double v) =>
      top + (right - top) * u + (left - top) * v;

  /// Pieces stand at ⅓ and ⅔ along the long (horizontal) diagonal.
  Offset pieceBase(PlayerSide side) => Offset(
    left.dx + width * (side == PlayerSide.first ? 1 / 3 : 2 / 3),
    center.dy,
  );

  Rect pieceRect(PlayerSide side) {
    final base = pieceBase(side);
    return Rect.fromLTWH(
      base.dx - pieceSize / 2,
      base.dy - pieceSize * 0.82,
      pieceSize,
      pieceSize,
    );
  }
}

class _SlabPainter extends CustomPainter {
  const _SlabPainter({
    required this.face,
    required this.side,
    required this.pattern,
  });

  static const int _checkerCells = 4;
  static const int _gridFiles = 5;
  static const int _gridRanks = 6;
  static const double _gridInset = 0.1;
  static const double _gridLineWidth = 1.5;

  final Color face;
  final Color side;
  final HeroPattern pattern;

  @override
  void paint(Canvas canvas, Size size) {
    final g = _HeroGeometry(size);
    final sidePaint = Paint()..color = side;
    final down = Offset(0, g.depth);

    canvas
      ..drawPath(
        _polygon([g.left, g.bottom, g.bottom + down, g.left + down]),
        sidePaint,
      )
      ..drawPath(
        _polygon([g.bottom, g.right, g.right + down, g.bottom + down]),
        sidePaint,
      )
      ..drawPath(
        _polygon([g.top, g.right, g.bottom, g.left]),
        Paint()..color = face,
      );

    switch (pattern) {
      case HeroPattern.checker:
        _paintChecker(canvas, g);
      case HeroPattern.intersectionGrid:
        _paintGrid(canvas, g);
    }

    for (final player in PlayerSide.values) {
      canvas.drawOval(
        Rect.fromCenter(
          center: g.pieceBase(player),
          width: g.pieceSize,
          height: 0.08 * g.width,
        ),
        sidePaint,
      );
    }
  }

  void _paintChecker(Canvas canvas, _HeroGeometry g) {
    final dark = Paint()
      ..color = Color.alphaBlend(side.withValues(alpha: 0.4), face);
    const step = 1 / _checkerCells;
    for (var i = 0; i < _checkerCells; i++) {
      for (var j = 0; j < _checkerCells; j++) {
        if ((i + j).isEven) continue;
        final u = i * step;
        final v = j * step;
        canvas.drawPath(
          _polygon([
            g.onFace(u, v),
            g.onFace(u + step, v),
            g.onFace(u + step, v + step),
            g.onFace(u, v + step),
          ]),
          dark,
        );
      }
    }
  }

  void _paintGrid(Canvas canvas, _HeroGeometry g) {
    final line = Paint()
      ..color = side
      ..strokeWidth = _gridLineWidth
      ..style = PaintingStyle.stroke;
    const span = 1 - 2 * _gridInset;
    double file(int i) => _gridInset + span * i / (_gridFiles - 1);
    double rank(int j) => _gridInset + span * j / (_gridRanks - 1);
    const riverAbove = _gridRanks ~/ 2 - 1;

    for (var j = 0; j < _gridRanks; j++) {
      canvas.drawLine(
        g.onFace(file(0), rank(j)),
        g.onFace(file(_gridFiles - 1), rank(j)),
        line,
      );
    }
    for (var i = 0; i < _gridFiles; i++) {
      final isEdge = i == 0 || i == _gridFiles - 1;
      if (isEdge) {
        canvas.drawLine(
          g.onFace(file(i), rank(0)),
          g.onFace(file(i), rank(_gridRanks - 1)),
          line,
        );
        continue;
      }
      canvas
        ..drawLine(
          g.onFace(file(i), rank(0)),
          g.onFace(file(i), rank(riverAbove)),
          line,
        )
        ..drawLine(
          g.onFace(file(i), rank(riverAbove + 1)),
          g.onFace(file(i), rank(_gridRanks - 1)),
          line,
        );
    }
  }

  static Path _polygon(List<Offset> points) => Path()..addPolygon(points, true);

  @override
  bool shouldRepaint(_SlabPainter oldDelegate) =>
      face != oldDelegate.face ||
      side != oldDelegate.side ||
      pattern != oldDelegate.pattern;
}
