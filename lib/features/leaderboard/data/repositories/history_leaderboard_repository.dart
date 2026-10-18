import '../../../../core/result.dart';
import '../../../game/domain/entities/difficulty_level.dart';
import '../../../game/domain/entities/game_result.dart';
import '../../../game/domain/repositories/game_history_repository.dart';
import '../../domain/entities/leaderboard_entry.dart';
import '../../domain/repositories/leaderboard_repository.dart';

/// Derives rankings from the game history (single source of truth).
class HistoryLeaderboardRepository implements LeaderboardRepository {
  const HistoryLeaderboardRepository(this._history);

  // ignore: unused_field
  final GameHistoryRepository _history;

  @override
  Future<Result<List<LeaderboardEntry>>> getTop(
    DifficultyLevel level, {
    int limit = 10,
  }) {
    // TODO(backend): implement.
    throw UnimplementedError();
  }

  @override
  Future<Result<LeaderboardEntry?>> getPersonalBest(DifficultyLevel level) {
    // TODO(backend): implement.
    throw UnimplementedError();
  }

  @override
  Future<Result<bool>> submit(GameResult result) {
    // TODO(backend): implement (compare against best before the result is saved).
    throw UnimplementedError();
  }
}
