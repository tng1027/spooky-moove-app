import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/l10n/app_strings.dart';
import 'core/theme/app_theme.dart';
import 'features/advisor/presentation/advisor_screen.dart';
import 'features/fair_play/presentation/fair_play_controller.dart';
import 'features/fair_play/presentation/fair_play_screen.dart';
import 'features/new_game/presentation/game_session_controller.dart';
import 'features/new_game/presentation/home_screen.dart';
import 'features/settings/application/app_language_controller.dart';
import 'features/settings/domain/app_language.dart';

class SpookyMooveApp extends ConsumerWidget {
  const SpookyMooveApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(appLanguageProvider);
    return MaterialApp(
      title: 'Spooky Moove',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.dark,
      locale: Locale(language.code),
      supportedLocales: [
        for (final language in AppLanguage.values) Locale(language.code),
      ],
      localizationsDelegates: const [
        AppStrings.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const _HomeGate(),
    );
  }
}

/// The fair-play notice is the root screen until acknowledged, so no route
/// sits beneath it and system back cannot bypass it (OB-008 REQ-001). The
/// Home screen is the root until the first game starts (OB-049).
class _HomeGate extends ConsumerWidget {
  const _HomeGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAcknowledged = ref.watch(fairPlayAcknowledgedProvider);
    if (!isAcknowledged) {
      return FairPlayScreen(
        onAcknowledge: ref
            .read(fairPlayAcknowledgedProvider.notifier)
            .acknowledge,
      );
    }
    final hasGame = ref.watch(gameSessionProvider) != null;
    if (hasGame) return const AdvisorScreen();
    return HomeScreen(
      onStart: ref.read(gameSessionProvider.notifier).start,
      onLanguageSelected: ref.read(appLanguageProvider.notifier).select,
    );
  }
}
