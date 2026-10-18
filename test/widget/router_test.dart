import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sliding_puzzle/app/di/bootstrap.dart';
import 'package:sliding_puzzle/app/di/providers.dart';
import 'package:sliding_puzzle/app/router.dart';
import 'package:sliding_puzzle/core/services/feedback_service.dart';
import 'package:sliding_puzzle/features/game/domain/entities/difficulty_level.dart';
import 'package:sliding_puzzle/features/game/domain/entities/game_result.dart';
import 'package:sliding_puzzle/features/game/presentation/pages/result_page.dart';
import 'package:sliding_puzzle/features/menu/presentation/menu_page.dart';
import 'package:sliding_puzzle/features/settings/application/settings_controller.dart';
import 'package:sliding_puzzle/features/splash/presentation/splash_page.dart';

import 'helpers/widget_test_helpers.dart';

class _FakeAppDependencies implements AppDependencies {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Router Guard & Redirect Tests', () {
    testWidgets('redirects to /splash until appDependenciesProvider has a value', (
      tester,
    ) async {
      // AsyncLoading state using Completer (no pending timers)
      final completer = Completer<AppDependencies>();
      addTearDown(() {
        if (!completer.isCompleted) {
          completer.complete(_FakeAppDependencies());
        }
      });

      final container = ProviderContainer(
        overrides: [
          appDependenciesProvider.overrideWith(
            (ref) => completer.future,
          ),
          settingsControllerProvider.overrideWith(
            () => FakeSettingsController(),
          ),
          feedbackServiceProvider.overrideWithValue(
            const NoopFeedbackService(),
          ),
        ],
      );
      addTearDown(container.dispose);

      final router = container.read(routerProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pump();

      // Deep link to /game while deps still loading
      router.go(AppRoutes.game);
      await tester.pump();

      // Must be redirected to /splash
      expect(router.state.matchedLocation, equals(AppRoutes.splash));
      expect(find.byType(SplashPage), findsOneWidget);
    });

    testWidgets('/result without GameResult extra redirects to /menu', (
      tester,
    ) async {
      final container = ProviderContainer(
        overrides: [
          appDependenciesProvider.overrideWith(
            (ref) async => _FakeAppDependencies(),
          ),
          settingsControllerProvider.overrideWith(
            () => FakeSettingsController(),
          ),
          feedbackServiceProvider.overrideWithValue(
            const NoopFeedbackService(),
          ),
        ],
      );
      addTearDown(container.dispose);

      final router = container.read(routerProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to /result without extra
      router.go(AppRoutes.result);
      await tester.pumpAndSettle();

      // Redirected to /menu
      expect(router.state.matchedLocation, equals(AppRoutes.menu));
      expect(find.byType(MenuPage), findsOneWidget);
    });

    testWidgets('/result with valid GameResult extra renders ResultPage', (
      tester,
    ) async {
      final container = ProviderContainer(
        overrides: [
          appDependenciesProvider.overrideWith(
            (ref) async => _FakeAppDependencies(),
          ),
          settingsControllerProvider.overrideWith(
            () => FakeSettingsController(),
          ),
          feedbackServiceProvider.overrideWithValue(
            const NoopFeedbackService(),
          ),
        ],
      );
      addTearDown(container.dispose);

      final router = container.read(routerProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final result = GameResult(
        level: DifficultyLevel.easy,
        boardSize: 3,
        moves: 10,
        duration: const Duration(seconds: 30),
        outcome: GameOutcome.won,
        minSolutionDepth: 8,
        playedAt: DateTime(2026, 10, 17),
      );

      // Navigate to /result with extra
      router.go(AppRoutes.result, extra: result);
      await tester.pumpAndSettle();

      expect(router.state.matchedLocation, equals(AppRoutes.result));
      expect(find.byType(ResultPage), findsOneWidget);
    });
  });
}
