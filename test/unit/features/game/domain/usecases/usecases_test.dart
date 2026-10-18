import 'package:flutter_test/flutter_test.dart';
import 'package:sliding_puzzle/core/errors/failure.dart';
import 'package:sliding_puzzle/core/result.dart';
import 'package:sliding_puzzle/core/utils/clock.dart';
import 'package:sliding_puzzle/core/utils/random_source.dart';
import 'package:sliding_puzzle/features/game/domain/entities/difficulty_decision.dart';
import 'package:sliding_puzzle/features/game/domain/entities/difficulty_level.dart';
import 'package:sliding_puzzle/features/game/domain/entities/game_result.dart';
import 'package:sliding_puzzle/features/game/domain/entities/game_session.dart';
import 'package:sliding_puzzle/features/game/domain/repositories/game_history_repository.dart';
import 'package:sliding_puzzle/features/game/domain/services/difficulty_engine.dart';
import 'package:sliding_puzzle/features/game/domain/services/shuffler.dart';
import 'package:sliding_puzzle/features/game/domain/usecases/finish_game.dart';
import 'package:sliding_puzzle/features/game/domain/usecases/start_game.dart';
import 'package:sliding_puzzle/features/game/domain/usecases/stats_usecases.dart';
import 'package:sliding_puzzle/features/leaderboard/domain/entities/leaderboard_entry.dart';
import 'package:sliding_puzzle/features/leaderboard/domain/repositories/leaderboard_repository.dart';

class History implements GameHistoryRepository {
  final List<GameResult> items = [];
  Failure? loadFailure;
  @override
  Future<Result<void>> save(GameResult r) async {
    items.insert(0, r);
    return const Result.ok(null);
  }

  @override
  Future<Result<List<GameResult>>> getHistory({
    DifficultyLevel? level,
    int? limit,
  }) async {
    if (loadFailure case final failure?) return Result.err(failure);
    return Result.ok(
      items
          .where((r) => level == null || r.level == level)
          .take(limit ?? items.length)
          .toList(),
    );
  }

  @override
  Future<Result<void>> clear() async {
    items.clear();
    return const Result.ok(null);
  }
}

class BoardRandom implements RandomSource {
  int n = 0;
  @override
  int nextInt(int max) => (n++) % max;
}

class Leader implements LeaderboardRepository {
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
  Future<Result<bool>> submit(GameResult result) async => const Result.ok(true);
}

class FixedClock implements Clock {
  @override
  DateTime now() => DateTime.utc(2026, 1, 1);
}

void main() {
  test(
    'StartGame makes a ready solvable setup and manual difficulty is honored',
    () async {
      final history = History();
      final start = StartGame(
        engine: const DifficultyEngine(),
        shuffler: Shuffler(BoardRandom()),
        history: history,
      );
      final result = await start(
        currentLevel: DifficultyLevel.easy,
        manualLevel: DifficultyLevel.easy,
      );
      final setup = result.valueOrNull!;
      expect(setup.session.status, GameStatus.ready);
      expect(setup.session.board.isSolved, isFalse);
    },
  );
  test('FinishGame records win after leaderboard comparison and marks personal best', () async {
    final history = History();
    final setup =
        (await StartGame(
              engine: const DifficultyEngine(),
              shuffler: Shuffler(BoardRandom()),
              history: history,
            )(
              currentLevel: DifficultyLevel.easy,
              manualLevel: DifficultyLevel.easy,
            ))
            .valueOrNull!;
    final finish = FinishGame(
      history: history,
      leaderboard: Leader(),
      clock: FixedClock(),
    );
    final result = await finish(
      setup.session.copyWith(moves: 4),
      GameOutcome.won,
    );
    expect(result.valueOrNull!.isPersonalBest, isTrue);
    expect(history.items, hasLength(1));
    expect(history.items.single.minSolutionDepth, greaterThan(0));
  });
  test(
    'stats and next difficulty handle empty and populated history',
    () async {
      final history = History();
      expect((await GetPlayerStats(history)()).valueOrNull!.gamesPlayed, 0);
      expect(
        (await ComputeNextDifficulty(
          engine: const DifficultyEngine(),
          history: history,
        )(DifficultyLevel.hard)).valueOrNull!.level,
        DifficultyLevel.hard,
      );
      history.items.insert(
        0,
        GameResult(
          level: DifficultyLevel.easy,
          boardSize: 3,
          moves: 20,
          duration: const Duration(seconds: 12),
          outcome: GameOutcome.won,
          minSolutionDepth: 10,
          playedAt: DateTime.utc(2026),
          timeLimit: const Duration(minutes: 5),
        ),
      );
      final stats = (await GetPlayerStats(history)()).valueOrNull!;
      expect(stats.wins, 1);
      expect(stats.averageMoves, 20);
      expect(stats.bestWinStreak, 1);
      expect(stats.winStreak, 1);
      expect(stats.lossStreak, 0);
      history.items.add(
        GameResult(
          level: DifficultyLevel.easy,
          boardSize: 3,
          moves: 22,
          duration: const Duration(minutes: 4),
          outcome: GameOutcome.abandoned,
          minSolutionDepth: 10,
          playedAt: DateTime.utc(2025),
          timeLimit: const Duration(minutes: 5),
        ),
      );
      final newerWinStats = (await GetPlayerStats(history)()).valueOrNull!;
      expect(newerWinStats.winStreak, 1);
      expect(newerWinStats.lossStreak, 0);
      history.items.insert(
        0,
        GameResult(
          level: DifficultyLevel.easy,
          boardSize: 3,
          moves: 1,
          duration: const Duration(seconds: 5),
          outcome: GameOutcome.lost,
          minSolutionDepth: 10,
          playedAt: DateTime.utc(2026, 2),
          timeLimit: const Duration(minutes: 5),
        ),
      );
      history.items.insert(
        1,
        GameResult(
          level: DifficultyLevel.easy,
          boardSize: 3,
          moves: 3,
          duration: const Duration(seconds: 7),
          outcome: GameOutcome.abandoned,
          minSolutionDepth: 10,
          playedAt: DateTime.utc(2026, 1, 2),
          timeLimit: const Duration(minutes: 5),
        ),
      );
      final newestLossStats = (await GetPlayerStats(history)()).valueOrNull!;
      expect(newestLossStats.winStreak, 0);
      expect(newestLossStats.lossStreak, 2);
      expect(newestLossStats.bestWinStreak, 1);
    },
  );
  test(
    'adaptive start evaluates recent history and chooses promoted config',
    () async {
      final history = History();
      for (var i = 0; i < 3; i++) {
        history.items.add(
          GameResult(
            level: DifficultyLevel.easy,
            boardSize: 3,
            moves: 18,
            duration: const Duration(minutes: 1),
            outcome: GameOutcome.won,
            minSolutionDepth: 10,
            playedAt: DateTime.utc(2026, 1, i + 1),
            timeLimit: const Duration(minutes: 5),
          ),
        );
      }
      final setup = (await StartGame(
        engine: const DifficultyEngine(),
        shuffler: Shuffler(BoardRandom()),
        history: history,
      )(currentLevel: DifficultyLevel.easy)).valueOrNull!;
      expect(setup.decision.level, DifficultyLevel.medium);
      expect(setup.session.config.level, DifficultyLevel.medium);
    },
  );
  test(
    'StartGame falls back to the current level when history cannot load',
    () async {
      final history = History()
        ..loadFailure = const StorageFailure('read failed');
      final setup = (await StartGame(
        engine: const DifficultyEngine(),
        shuffler: Shuffler(BoardRandom()),
        history: history,
      )(currentLevel: DifficultyLevel.hard)).valueOrNull!;
      expect(setup.decision.level, DifficultyLevel.hard);
      expect(setup.decision.trend, DifficultyTrend.unchanged);
    },
  );
}
