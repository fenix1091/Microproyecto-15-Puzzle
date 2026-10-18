import 'package:equatable/equatable.dart';

import 'difficulty_level.dart';

enum GameOutcome { won, lost, abandoned }

/// A finished game, as stored in history and shown on the result screen.
class GameResult extends Equatable {
  const GameResult({
    required this.level,
    required this.boardSize,
    required this.moves,
    required this.duration,
    required this.outcome,
    required this.minSolutionDepth,
    required this.playedAt,
    this.timeLimit,
    this.isPersonalBest = false,
  });

  final DifficultyLevel level;
  final int boardSize;
  final int moves;
  final Duration duration;
  final GameOutcome outcome;

  /// Lower bound of the scrambled board; used to judge move efficiency.
  final int minSolutionDepth;
  final DateTime playedAt;
  final Duration? timeLimit;

  /// Set by `FinishGame` when this win beats the previous best for [level].
  final bool isPersonalBest;

  bool get isWin => outcome == GameOutcome.won;

  GameResult copyWith({bool? isPersonalBest}) => GameResult(
    level: level,
    boardSize: boardSize,
    moves: moves,
    duration: duration,
    outcome: outcome,
    minSolutionDepth: minSolutionDepth,
    playedAt: playedAt,
    timeLimit: timeLimit,
    isPersonalBest: isPersonalBest ?? this.isPersonalBest,
  );

  @override
  List<Object?> get props => [
    level,
    boardSize,
    moves,
    duration,
    outcome,
    minSolutionDepth,
    playedAt,
    timeLimit,
    isPersonalBest,
  ];
}
