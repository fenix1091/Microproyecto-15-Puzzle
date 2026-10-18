import '../entities/difficulty_config.dart';
import '../entities/difficulty_decision.dart';
import '../entities/difficulty_level.dart';
import '../entities/game_result.dart';

/// Pure adaptive-difficulty rules.
///
/// Looks at the last [window] results (newest first):
/// - time ratio = duration / timeLimit, move ratio = moves / minSolutionDepth.
/// - Promote when winStreak >= 3 and the average time ratio of wins < 0.6.
/// - Demote when lossStreak >= 2 or the average time ratio > 0.95.
/// - Otherwise stay, and nudge shuffle/time multipliers within [0.8, 1.2]
///   toward harder when the player is fast and efficient, easier when slow.
/// Abandoned games count as losses.
class DifficultyEngine {
  const DifficultyEngine({this.window = 10});

  final int window;

  DifficultyDecision evaluate({
    required List<GameResult> history,
    required DifficultyLevel current,
  }) {
    final recent = history.take(window).toList();
    if (recent.isEmpty) {
      return DifficultyDecision(
        level: current,
        trend: DifficultyTrend.unchanged,
      );
    }
    var winRun = 0;
    var lossRun = 0;
    var streakOpen = true;
    bool? streakIsWin;
    final winRatios = <double>[];
    final recentRatios = <double>[];
    for (final result in recent) {
      final ratio = _timeRatio(result);
      recentRatios.add(ratio);
      if (result.outcome == GameOutcome.won) {
        winRatios.add(ratio);
      }
      if (streakOpen) {
        final isWin = result.outcome == GameOutcome.won;
        streakIsWin ??= isWin;
        if (isWin == streakIsWin) {
          if (streakIsWin) {
            winRun++;
          } else {
            lossRun++;
          }
        } else {
          streakOpen = false;
        }
      }
    }
    final average = recentRatios.reduce((a, b) => a + b) / recentRatios.length;
    final averageWins = winRatios.isEmpty
        ? 0.0
        : winRatios.reduce((a, b) => a + b) / winRatios.length;
    if (winRun >= 3 && averageWins < .6 && !current.isLast) {
      return DifficultyDecision(
        level: current.next,
        trend: DifficultyTrend.promoted,
      );
    }
    if ((lossRun >= 2 || average > .95) && !current.isFirst) {
      return DifficultyDecision(
        level: current.previous,
        trend: DifficultyTrend.demoted,
      );
    }
    final last = recent.first;
    final timeRatio = _timeRatio(last);
    final moveRatio = last.minSolutionDepth == 0
        ? 0.0
        : last.moves / last.minSolutionDepth;
    // Fine tuning uses the last game; only a win can enter the fast branch.
    if (last.outcome == GameOutcome.won && timeRatio < .75 && moveRatio < 2.5) {
      final amount = ((.75 - timeRatio) / .75).clamp(0.0, 1.0);
      return DifficultyDecision(
        level: current,
        trend: DifficultyTrend.unchanged,
        shuffleMultiplier: (1.1 + amount * .1).clamp(.8, 1.2),
        timeMultiplier: (.9 - amount * .1).clamp(.8, 1.2),
      );
    }
    if (last.outcome != GameOutcome.won || timeRatio > .85) {
      final amount = last.outcome == GameOutcome.won
          ? ((timeRatio - .85) / .15).clamp(0.0, 1.0) * .1
          : 0.0;
      return DifficultyDecision(
        level: current,
        trend: DifficultyTrend.unchanged,
        shuffleMultiplier: (1.0 - amount).clamp(.8, 1.2),
        timeMultiplier: (1.1 + amount).clamp(.8, 1.2),
      );
    }
    return DifficultyDecision(level: current, trend: DifficultyTrend.unchanged);
  }

  static double _timeRatio(GameResult result) =>
      result.timeLimit == null || result.timeLimit!.inMicroseconds == 0
      ? 0.0
      : result.duration.inMicroseconds / result.timeLimit!.inMicroseconds;

  /// Applies [decision] to the base config of its level.
  DifficultyConfig configFor(DifficultyDecision decision) {
    final base = DifficultyConfig.base(decision.level);
    final limit = base.timeLimit;
    return base.copyWith(
      shuffleMoves: (base.shuffleMoves * decision.shuffleMultiplier).round(),
      timeLimit: limit == null
          ? null
          : Duration(
              microseconds: (limit.inMicroseconds * decision.timeMultiplier)
                  .round(),
            ),
    );
  }
}
