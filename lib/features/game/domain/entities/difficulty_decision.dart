import 'package:equatable/equatable.dart';

import 'difficulty_level.dart';

enum DifficultyTrend { promoted, demoted, unchanged }

/// What the adaptive engine recommends for the next game.
class DifficultyDecision extends Equatable {
  const DifficultyDecision({
    required this.level,
    required this.trend,
    this.shuffleMultiplier = 1.0,
    this.timeMultiplier = 1.0,
  });

  final DifficultyLevel level;
  final DifficultyTrend trend;

  /// Fine tuning inside the level, both clamped to `[0.8, 1.2]`.
  final double shuffleMultiplier;
  final double timeMultiplier;

  @override
  List<Object?> get props => [level, trend, shuffleMultiplier, timeMultiplier];
}
