import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/settings/application/settings_controller.dart';
import '../features/settings/domain/entities/user_settings.dart';
import 'router.dart';
import 'theme/app_theme.dart';

/// Root widget of the Sliding Puzzle application.
/// Configures Material 3 light/dark themes and dynamically responds to
/// the user's themeMode preference from [settingsControllerProvider].
class SlidingPuzzleApp extends ConsumerWidget {
  const SlidingPuzzleApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsControllerProvider);
    final themeMode = settingsAsync.maybeWhen(
      data: (settings) => switch (settings.themeMode) {
        AppThemeMode.light => ThemeMode.light,
        AppThemeMode.dark => ThemeMode.dark,
        AppThemeMode.system => ThemeMode.system,
      },
      orElse: () => ThemeMode.system,
    );

    return MaterialApp.router(
      title: 'Sliding Puzzle',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: ref.watch(routerProvider),
    );
  }
}
