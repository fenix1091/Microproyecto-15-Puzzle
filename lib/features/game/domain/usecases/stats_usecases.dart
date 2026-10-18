import '../../../../core/result.dart';
import '../entities/difficulty_decision.dart';
import '../entities/difficulty_level.dart';
import '../entities/player_stats.dart';
import '../repositories/game_history_repository.dart';
import '../services/difficulty_engine.dart';

/// Preview of the adaptive engine's next decision (shown on the menu).
class ComputeNextDifficulty {
  const ComputeNextDifficulty({required this._engine, required this._history});

  // ignore: unused_field
  final DifficultyEngine _engine;
  // ignore: unused_field
  final GameHistoryRepository _history;

  Future<Result<DifficultyDecision>> call(DifficultyLevel current) {
    // TODO(backend): implement.
    throw UnimplementedError();
  }
}

class GetPlayerStats {
  const GetPlayerStats(this._history);

  // ignore: unused_field
  final GameHistoryRepository _history;

  Future<Result<PlayerStats>> call() {
    // TODO(backend): implement.
    throw UnimplementedError();
  }
}
