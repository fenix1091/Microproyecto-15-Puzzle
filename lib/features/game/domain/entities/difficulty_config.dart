import 'package:equatable/equatable.dart';

import 'difficulty_level.dart';

/// Concrete parameters a game is generated and judged with.
class DifficultyConfig extends Equatable {
  const DifficultyConfig({
    required this.level,
    required this.boardSize,
    required this.shuffleMoves,
    required this.timeLimit,
    required this.minSolutionDepth,
  });

  /// Base table from the spec; [DifficultyEngine] scales it ±20 %.
  factory DifficultyConfig.base(DifficultyLevel level) => switch (level) {
    DifficultyLevel.easy => const DifficultyConfig(
      level: DifficultyLevel.easy,
      boardSize: 3,
      shuffleMoves: 40,
      timeLimit: Duration(minutes: 5),
      minSolutionDepth: 10,
    ),
    DifficultyLevel.medium => const DifficultyConfig(
      level: DifficultyLevel.medium,
      boardSize: 4,
      shuffleMoves: 100,
      timeLimit: Duration(minutes: 6),
      minSolutionDepth: 25,
    ),
    DifficultyLevel.hard => const DifficultyConfig(
      level: DifficultyLevel.hard,
      boardSize: 4,
      shuffleMoves: 200,
      timeLimit: Duration(minutes: 4),
      minSolutionDepth: 40,
    ),
    DifficultyLevel.expert => const DifficultyConfig(
      level: DifficultyLevel.expert,
      boardSize: 5,
      shuffleMoves: 400,
      timeLimit: Duration(minutes: 8),
      minSolutionDepth: 70,
    ),
    DifficultyLevel.master => const DifficultyConfig(
      level: DifficultyLevel.master,
      boardSize: 6,
      shuffleMoves: 800,
      timeLimit: Duration(minutes: 12),
      minSolutionDepth: 110,
    ),
  };

  final DifficultyLevel level;

  /// Tiles per side (3..6).
  final int boardSize;

  /// Random-walk length used to scramble the solved board.
  final int shuffleMoves;

  /// Time allowed before the game is lost; `null` means unlimited.
  final Duration? timeLimit;

  /// Minimum admissible lower bound (Manhattan + linear conflict) the
  /// scrambled board must reach.
  final int minSolutionDepth;

  DifficultyConfig copyWith({
    int? shuffleMoves,
    Duration? timeLimit,
    int? minSolutionDepth,
  }) => DifficultyConfig(
    level: level,
    boardSize: boardSize,
    shuffleMoves: shuffleMoves ?? this.shuffleMoves,
    timeLimit: timeLimit ?? this.timeLimit,
    minSolutionDepth: minSolutionDepth ?? this.minSolutionDepth,
  );

  @override
  List<Object?> get props => [
    level,
    boardSize,
    shuffleMoves,
    timeLimit,
    minSolutionDepth,
  ];
}
