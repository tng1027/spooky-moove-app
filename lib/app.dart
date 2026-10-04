import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'features/advisor/presentation/advisor_screen.dart';
import 'features/fair_play/presentation/fair_play_controller.dart';
import 'features/fair_play/presentation/fair_play_screen.dart';
import 'features/new_game/presentation/game_session_controller.dart';
import 'features/new_game/presentation/home_screen.dart';

class CatalandApp extends StatelessWidget {
  const CatalandApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cataland',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.dark,
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
    return HomeScreen(onStart: ref.read(gameSessionProvider.notifier).start);
  }
}
