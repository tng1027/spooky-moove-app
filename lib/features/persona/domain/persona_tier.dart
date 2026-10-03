/// The 7 persona tiers, identical for every game (OB-021, OB-022 REQ-001).
///
/// This is the single list of offered tiers (OB-035 design guardrail).
enum PersonaTier {
  baby(1, '🥚', 'Baby'),
  gentle(2, '🐣', 'Gentle'),
  soft(3, '🐥', 'Soft'),
  even(4, '🥉', 'Even'),
  solid(5, '🥈', 'Solid'),
  master(6, '🥇', 'Master'),
  god(7, '👑', 'God');

  const PersonaTier(this.level, this.emoji, this.label);

  final int level;
  final String emoji;
  final String label;
}
