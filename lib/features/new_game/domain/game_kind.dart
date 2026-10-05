/// Games offered in the new-game flow, in display order (OB-011 REQ-002).
///
/// This is the single place that decides which games are available; later
/// phases register a game by adding a value here.
enum GameKind {
  chess(engineVariant: 'chess', files: 8, ranks: 8),
  xiangqi(engineVariant: 'xiangqi', files: 9, ranks: 10);

  const GameKind({
    required this.engineVariant,
    required this.files,
    required this.ranks,
  });

  /// Fairy-Stockfish `UCI_Variant` value (OB-042 REQ-005).
  final String engineVariant;

  /// Board grid size, for the advisor layout.
  final int files;
  final int ranks;
}
