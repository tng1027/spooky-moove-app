/// The side a player plays, independent of the game (OB-042 REQ-001).
///
/// Each game maps it to its own colors (Chess: first = White) and labels
/// (`AppStrings.sideName`); the enum name is never shown.
enum PlayerSide {
  /// Moves first.
  first,

  /// Moves second.
  second;

  PlayerSide get opposite => this == first ? second : first;
}
