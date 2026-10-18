import '../../../../core/result.dart';
import '../entities/difficulty_decision.dart';
import '../entities/difficulty_level.dart';
import '../entities/game_result.dart';
import '../entities/player_stats.dart';
import '../repositories/game_history_repository.dart';
import '../services/difficulty_engine.dart';

/// Preview of the adaptive engine's next decision (shown on the menu).
class ComputeNextDifficulty {
  const ComputeNextDifficulty({required this._engine, required this._history});

  // ignore: unused_field
  final DifficultyEngine _engine;
  // ignore: unused_field
  final GameHistoryRepository _history;

  Future<Result<DifficultyDecision>> call(DifficultyLevel current) async {
    final history = await _history.getHistory(limit: _engine.window);
    return history.fold(
      (items) => Result.ok(_engine.evaluate(history: items, current: current)),
      Result.err,
    );
  }
}

class GetPlayerStats {
  const GetPlayerStats(this._history);

  // ignore: unused_field
  final GameHistoryRepository _history;

  Future<Result<PlayerStats>> call() async {
    final loaded = await _history.getHistory();
    return loaded.fold((items) {
      if (items.isEmpty) return const Result.ok(PlayerStats.empty);
      var wins = 0,
          totalMicros = 0,
          moves = 0,
          winRun = 0,
          lossRun = 0,
          best = 0;
      for (final game in items) {
        if (game.outcome == GameOutcome.won) {
          wins++;
          totalMicros += game.duration.inMicroseconds;
          moves += game.moves;
        }
      }
      for (final game in items) {
        if (game.outcome == GameOutcome.won) {
          winRun++;
          lossRun = 0;
          if (winRun > best) best = winRun;
        } else {
          lossRun++;
          winRun = 0;
        }
      }
      return Result.ok(
        PlayerStats(
          gamesPlayed: items.length,
          wins: wins,
          averageTime: wins == 0
              ? Duration.zero
              : Duration(microseconds: totalMicros ~/ wins),
          averageMoves: wins == 0 ? 0 : moves / wins,
          winStreak: winRun,
          lossStreak: lossRun,
          bestWinStreak: best,
        ),
      );
    }, Result.err);
  }
}
