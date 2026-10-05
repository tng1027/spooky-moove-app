import 'package:flutter/material.dart';

import '../../domain/persona_tier.dart';

/// The approved one-colour icon of a tier (OB-054 D9), shared by the level
/// keys and the new-game level card. Fixed size, so it never clips at large
/// text scales; decorative, so it is excluded from semantics.
class PersonaTierIcon extends StatelessWidget {
  const PersonaTierIcon({required this.tier, required this.color, super.key});

  static const double size = 24;

  final PersonaTier tier;
  final Color color;

  static IconData iconFor(PersonaTier tier) => switch (tier) {
    PersonaTier.baby => Icons.egg_alt,
    PersonaTier.gentle => Icons.military_tech,
    PersonaTier.soft => Icons.local_cafe,
    PersonaTier.even => Icons.balance,
    PersonaTier.solid => Icons.pets,
    PersonaTier.master => Icons.business_center,
    PersonaTier.god => Icons.psychology,
  };

  @override
  Widget build(BuildContext context) {
    return Icon(iconFor(tier), size: size, color: color);
  }
}
