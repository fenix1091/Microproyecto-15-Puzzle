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

  final DifficultyEngine _engine;
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

  final GameHistoryRepository _history;

  Future<Result<PlayerStats>> call() async {
    final loaded = await _history.getHistory();
    return loaded.fold((items) {
      if (items.isEmpty) return const Result.ok(PlayerStats.empty);
      var wins = 0;
      var totalMicros = 0;
      var moves = 0;
      var runningWins = 0;
      var best = 0;
      var currentWins = 0;
      var currentLosses = 0;
      var currentStreakOpen = true;
      final latestWasWin = items.first.outcome == GameOutcome.won;
      for (final game in items) {
        if (game.outcome == GameOutcome.won) {
          wins++;
          totalMicros += game.duration.inMicroseconds;
          moves += game.moves;
          runningWins++;
          if (runningWins > best) best = runningWins;
        } else {
          runningWins = 0;
        }
        if (currentStreakOpen) {
          final isWin = game.outcome == GameOutcome.won;
          if (isWin == latestWasWin) {
            if (latestWasWin) {
              currentWins++;
            } else {
              currentLosses++;
            }
          } else {
            currentStreakOpen = false;
          }
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
          winStreak: currentWins,
          lossStreak: currentLosses,
          bestWinStreak: best,
        ),
      );
    }, Result.err);
  }
}
