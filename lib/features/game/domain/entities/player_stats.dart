import 'package:equatable/equatable.dart';

/// Aggregates over the player's history (abandoned games count as losses).
class PlayerStats extends Equatable {
  const PlayerStats({
    required this.gamesPlayed,
    required this.wins,
    required this.averageTime,
    required this.averageMoves,
    required this.winStreak,
    required this.lossStreak,
    required this.bestWinStreak,
  });

  static const empty = PlayerStats(
    gamesPlayed: 0,
    wins: 0,
    averageTime: Duration.zero,
    averageMoves: 0,
    winStreak: 0,
    lossStreak: 0,
    bestWinStreak: 0,
  );

  final int gamesPlayed;
  final int wins;

  /// Averages over won games only.
  final Duration averageTime;
  final double averageMoves;

  /// Current streaks; at most one of them is non-zero.
  final int winStreak;
  final int lossStreak;
  final int bestWinStreak;

  double get winRate => gamesPlayed == 0 ? 0 : wins / gamesPlayed;

  @override
  List<Object?> get props => [
    gamesPlayed,
    wins,
    averageTime,
    averageMoves,
    winStreak,
    lossStreak,
    bestWinStreak,
  ];
}
