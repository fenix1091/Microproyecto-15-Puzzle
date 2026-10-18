import 'package:equatable/equatable.dart';

import '../../../game/domain/entities/difficulty_level.dart';

/// A ranked win. Ordering: shorter [duration] first, then fewer [moves].
class LeaderboardEntry extends Equatable {
  const LeaderboardEntry({
    required this.rank,
    required this.level,
    required this.boardSize,
    required this.duration,
    required this.moves,
    required this.playedAt,
  });

  /// 1-based position within the level's leaderboard.
  final int rank;
  final DifficultyLevel level;
  final int boardSize;
  final Duration duration;
  final int moves;
  final DateTime playedAt;

  @override
  List<Object?> get props => [
    rank,
    level,
    boardSize,
    duration,
    moves,
    playedAt,
  ];
}
