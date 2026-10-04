import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cataland/app.dart';
import 'package:cataland/features/new_game/presentation/home_screen.dart';
import 'package:cataland/features/fair_play/domain/fair_play_notice.dart';
import 'package:cataland/features/fair_play/presentation/fair_play_controller.dart';
import 'package:cataland/features/fair_play/presentation/fair_play_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cataland/features/advisor/presentation/suggestion_providers.dart';

import '../persona/fake_game_engine.dart';

const _key = FairPlayController.acknowledgedVersionKey;

Future<SharedPreferences> _pumpApp(
  WidgetTester tester, {
  int? acknowledgedVersion,
  Size size = const Size(392, 800),
  double textScale = 1.0,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearAllTestValues);

  SharedPreferences.setMockInitialValues({_key: ?acknowledgedVersion});
  final preferences = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(preferences),
        gameEngineProvider.overrideWithValue(FakeGameEngine()),
      ],
      child: const CatalandApp(),
    ),
  );
  return preferences;
}

void main() {
  testWidgets('a fresh install shows the notice, not the Home screen', (
    tester,
  ) async {
    await _pumpApp(tester);

    expect(find.byType(FairPlayScreen), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);
    expect(find.byKey(FairPlayScreen.closeKey), findsNothing);
  });

  testWidgets('acknowledging opens the Home screen and persists the version', (
    tester,
  ) async {
    final preferences = await _pumpApp(tester);

    await tester.tap(find.byKey(FairPlayScreen.acknowledgeKey));
    await tester.pump();

    expect(find.byType(FairPlayScreen), findsNothing);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(preferences.getInt(_key), fairPlayNoticeVersion);
  });

  testWidgets('the current version already acknowledged skips the notice', (
    tester,
  ) async {
    await _pumpApp(tester, acknowledgedVersion: fairPlayNoticeVersion);

    expect(find.byType(FairPlayScreen), findsNothing);
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('an older acknowledged version shows the notice again', (
    tester,
  ) async {
    await _pumpApp(tester, acknowledgedVersion: fairPlayNoticeVersion - 1);

    expect(find.byType(FairPlayScreen), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);
  });

  testWidgets('a Vietnamese device shows the Vietnamese text', (tester) async {
    tester.platformDispatcher.localeTestValue = const Locale('vi', 'VN');
    await _pumpApp(tester);

    expect(find.text(FairPlayNoticeText.vietnamese.title), findsOneWidget);
    expect(find.text('TÔI ĐÃ HIỂU'), findsOneWidget);
    expect(find.text(FairPlayNoticeText.english.title), findsNothing);
  });

  testWidgets('any other language shows the English text', (tester) async {
    tester.platformDispatcher.localeTestValue = const Locale('fr', 'FR');
    await _pumpApp(tester);

    expect(find.text(FairPlayNoticeText.english.title), findsOneWidget);
    expect(find.text('I UNDERSTAND'), findsOneWidget);
  });

  testWidgets('at text scale 2.0 on a small phone the key stays tappable', (
    tester,
  ) async {
    await _pumpApp(tester, size: const Size(360, 640), textScale: 2.0);
    expect(tester.takeException(), isNull);

    final last = find.text(FairPlayNoticeText.english.paragraphs.last);
    await tester.scrollUntilVisible(last, 100);
    expect(last.hitTestable(), findsOneWidget);

    await tester.tap(find.byKey(FairPlayScreen.acknowledgeKey));
    await tester.pump();
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('read-only mode closes back to the previous screen', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const FairPlayScreen.readOnly(),
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byKey(FairPlayScreen.acknowledgeKey), findsNothing);
    expect(find.text(FairPlayNoticeText.english.closeLabel), findsOneWidget);

    await tester.tap(find.byKey(FairPlayScreen.closeKey));
    await tester.pumpAndSettle();
    expect(find.byType(FairPlayScreen), findsNothing);
    expect(find.text('open'), findsOneWidget);
  });
}
