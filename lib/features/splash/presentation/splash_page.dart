import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/di/bootstrap.dart';
import '../../../app/di/providers.dart';
import '../../../app/routes.dart';
import '../../../app/theme/tokens.dart';
import '../../../shared/widgets/animated_logo.dart';
import '../../settings/application/settings_controller.dart';

/// Splash screen that animates the logo and awaits dependencies,
/// settings, and audio preload before navigating to the main menu.
/// If critical dependencies fail to load, displays an error view with "Reintentar".
class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  Timer? _minDurationTimer;
  bool _minDurationPassed = false;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _preloadOther();
  }

  void _startTimer() {
    _minDurationPassed = false;
    _minDurationTimer?.cancel();
    _minDurationTimer = Timer(AppTokens.splashMinDuration, () {
      _minDurationPassed = true;
      _checkNavigate();
    });
  }

  Future<void> _preloadOther() async {
    try {
      await Future.wait([
        ref.read(settingsControllerProvider.future),
        ref.read(feedbackServiceProvider).preload(),
      ]);
    } catch (_) {}
    _checkNavigate();
  }

  void _checkNavigate() {
    if (!mounted || _navigated || !_minDurationPassed) return;
    final deps = ref.read(appDependenciesProvider);
    if (deps.hasValue) {
      _navigated = true;
      context.go(AppRoutes.menu);
    }
  }

  void _retry() {
    _startTimer();
    _preloadOther();
    ref.invalidate(appDependenciesProvider);
  }

  @override
  void dispose() {
    _minDurationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<AppDependencies>>(appDependenciesProvider, (_, next) {
      if (next.hasValue) {
        _checkNavigate();
      }
    });

    final depsAsync = ref.watch(appDependenciesProvider);
    final hasError = depsAsync.hasError;
    final isLoading = depsAsync.isLoading;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final reduceMotion =
        ref.watch(settingsControllerProvider).asData?.value.reduceMotion ??
        false;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTokens.spaceLarge),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedLogo(size: 140, reduceMotion: reduceMotion),
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
              if (hasError) ...[
                Icon(
                  Icons.error_outline_rounded,
                  size: 40,
                  color: colorScheme.error,
                ),
                const SizedBox(height: AppTokens.spaceSmall),
                Text(
                  'No se pudieron cargar los datos del juego',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.error,
                  ),
                ),
                const SizedBox(height: AppTokens.spaceMedium),
                FilledButton.icon(
                  onPressed: _retry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Reintentar'),
                ),
              ] else if (isLoading)
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
      ),
    );
  }
}
