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
    // TODO(backend): implement.
    throw UnimplementedError();
  }

  /// Applies [decision] to the base config of its level.
  DifficultyConfig configFor(DifficultyDecision decision) {
    // TODO(backend): implement (round shuffle moves, scale time limit).
    throw UnimplementedError();
  }
}
