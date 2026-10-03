import '../../../core/game/player_side.dart';

/// Games offered in the new-game flow, in display order (OB-011 REQ-002).
///
/// This is the single place that decides which games are available; later
/// phases register a game by adding a value here.
enum GameKind {
  chess(
    'CHESS',
    engineVariant: 'chess',
    files: 8,
    ranks: 8,
    firstSideLabel: 'WHITE',
    secondSideLabel: 'BLACK',
  ),
  xiangqi(
    'XIANGQI',
    engineVariant: 'xiangqi',
    files: 9,
    ranks: 10,
    firstSideLabel: 'RED',
    secondSideLabel: 'BLACK',
  );

  const GameKind(
    this.label, {
    required this.engineVariant,
    required this.files,
    required this.ranks,
    required this.firstSideLabel,
    required this.secondSideLabel,
  });

  final String label;

  /// Fairy-Stockfish `UCI_Variant` value (OB-042 REQ-005).
  final String engineVariant;

  /// Board grid size, for the advisor layout.
  final int files;
  final int ranks;

  final String firstSideLabel;
  final String secondSideLabel;

  /// The user-visible name of [side] in this game (OB-042 REQ-001).
  String sideLabel(PlayerSide side) =>
      side == PlayerSide.first ? firstSideLabel : secondSideLabel;
}
