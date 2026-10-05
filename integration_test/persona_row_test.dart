import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:spookymoove/app.dart';
import 'package:spookymoove/core/theme/app_colors.dart';
import 'package:spookymoove/core/widgets/app_block.dart';
import 'package:spookymoove/features/advisor/presentation/widgets/suggestion_card.dart';
import 'package:spookymoove/features/fair_play/domain/fair_play_notice.dart';
import 'package:spookymoove/features/fair_play/presentation/fair_play_controller.dart';
import 'package:spookymoove/features/new_game/domain/game_kind.dart';
import 'package:spookymoove/features/new_game/presentation/home_screen.dart';
import 'package:spookymoove/features/new_game/presentation/new_game_screen.dart';
import 'package:spookymoove/features/persona/domain/persona_tier.dart';
import 'package:spookymoove/features/persona/presentation/persona_tier_controller.dart';
import 'package:spookymoove/features/persona/presentation/widgets/persona_row.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Real app on the simulator. `SHOT:<name>` lines mark states that stay on
/// screen for [_hold] so an external script can capture them.
const _hold = Duration(seconds: 3);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> shot(WidgetTester tester, String name) async {
    await tester.pumpAndSettle();
    debugPrint('SHOT:$name');
    await tester.runAsync(() => Future<void>.delayed(_hold));
  }

  Color keyColor(WidgetTester tester, PersonaTier tier) => tester
      .widget<AppBlock>(
        find.descendant(
          of: find.byKey(PersonaRow.tierKey(tier)),
          matching: find.byType(AppBlock),
        ),
      )
      .face;

  testWidgets('choose and change the persona tier', (tester) async {
    SharedPreferences.setMockInitialValues({
      FairPlayController.acknowledgedVersionKey: fairPlayNoticeVersion,
    });
    final preferences = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const SpookyMooveApp(),
      ),
    );
    await tester.tap(find.byKey(HomeScreen.gameKey(GameKind.chess)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(NewGameScreen.startKey));
    await tester.pumpAndSettle();
    final prompt = find.text(SuggestionCard.pickTierPrompt);

    expect(container.read(personaTierProvider), PersonaTier.even);
    expect(keyColor(tester, PersonaTier.even), AppColors.accentActive);
    expect(prompt, findsNothing);
    await shot(tester, 'persona_default_even');

    await tester.tap(find.byKey(PersonaRow.tierKey(PersonaTier.soft)));
    await tester.pumpAndSettle();
    expect(container.read(personaTierProvider), PersonaTier.soft);
    expect(keyColor(tester, PersonaTier.soft), AppColors.accentActive);
    expect(prompt, findsNothing);
    await shot(tester, 'persona_soft');

    await tester.tap(find.byKey(PersonaRow.tierKey(PersonaTier.baby)));
    await tester.pumpAndSettle();
    expect(container.read(personaTierProvider), PersonaTier.baby);
    expect(keyColor(tester, PersonaTier.soft), AppColors.keyNormal);
    expect(keyColor(tester, PersonaTier.baby), AppColors.accentActive);
  });
}
