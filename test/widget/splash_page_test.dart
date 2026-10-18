import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sliding_puzzle/app/di/bootstrap.dart';
import 'package:sliding_puzzle/app/di/providers.dart';
import 'package:sliding_puzzle/app/routes.dart';
import 'package:sliding_puzzle/core/services/feedback_service.dart';
import 'package:sliding_puzzle/features/settings/application/settings_controller.dart';
import 'package:sliding_puzzle/features/splash/presentation/splash_page.dart';

import 'helpers/widget_test_helpers.dart';

class _FakeAppDependencies implements AppDependencies {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _SpyFeedbackService extends NoopFeedbackService {
  bool preloadCalled = false;

  @override
  Future<void> preload() async {
    preloadCalled = true;
  }
}

void main() {
  group('SplashPage Widget Tests', () {
    testWidgets('renders animated logo, preloads, and navigates to menu', (
      tester,
    ) async {
      final spyFeedback = _SpyFeedbackService();
      final router = GoRouter(
        initialLocation: AppRoutes.splash,
        routes: [
          GoRoute(
            path: AppRoutes.splash,
            builder: (context, state) => const SplashPage(),
          ),
          GoRoute(
            path: AppRoutes.menu,
            builder: (context, state) =>
                const Scaffold(body: Text('Menu Screen')),
          ),
        ],
      );

      final container = ProviderContainer(
        overrides: [
          appDependenciesProvider.overrideWith(
            (ref) async => _FakeAppDependencies(),
          ),
          settingsControllerProvider.overrideWith(
            () => FakeSettingsController(),
          ),
          feedbackServiceProvider.overrideWithValue(spyFeedback),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      expect(find.byType(SplashPage), findsOneWidget);
      expect(find.text('Sliding Puzzle'), findsOneWidget);
      expect(find.text('Desafía tu mente'), findsOneWidget);

      // Fast forward past the 1.2s minimum delay to complete navigation
      await tester.pump(const Duration(milliseconds: 1400));
      await tester.pumpAndSettle();

      expect(spyFeedback.preloadCalled, isTrue);
      expect(find.text('Menu Screen'), findsOneWidget);
    });

    testWidgets(
      'shows error view with Reintentar on failure and does not navigate',
      (tester) async {
        var attempt = 0;
        final router = GoRouter(
          initialLocation: AppRoutes.splash,
          routes: [
            GoRoute(
              path: AppRoutes.splash,
              builder: (context, state) => const SplashPage(),
            ),
            GoRoute(
              path: AppRoutes.menu,
              builder: (context, state) =>
                  const Scaffold(body: Text('Menu Screen')),
            ),
          ],
        );

        final container = ProviderContainer(
          overrides: [
            appDependenciesProvider.overrideWith((ref) async {
              attempt++;
              if (attempt == 1) {
                throw Exception('IndexedDB failure');
              }
              return _FakeAppDependencies();
            }),
            settingsControllerProvider.overrideWith(
              () => FakeSettingsController(),
            ),
            feedbackServiceProvider.overrideWithValue(
              const NoopFeedbackService(),
            ),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp.router(routerConfig: router),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        // Error UI is displayed
        expect(
          find.text('No se pudieron cargar los datos del juego'),
          findsOneWidget,
        );
        final retryButton = find.widgetWithText(FilledButton, 'Reintentar');
        expect(retryButton, findsOneWidget);
        expect(find.text('Menu Screen'), findsNothing);

        // Tap Reintentar
        await tester.tap(retryButton);
        await tester.pump(const Duration(milliseconds: 1400));
        await tester.pumpAndSettle();

        // Second attempt succeeds and navigates to menu
        expect(attempt, equals(2));
        expect(find.text('Menu Screen'), findsOneWidget);
      },
    );
  });
}
