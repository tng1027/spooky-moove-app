import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/persona_tier.dart';

/// Persona tier of the current game; null until the user picks one
/// (OB-021 D5). Move selection listens to it to recompute (OB-022).
final personaTierProvider =
    NotifierProvider<PersonaTierController, PersonaTier?>(
      PersonaTierController.new,
    );

class PersonaTierController extends Notifier<PersonaTier?> {
  @override
  PersonaTier? build() => null;

  /// Selects [tier]; tapping the selected tier again changes nothing.
  void select(PersonaTier tier) {
    if (state == tier) return;
    state = tier;
    HapticFeedback.selectionClick();
  }

  /// Sets the tier picked on the new-game screen, or none, when a new game
  /// starts (OB-011). No haptic: the pick already gave one.
  void reset([PersonaTier? tier]) => state = tier;
}
