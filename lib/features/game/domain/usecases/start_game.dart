import 'package:equatable/equatable.dart';

import '../../../../core/result.dart';
import '../entities/difficulty_decision.dart';
import '../entities/difficulty_level.dart';
import '../entities/game_session.dart';
import '../repositories/game_history_repository.dart';
import '../services/difficulty_engine.dart';
import '../services/shuffler.dart';

/// A freshly generated game plus why its difficulty was chosen.
class GameSetup extends Equatable {
  const GameSetup({required this.session, required this.decision});

  final GameSession session;
  final DifficultyDecision decision;

  @override
  List<Object?> get props => [session, decision];
}

/// Builds a new scrambled session (status [GameStatus.ready]).
///
/// With [manualLevel] the base config of that level is used unchanged.
/// Otherwise the engine evaluates the history against [currentLevel].
class StartGame {
  const StartGame({
    required this._engine,
    required this._shuffler,
    required this._history,
  });

  // ignore: unused_field
  final DifficultyEngine _engine;
  // ignore: unused_field
  final Shuffler _shuffler;
  // ignore: unused_field
  final GameHistoryRepository _history;

  Future<Result<GameSetup>> call({
    required DifficultyLevel currentLevel,
    DifficultyLevel? manualLevel,
  }) {
    // TODO(backend): implement; apply AppEnv QA overrides (time limit, shuffle moves).
    throw UnimplementedError();
  }
}
