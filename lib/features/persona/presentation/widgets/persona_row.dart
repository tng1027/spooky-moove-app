import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_dimens.dart';
import '../../domain/persona_tier.dart';
import '../persona_tier_controller.dart';
import 'persona_tier_keys.dart';

/// Advisor row of the 7 persona tier keys (OB-023), bound to the current
/// game's tier.
class PersonaRow extends ConsumerWidget {
  const PersonaRow({super.key = regionKey});

  static const Key regionKey = Key('advisor.personaRow');

  static Key tierKey(PersonaTier tier) => Key('personaRow.${tier.name}');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: AppDimens.personaRowHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.spacingSmall,
          vertical: AppDimens.spacingSmall / 2,
        ),
        child: PersonaTierKeys(
          selected: ref.watch(personaTierProvider),
          onSelected: ref.read(personaTierProvider.notifier).select,
          tierKey: tierKey,
        ),
      ),
    );
  }
}
