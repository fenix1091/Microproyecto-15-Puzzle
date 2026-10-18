import '../../../../core/result.dart';
import '../../../../core/utils/clock.dart';
import '../../../leaderboard/domain/repositories/leaderboard_repository.dart';
import '../entities/game_result.dart';
import '../entities/game_session.dart';
import '../repositories/game_history_repository.dart';
import '../services/heuristics.dart';

/// Converts a session into a [GameResult], saves it to history, submits wins
/// to the leaderboard and flags `isPersonalBest`.
class FinishGame {
  const FinishGame({
    required this._history,
    required this._leaderboard,
    required this._clock,
  });

  final GameHistoryRepository _history;
  final LeaderboardRepository _leaderboard;
  final Clock _clock;

  Future<Result<GameResult>> call(
    GameSession session,
    GameOutcome outcome,
  ) async {
    var result = GameResult(
      level: session.config.level,
      boardSize: session.config.boardSize,
      moves: session.moves,
      duration: session.elapsed,
      outcome: outcome,
      minSolutionDepth: Heuristics.lowerBound(session.initialBoard),
      playedAt: _clock.now(),
      timeLimit: session.config.timeLimit,
    );
    if (outcome == GameOutcome.won) {
      final submitted = await _leaderboard.submit(result);
      if (submitted case Err<bool>(:final failure)) return Result.err(failure);
      result = result.copyWith(isPersonalBest: (submitted as Ok<bool>).value);
    }
    final saved = await _history.save(result);
    if (saved case Err<void>(:final failure)) return Result.err(failure);
    return Result.ok(result);
  }
}
