/// The 7 persona tiers, identical for every game (OB-021, OB-022 REQ-001).
///
/// This is the single list of offered tiers (OB-035 design guardrail).
/// User-facing names live in `persona_tier_copy.dart` (OB-054).
enum PersonaTier {
  baby(1),
  gentle(2),
  soft(3),
  even(4),
  solid(5),
  master(6),
  god(7);

  const PersonaTier(this.level);

  final int level;
}
