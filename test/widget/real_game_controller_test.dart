import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sliding_puzzle/app/di/providers.dart';
import 'package:sliding_puzzle/app/routes.dart';
import 'package:sliding_puzzle/core/result.dart';
import 'package:sliding_puzzle/core/services/feedback_service.dart';
import 'package:sliding_puzzle/core/utils/clock.dart';
import 'package:sliding_puzzle/core/utils/random_source.dart';
import 'package:sliding_puzzle/features/game/application/game_controller.dart';
import 'package:sliding_puzzle/features/game/domain/entities/board.dart';
import 'package:sliding_puzzle/features/game/domain/entities/difficulty_config.dart';
import 'package:sliding_puzzle/features/game/domain/entities/difficulty_decision.dart';
import 'package:sliding_puzzle/features/game/domain/entities/difficulty_level.dart';
import 'package:sliding_puzzle/features/game/domain/entities/game_result.dart';
import 'package:sliding_puzzle/features/game/domain/entities/game_session.dart';
import 'package:sliding_puzzle/features/game/domain/repositories/game_history_repository.dart';
import 'package:sliding_puzzle/features/game/domain/services/difficulty_engine.dart';
import 'package:sliding_puzzle/features/game/domain/services/shuffler.dart';
import 'package:sliding_puzzle/features/game/domain/usecases/finish_game.dart';
import 'package:sliding_puzzle/features/game/domain/usecases/game_actions.dart';
import 'package:sliding_puzzle/features/game/domain/usecases/start_game.dart';
import 'package:sliding_puzzle/features/game/presentation/pages/game_page.dart';
import 'package:sliding_puzzle/features/leaderboard/domain/entities/leaderboard_entry.dart';
import 'package:sliding_puzzle/features/leaderboard/domain/repositories/leaderboard_repository.dart';
import 'package:sliding_puzzle/features/settings/domain/entities/user_settings.dart';
import 'package:sliding_puzzle/features/settings/domain/repositories/settings_repository.dart';

class _TestClock implements Clock {
  DateTime value = DateTime.utc(2026);
  @override
  DateTime now() => value;
}

class _FixedRandom implements RandomSource {
  @override
  int nextInt(int max) => 0;
}

class _MemoryHistory implements GameHistoryRepository {
  final records = <GameResult>[];
  @override
  Future<Result<void>> clear() async {
    records.clear();
    return const Result.ok(null);
  }

  @override
  Future<Result<List<GameResult>>> getHistory({
    DifficultyLevel? level,
    int? limit,
  }) async => Result.ok(
    records
        .where((game) => level == null || game.level == level)
        .take(limit ?? records.length)
        .toList(),
  );

  @override
  Future<Result<void>> save(GameResult result) async {
    records.insert(0, result);
    return const Result.ok(null);
  }
}

class _MemoryLeaderboard implements LeaderboardRepository {
  @override
  Future<Result<List<LeaderboardEntry>>> getTop(
    DifficultyLevel level, {
    int limit = 10,
  }) async => const Result.ok([]);

  @override
  Future<Result<LeaderboardEntry?>> getPersonalBest(
    DifficultyLevel level,
  ) async => const Result.ok(null);

  @override
  Future<Result<bool>> submit(GameResult result) async =>
      Result.ok(result.outcome == GameOutcome.won);
}

class _MemorySettings implements SettingsRepository {
  _MemorySettings(this.settings);
  UserSettings settings;
  @override
  Future<Result<UserSettings>> load() async => Result.ok(settings);
  @override
  Future<Result<void>> save(UserSettings value) async {
    settings = value;
    return const Result.ok(null);
  }
}

class _FixedStartGame extends StartGame {
  _FixedStartGame(this.session, this.decision)
    : super(
        engine: const DifficultyEngine(),
        shuffler: Shuffler(_FixedRandom()),
        history: _MemoryHistory(),
      );

  final GameSession session;
  final DifficultyDecision decision;

  @override
  Future<Result<GameSetup>> call({
    required DifficultyLevel currentLevel,
    DifficultyLevel? manualLevel,
  }) async {
    return Result.ok(GameSetup(session: session, decision: decision));
  }
}

Widget createIntegrationApp({
  required GameSession session,
  required GoRouter router,
}) {
  final clock = _TestClock();
  final history = _MemoryHistory();
  final leaderboard = _MemoryLeaderboard();
  final settingsRepo = _MemorySettings(const UserSettings());
  final decision = const DifficultyDecision(
    level: DifficultyLevel.easy,
    trend: DifficultyTrend.unchanged,
  );
  final fixedStartGame = _FixedStartGame(session, decision);

  return ProviderScope(
    overrides: [
      clockProvider.overrideWithValue(clock),
      feedbackServiceProvider.overrideWithValue(const NoopFeedbackService()),
      gameHistoryRepositoryProvider.overrideWithValue(history),
      leaderboardRepositoryProvider.overrideWithValue(leaderboard),
      settingsRepositoryProvider.overrideWithValue(settingsRepo),
      startGameProvider.overrideWithValue(fixedStartGame),
      moveTileProvider.overrideWithValue(const MoveTile()),
      tickGameProvider.overrideWithValue(const TickGame()),
      pauseGameProvider.overrideWithValue(const PauseGame()),
      resumeGameProvider.overrideWithValue(const ResumeGame()),
      finishGameProvider.overrideWithValue(
        FinishGame(history: history, leaderboard: leaderboard, clock: clock),
      ),
      gameControllerProvider.overrideWith(GameController.new),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  group('MED-013 Real GameController Integration Tests', () {
    testWidgets('Win triggers navigation to /result', (tester) async {
      // 1 move away from solved:
      // Row 0: 1, 2, 3
      // Row 1: 4, 5, 6
      // Row 2: 7, 0, 8
      // Tapping tile 8 moves 8 to index 7 and 0 to index 8 -> Solved!
      final board = Board(size: 3, tiles: const [1, 2, 3, 4, 5, 6, 7, 0, 8]);
      final session = GameSession(
        initialBoard: board,
        board: board,
        config: DifficultyConfig.base(DifficultyLevel.easy),
        moves: 3,
        elapsed: const Duration(seconds: 25),
        status: GameStatus.playing,
      );

      final router = GoRouter(
        initialLocation: AppRoutes.game,
        routes: [
          GoRoute(
            path: AppRoutes.game,
            builder: (context, state) => const GamePage(),
          ),
          GoRoute(
            path: AppRoutes.result,
            builder: (context, state) =>
                const Scaffold(body: Text('Pantalla de Resultados')),
          ),
          GoRoute(
            path: AppRoutes.menu,
            builder: (context, state) =>
                const Scaffold(body: Text('Pantalla de Menu')),
          ),
        ],
      );

      await tester.pumpWidget(
        createIntegrationApp(session: session, router: router),
      );
      await tester.pumpAndSettle();

      expect(find.byType(GamePage), findsOneWidget);

      // Find tile 8 and tap it
      final tile8 = find.widgetWithText(InkWell, '8');
      expect(tile8, findsOneWidget);
      await tester.tap(tile8);
      await tester.pumpAndSettle();

      // Navigation to /result must have happened
      expect(find.text('Pantalla de Resultados'), findsOneWidget);
      expect(find.byType(GamePage), findsNothing);
    });

    testWidgets('Abandon triggers navigation to /menu', (tester) async {
      final board = Board(size: 3, tiles: const [1, 2, 3, 4, 5, 6, 7, 0, 8]);
      final session = GameSession(
        initialBoard: board,
        board: board,
        config: DifficultyConfig.base(DifficultyLevel.easy),
        moves: 3,
        elapsed: const Duration(seconds: 25),
        status: GameStatus.playing,
      );

      final router = GoRouter(
        initialLocation: AppRoutes.game,
        routes: [
          GoRoute(
            path: AppRoutes.game,
            builder: (context, state) => const GamePage(),
          ),
          GoRoute(
            path: AppRoutes.result,
            builder: (context, state) =>
                const Scaffold(body: Text('Pantalla de Resultados')),
          ),
          GoRoute(
            path: AppRoutes.menu,
            builder: (context, state) =>
                const Scaffold(body: Text('Pantalla de Menu')),
          ),
        ],
      );

      await tester.pumpWidget(
        createIntegrationApp(session: session, router: router),
      );
      await tester.pumpAndSettle();

      // Tap Salir in HUD
      final exitHudButton = find.widgetWithText(OutlinedButton, 'Salir');
      expect(exitHudButton, findsOneWidget);
      await tester.tap(exitHudButton);
      await tester.pumpAndSettle();

      // Confirm dialog is shown; tap Salir inside dialog
      final exitDialogButton = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(FilledButton, 'Salir'),
      );
      expect(exitDialogButton, findsOneWidget);
      await tester.tap(exitDialogButton);
      await tester.pumpAndSettle();

      // Navigation to /menu must have happened
      expect(find.text('Pantalla de Menu'), findsOneWidget);
      expect(find.byType(GamePage), findsNothing);
    });

    testWidgets('Auto-pause triggers on lifecycle inactive and paused', (
      tester,
    ) async {
      final board = Board(size: 3, tiles: const [1, 2, 3, 4, 5, 6, 7, 0, 8]);
      final session = GameSession(
        initialBoard: board,
        board: board,
        config: DifficultyConfig.base(DifficultyLevel.easy),
        moves: 3,
        elapsed: const Duration(seconds: 25),
        status: GameStatus.playing,
      );

      final router = GoRouter(
        initialLocation: AppRoutes.game,
        routes: [
          GoRoute(
            path: AppRoutes.game,
            builder: (context, state) => const GamePage(),
          ),
        ],
      );

      await tester.pumpWidget(
        createIntegrationApp(session: session, router: router),
      );
      await tester.pumpAndSettle();

      // Ensure resumed initially
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      // Verify no pause overlay initially
      expect(find.text('Partida pausada'), findsNothing);

      // Transition to inactive
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pumpAndSettle();

      // Pause overlay should appear
      expect(find.text('Partida pausada'), findsOneWidget);

      // Resume game via Reanudar button
      final resumeButton = find.widgetWithText(FilledButton, 'Reanudar');
      expect(resumeButton, findsOneWidget);
      await tester.tap(resumeButton);
      await tester.pumpAndSettle();

      expect(find.text('Partida pausada'), findsNothing);

      // Transition back to resumed
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      // Transition to paused via inactive -> hidden -> paused
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pumpAndSettle();

      expect(find.text('Partida pausada'), findsOneWidget);
    });
  });
}
