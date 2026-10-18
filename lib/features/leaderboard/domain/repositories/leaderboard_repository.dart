import '../../../../core/result.dart';
import '../../../game/domain/entities/difficulty_level.dart';
import '../../../game/domain/entities/game_result.dart';
import '../entities/leaderboard_entry.dart';

abstract interface class LeaderboardRepository {
  /// Best [limit] wins for [level], ranked.
  Future<Result<List<LeaderboardEntry>>> getTop(
    DifficultyLevel level, {
    int limit = 10,
  });

  /// Best win for [level], or `null` if the player never won it.
  Future<Result<LeaderboardEntry?>> getPersonalBest(DifficultyLevel level);

  /// Records a win; returns `true` when it is a new personal best.
  /// Non-wins are ignored and return `false`.
  Future<Result<bool>> submit(GameResult result);
}
