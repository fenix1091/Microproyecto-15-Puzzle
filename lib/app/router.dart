import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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

/// TODO(frontend): real pages; redirect any route to [AppRoutes.splash]
/// until `appDependenciesProvider` has a value (web refresh / deep links);
/// `/result` without `extra` redirects to the menu.
final routerProvider = Provider<GoRouter>(
  (ref) => GoRouter(
    initialLocation: AppRoutes.splash,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('Sliding Puzzle'))),
      ),
    ],
  ),
);
