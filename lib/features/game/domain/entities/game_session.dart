import 'package:equatable/equatable.dart';

import 'board.dart';
import 'difficulty_config.dart';

enum GameStatus { ready, playing, paused, won, lost }

/// Snapshot of a game in progress.
class GameSession extends Equatable {
  const GameSession({
    required this.initialBoard,
    required this.board,
    required this.config,
    this.moves = 0,
    this.elapsed = Duration.zero,
    this.status = GameStatus.ready,
  });

  /// Scrambled board the game started from; used by restart.
  final Board initialBoard;
  final Board board;
  final DifficultyConfig config;

  /// Number of taps that moved tiles (a multi-tile slide counts as one).
  final int moves;

  /// Active play time, excluding pauses.
  final Duration elapsed;
  final GameStatus status;

  bool get isFinished => status == GameStatus.won || status == GameStatus.lost;

  /// Time left, or `null` when the level has no limit.
  Duration? get remaining {
    final limit = config.timeLimit;
    if (limit == null) return null;
    final left = limit - elapsed;
    return left.isNegative ? Duration.zero : left;
  }

  GameSession copyWith({
    Board? board,
    int? moves,
    Duration? elapsed,
    GameStatus? status,
  }) => GameSession(
    initialBoard: initialBoard,
    board: board ?? this.board,
    config: config,
    moves: moves ?? this.moves,
    elapsed: elapsed ?? this.elapsed,
    status: status ?? this.status,
  );

  @override
  List<Object?> get props => [
    initialBoard,
    board,
    config,
    moves,
    elapsed,
    status,
  ];
}
