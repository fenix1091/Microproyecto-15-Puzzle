import '../../../../core/result.dart';
import '../entities/difficulty_level.dart';
import '../entities/game_result.dart';

abstract interface class GameHistoryRepository {
  Future<Result<void>> save(GameResult result);

  /// Newest first, optionally filtered by [level] and capped at [limit].
  Future<Result<List<GameResult>>> getHistory({
    DifficultyLevel? level,
    int? limit,
  });

  Future<Result<void>> clear();
}
