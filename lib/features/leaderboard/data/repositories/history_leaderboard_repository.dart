import '../../../../core/result.dart';
import '../../../game/domain/entities/difficulty_level.dart';
import '../../../game/domain/entities/game_result.dart';
import '../../../game/domain/repositories/game_history_repository.dart';
import '../../domain/entities/leaderboard_entry.dart';
import '../../domain/repositories/leaderboard_repository.dart';

/// Derives rankings from the game history (single source of truth).
class HistoryLeaderboardRepository implements LeaderboardRepository {
  const HistoryLeaderboardRepository(this._history);

  final GameHistoryRepository _history;

  @override
  Future<Result<List<LeaderboardEntry>>> getTop(
    DifficultyLevel level, {
    int limit = 10,
  }) async {
    final loaded = await _history.getHistory(level: level);
    return loaded.fold((games) {
      final wins = games.where((g) => g.outcome == GameOutcome.won).toList()
        ..sort((a, b) => _compareResults(a, b));
      return Result.ok([
        for (var i = 0; i < wins.length && i < limit; i++)
          _entry(wins[i], i + 1),
      ]);
    }, Result.err);
  }

  @override
  Future<Result<LeaderboardEntry?>> getPersonalBest(
    DifficultyLevel level,
  ) async {
    final top = await getTop(level, limit: 1);
    return top.fold(
      (entries) => Result.ok(entries.isEmpty ? null : entries.first),
      Result.err,
    );
  }

  @override
  Future<Result<bool>> submit(GameResult result) async {
    if (result.outcome != GameOutcome.won) return const Result.ok(false);
    final best = await getPersonalBest(result.level);
    return best.fold((entry) {
      if (entry == null ||
          result.duration.compareTo(entry.duration) < 0 ||
          (result.duration == entry.duration && result.moves < entry.moves)) {
        return const Result.ok(true);
      }
      return const Result.ok(false);
    }, Result.err);
  }

  static int _compareResults(GameResult a, GameResult b) {
    final duration = a.duration.compareTo(b.duration);
    return duration != 0 ? duration : a.moves.compareTo(b.moves);
  }

  static LeaderboardEntry _entry(GameResult g, int rank) => LeaderboardEntry(
    rank: rank,
    level: g.level,
    boardSize: g.boardSize,
    duration: g.duration,
    moves: g.moves,
    playedAt: g.playedAt,
  );
}
