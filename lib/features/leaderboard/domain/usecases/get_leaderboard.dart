import '../../../../core/result.dart';
import '../../../game/domain/entities/difficulty_level.dart';
import '../entities/leaderboard_entry.dart';
import '../repositories/leaderboard_repository.dart';

class GetLeaderboard {
  const GetLeaderboard(this._repository);

  final LeaderboardRepository _repository;

  Future<Result<List<LeaderboardEntry>>> call(
    DifficultyLevel level, {
    int limit = 10,
  }) => _repository.getTop(level, limit: limit);
}

class GetPersonalBest {
  const GetPersonalBest(this._repository);

  final LeaderboardRepository _repository;

  Future<Result<LeaderboardEntry?>> call(DifficultyLevel level) =>
      _repository.getPersonalBest(level);
}
