import 'package:flutter_test/flutter_test.dart';
import 'package:sliding_puzzle/core/result.dart';
import 'package:sliding_puzzle/features/game/domain/entities/difficulty_level.dart';
import 'package:sliding_puzzle/features/game/domain/entities/game_result.dart';
import 'package:sliding_puzzle/features/game/domain/repositories/game_history_repository.dart';
import 'package:sliding_puzzle/features/leaderboard/data/repositories/history_leaderboard_repository.dart';

class MemoryHistory implements GameHistoryRepository {
  final items = <GameResult>[];
  @override
  Future<Result<void>> clear() async {
    items.clear();
    return const Result.ok(null);
  }

  @override
  Future<Result<List<GameResult>>> getHistory({
    DifficultyLevel? level,
    int? limit,
  }) async => Result.ok(
    items
        .where((g) => level == null || g.level == level)
        .take(limit ?? items.length)
        .toList(),
  );
  @override
  Future<Result<void>> save(GameResult result) async {
    items.insert(0, result);
    return const Result.ok(null);
  }
}

GameResult game(
  int seconds,
  int moves, {
  GameOutcome outcome = GameOutcome.won,
}) => GameResult(
  level: DifficultyLevel.easy,
  boardSize: 3,
  moves: moves,
  duration: Duration(seconds: seconds),
  outcome: outcome,
  minSolutionDepth: 10,
  playedAt: DateTime.utc(2026, 1, 1).add(Duration(seconds: seconds)),
);

void main() {
  test(
    'ranks by duration then moves, applies limit, and returns personal best',
    () async {
      final history = MemoryHistory()
        ..items.addAll([
          game(20, 5),
          game(10, 9),
          game(10, 3),
          game(2, 1, outcome: GameOutcome.lost),
        ]);
      final repository = HistoryLeaderboardRepository(history);
      final top = (await repository.getTop(
        DifficultyLevel.easy,
        limit: 2,
      )).valueOrNull!;
      expect(
        top.map((entry) => (entry.duration.inSeconds, entry.moves, entry.rank)),
        [(10, 3, 1), (10, 9, 2)],
      );
      expect(
        (await repository.getPersonalBest(DifficultyLevel.easy))
            .valueOrNull!
            .moves,
        3,
      );
      expect(
        (await repository.getPersonalBest(DifficultyLevel.master)).valueOrNull,
        isNull,
      );
    },
  );

  test(
    'submit only accepts strict improvements and ignores non-wins',
    () async {
      final history = MemoryHistory()..items.add(game(10, 5));
      final repository = HistoryLeaderboardRepository(history);
      expect((await repository.submit(game(9, 99))).valueOrNull, isTrue);
      expect((await repository.submit(game(10, 5))).valueOrNull, isFalse);
      expect((await repository.submit(game(11, 1))).valueOrNull, isFalse);
      expect(
        (await repository.submit(game(1, 1, outcome: GameOutcome.abandoned)))
            .valueOrNull,
        isFalse,
      );
    },
  );
}
