import '../../../../core/result.dart';
import '../../../../core/utils/clock.dart';
import '../../../leaderboard/domain/repositories/leaderboard_repository.dart';
import '../entities/game_result.dart';
import '../entities/game_session.dart';
import '../repositories/game_history_repository.dart';

/// Converts a session into a [GameResult], saves it to history, submits wins
/// to the leaderboard and flags `isPersonalBest`.
class FinishGame {
  const FinishGame({
    required this._history,
    required this._leaderboard,
    required this._clock,
  });

  // ignore: unused_field
  final GameHistoryRepository _history;
  // ignore: unused_field
  final LeaderboardRepository _leaderboard;
  // ignore: unused_field
  final Clock _clock;

  Future<Result<GameResult>> call(GameSession session, GameOutcome outcome) {
    // TODO(backend): implement.
    throw UnimplementedError();
  }
}
