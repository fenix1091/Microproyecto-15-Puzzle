// ignore_for_file: depend_on_referenced_packages

import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sliding_puzzle/app/di/providers.dart';
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
import 'package:sliding_puzzle/features/game/domain/usecases/start_game.dart';
import 'package:sliding_puzzle/features/leaderboard/domain/entities/leaderboard_entry.dart';
import 'package:sliding_puzzle/features/leaderboard/domain/repositories/leaderboard_repository.dart';
import 'package:sliding_puzzle/features/settings/application/settings_controller.dart';
import 'package:sliding_puzzle/features/settings/domain/entities/user_settings.dart';
import 'package:sliding_puzzle/features/settings/domain/repositories/settings_repository.dart';

class TestClock implements Clock {
  DateTime value = DateTime.utc(2026);
  void advance(Duration duration) => value = value.add(duration);
  @override
  DateTime now() => value;
}

class FixedRandom implements RandomSource {
  @override
  int nextInt(int max) => 0;
}

class MemoryHistory implements GameHistoryRepository {
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

class MemoryLeaderboard implements LeaderboardRepository {
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

class MemorySettings implements SettingsRepository {
  MemorySettings(this.settings);
  UserSettings settings;
  @override
  Future<Result<UserSettings>> load() async => Result.ok(settings);
  @override
  Future<Result<void>> save(UserSettings value) async {
    settings = value;
    return const Result.ok(null);
  }
}

class RecordingFeedback implements FeedbackService {
  int moves = 0, invalids = 0, wins = 0, losses = 0;
  final configs = <(bool, bool)>[];
  @override
  void configure({required bool sound, required bool vibration}) =>
      configs.add((sound, vibration));
  @override
  void gameLost() => losses++;
  @override
  void gameWon() => wins++;
  @override
  void invalidMove() => invalids++;
  @override
  Future<void> preload() async {}
  @override
  void tileMoved() => moves++;
}

class FixedStartGame extends StartGame {
  FixedStartGame(this.history, this.session, this.decision)
    : super(
        engine: const DifficultyEngine(),
        shuffler: Shuffler(FixedRandom()),
        history: history,
      );
  final GameHistoryRepository history;
  final GameSession session;
  final DifficultyDecision decision;
  DifficultyLevel? currentSeen;
  DifficultyLevel? manualSeen;
  @override
  Future<Result<GameSetup>> call({
    required DifficultyLevel currentLevel,
    DifficultyLevel? manualLevel,
  }) async {
    currentSeen = currentLevel;
    manualSeen = manualLevel;
    return Result.ok(GameSetup(session: session, decision: decision));
  }
}

Board twoMovesAway() => Board(size: 3, tiles: [1, 2, 3, 4, 5, 6, 0, 7, 8]);
GameSession session({Duration? limit}) {
  final board = twoMovesAway();
  return GameSession(
    initialBoard: board,
    board: board,
    config: DifficultyConfig(
      level: DifficultyLevel.easy,
      boardSize: 3,
      shuffleMoves: 2,
      timeLimit: limit,
      minSolutionDepth: 2,
    ),
  );
}

class Fixture {
  Fixture({UserSettings settings = const UserSettings(), Duration? limit}) {
    clock = TestClock();
    history = MemoryHistory();
    prefs = MemorySettings(settings);
    feedback = RecordingFeedback();
    start = FixedStartGame(
      history,
      session(limit: limit),
      const DifficultyDecision(
        level: DifficultyLevel.master,
        trend: DifficultyTrend.promoted,
      ),
    );
    container = ProviderContainer(
      overrides: [
        clockProvider.overrideWithValue(clock),
        gameHistoryRepositoryProvider.overrideWithValue(history),
        leaderboardRepositoryProvider.overrideWithValue(MemoryLeaderboard()),
        settingsRepositoryProvider.overrideWithValue(prefs),
        feedbackServiceProvider.overrideWithValue(feedback),
        startGameProvider.overrideWithValue(start),
      ],
    );
  }
  late final TestClock clock;
  late final MemoryHistory history;
  late final MemorySettings prefs;
  late final RecordingFeedback feedback;
  late final FixedStartGame start;
  late final ProviderContainer container;
  GameController get controller =>
      container.read(gameControllerProvider.notifier);
  Future<void> loadSettings() =>
      container.read(settingsControllerProvider.future).then((_) {});
  Future<void> close() async => container.dispose();
}

void main() {
  test('start chooses adaptive, manual, and explicit levels', () async {
    final adaptive = Fixture(
      settings: const UserSettings(
        adaptiveDifficulty: true,
        currentLevel: DifficultyLevel.hard,
      ),
    );
    await adaptive.loadSettings();
    await adaptive.controller.start();
    expect(adaptive.start.currentSeen, DifficultyLevel.hard);
    expect(adaptive.start.manualSeen, isNull);
    await adaptive.close();

    const manualSettings = UserSettings(
      adaptiveDifficulty: false,
      manualLevel: DifficultyLevel.expert,
    );
    final manual = Fixture(settings: manualSettings);
    await manual.loadSettings();
    await manual.controller.start();
    expect(manual.start.currentSeen, DifficultyLevel.expert);
    expect(manual.start.manualSeen, DifficultyLevel.expert);
    await manual.controller.start(level: DifficultyLevel.medium);
    expect(manual.start.manualSeen, DifficultyLevel.medium);
    await manual.close();
  });

  test('invalid taps report feedback; valid move starts play; win finishes and persists adaptive level', () async {
    final fixture = Fixture();
    await fixture.loadSettings();
    await fixture.controller.start();
    expect(
      fixture.container.read(gameControllerProvider).session!.status,
      GameStatus.ready,
    );
    fixture.controller.tap(1);
    expect(fixture.container.read(gameControllerProvider).invalidTapCount, 1);
    expect(fixture.feedback.invalids, 1);
    fixture.controller.tap(7);
    expect(
      fixture.container.read(gameControllerProvider).session!.status,
      GameStatus.playing,
    );
    expect(fixture.feedback.moves, 1);
    fixture.controller.tap(8);
    await Future<void>.delayed(Duration.zero);
    expect(
      fixture.container.read(gameControllerProvider).result!.isPersonalBest,
      isTrue,
    );
    expect(fixture.history.records.single.outcome, GameOutcome.won);
    expect(fixture.feedback.wins, 1);
    expect(fixture.prefs.settings.currentLevel, DifficultyLevel.master);
    await fixture.close();
  });

  test(
    'timer pauses, resumes, reaches time limit, and restart resets state',
    () {
      fakeAsync((async) {
        final fixture = Fixture(limit: const Duration(seconds: 2));
        addTearDown(fixture.close);
        fixture.controller.start();
        async.flushMicrotasks();
        fixture.controller.tap(7);
        async.flushMicrotasks();
        fixture.clock.advance(const Duration(seconds: 1));
        async.elapse(const Duration(seconds: 1));
        expect(
          fixture.container.read(gameControllerProvider).session!.elapsed,
          const Duration(seconds: 1),
        );
        fixture.controller.pause();
        fixture.clock.advance(const Duration(seconds: 3));
        async.elapse(const Duration(seconds: 3));
        expect(
          fixture.container.read(gameControllerProvider).session!.elapsed,
          const Duration(seconds: 1),
        );
        fixture.controller.resume();
        fixture.clock.advance(const Duration(seconds: 1));
        async.elapse(const Duration(seconds: 1));
        async.flushMicrotasks();
        expect(
          fixture.container.read(gameControllerProvider).session!.status,
          GameStatus.lost,
        );
        expect(fixture.feedback.losses, 1);
        fixture.controller.restart();
        expect(
          fixture.container.read(gameControllerProvider).session!.status,
          GameStatus.ready,
        );
        expect(
          fixture.container.read(gameControllerProvider).session!.moves,
          0,
        );
      });
    },
  );

  test('abandon ignores untouched games and records moved games', () async {
    final fixture = Fixture();
    await fixture.loadSettings();
    await fixture.controller.start();
    await fixture.controller.abandon();
    expect(fixture.history.records, isEmpty);
    fixture.controller.tap(7);
    await fixture.controller.abandon();
    await Future<void>.delayed(Duration.zero);
    expect(fixture.history.records.single.outcome, GameOutcome.abandoned);
    await fixture.close();
  });
}
