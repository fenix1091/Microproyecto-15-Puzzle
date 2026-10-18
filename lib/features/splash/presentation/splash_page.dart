import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/di/providers.dart';
import '../../../app/router.dart';
import '../../../app/theme/tokens.dart';
import '../../../shared/widgets/animated_logo.dart';
import '../../settings/application/settings_controller.dart';

/// Splash screen that animates the logo and awaits dependencies,
/// settings, and audio preload before navigating to the main menu.
class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  @override
  void initState() {
    super.initState();
    _startPreload();
  }

  Future<void> _startPreload() async {
    final stopwatch = Stopwatch()..start();

    try {
      await Future.wait([
        ref.read(appDependenciesProvider.future),
        ref.read(settingsControllerProvider.future),
        ref.read(feedbackServiceProvider).preload(),
      ]);
    } catch (_) {
      // Continue even if some optional dependency encounters an error.
    }

    final elapsed = stopwatch.elapsed;
    if (elapsed < AppTokens.splashMinDuration) {
      await Future<void>.delayed(AppTokens.splashMinDuration - elapsed);
    }

    if (mounted) {
      context.go(AppRoutes.menu);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const AnimatedLogo(size: 140),
            const SizedBox(height: AppTokens.spaceLarge),
            Text(
              'Sliding Puzzle',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppTokens.spaceSmall),
            Text(
              'Desafía tu mente',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppTokens.spaceXLarge),
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
