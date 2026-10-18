import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/game/domain/entities/game_result.dart';
import '../features/game/presentation/pages/game_page.dart';
import '../features/game/presentation/pages/result_page.dart';
import '../features/instructions/presentation/instructions_page.dart';
import '../features/leaderboard/presentation/leaderboard_page.dart';
import '../features/menu/presentation/menu_page.dart';
import '../features/settings/presentation/settings_page.dart';
import '../features/splash/presentation/splash_page.dart';
import 'di/providers.dart';
import 'theme/tokens.dart';

/// Route paths (contract shared by all features).
abstract final class AppRoutes {
  static const splash = '/splash';
  static const menu = '/menu';
  static const game = '/game';
  static const result = '/result';
  static const leaderboard = '/leaderboard';
  static const settings = '/settings';
  static const instructions = '/instructions';
}

Page<dynamic> _buildFadePage({
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: key,
    child: child,
    transitionDuration: AppTokens.transitionDuration,
    reverseTransitionDuration: AppTokens.transitionDuration,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOut,
        ),
        child: child,
      );
    },
  );
}

/// Router configuration with dependency guarding and page transitions.
final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = ValueNotifier<int>(0);
  ref.listen(appDependenciesProvider, (_, _) {
    refreshNotifier.value++;
  });
  ref.onDispose(refreshNotifier.dispose);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final depsAsync = ref.read(appDependenciesProvider);
      final isLoaded = depsAsync.hasValue;
      final isGoingToSplash = state.matchedLocation == AppRoutes.splash;

      // Redirect any route to splash until appDependenciesProvider has a value
      if (!isLoaded) {
        return isGoingToSplash ? null : AppRoutes.splash;
      }

      // /result without GameResult extra redirects to /menu
      if (state.matchedLocation == AppRoutes.result) {
        if (state.extra is! GameResult) {
          return AppRoutes.menu;
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        pageBuilder: (context, state) => _buildFadePage(
          key: state.pageKey,
          child: const SplashPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.menu,
        pageBuilder: (context, state) => _buildFadePage(
          key: state.pageKey,
          child: const MenuPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.game,
        pageBuilder: (context, state) => _buildFadePage(
          key: state.pageKey,
          child: const GamePage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.result,
        pageBuilder: (context, state) {
          final result = state.extra as GameResult;
          return _buildFadePage(
            key: state.pageKey,
            child: ResultPage(result: result),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.leaderboard,
        pageBuilder: (context, state) => _buildFadePage(
          key: state.pageKey,
          child: const LeaderboardPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.settings,
        pageBuilder: (context, state) => _buildFadePage(
          key: state.pageKey,
          child: const SettingsPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.instructions,
        pageBuilder: (context, state) => _buildFadePage(
          key: state.pageKey,
          child: const InstructionsPage(),
        ),
      ),
    ],
  );
});
