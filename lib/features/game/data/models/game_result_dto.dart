import '../../domain/entities/difficulty_level.dart';
import '../../domain/entities/game_result.dart';

/// Versioned plain-map representation used by Hive without adapters.
class GameResultDto {
  const GameResultDto._();

  static Map<String, Object?> toMap(GameResult r) => {
    'schemaVersion': 1,
    'level': r.level.key,
    'boardSize': r.boardSize,
    'moves': r.moves,
    'durationMs': r.duration.inMilliseconds,
    'outcome': r.outcome.name,
    'minSolutionDepth': r.minSolutionDepth,
    'playedAt': r.playedAt.toIso8601String(),
    'timeLimitMs': r.timeLimit?.inMilliseconds,
    'isPersonalBest': r.isPersonalBest,
  };

  static GameResult? fromMap(Map<dynamic, dynamic> map) {
    try {
      if (map['schemaVersion'] != 1) return null;
      final level = map['level'] as String;
      final outcome = GameOutcome.values.byName(map['outcome'] as String);
      final limit = map['timeLimitMs'];
      return GameResult(
        level: DifficultyLevel.fromKey(level),
        boardSize: map['boardSize'] as int,
        moves: map['moves'] as int,
        duration: Duration(milliseconds: map['durationMs'] as int),
        outcome: outcome,
        minSolutionDepth: map['minSolutionDepth'] as int,
        playedAt: DateTime.parse(map['playedAt'] as String),
        timeLimit: limit == null ? null : Duration(milliseconds: limit as int),
        isPersonalBest: map['isPersonalBest'] as bool? ?? false,
      );
    } on Object {
      return null;
    }
  }
}
