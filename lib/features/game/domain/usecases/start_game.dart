import 'package:equatable/equatable.dart';

import '../../../../core/config/app_env.dart';
import '../../../../core/result.dart';
import '../entities/difficulty_config.dart';
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
    int? qaShuffleMoves,
    int? qaTimeLimitSeconds,
  }) : _qaShuffleMoves = qaShuffleMoves ?? AppEnv.qaShuffleMoves,
       _qaTimeLimitSeconds = qaTimeLimitSeconds ?? AppEnv.qaTimeLimitSeconds;

  final DifficultyEngine _engine;
  final Shuffler _shuffler;
  final GameHistoryRepository _history;
  final int _qaShuffleMoves;
  final int _qaTimeLimitSeconds;

  Future<Result<GameSetup>> call({
    required DifficultyLevel currentLevel,
    DifficultyLevel? manualLevel,
  }) async {
    final historyResult = manualLevel == null
        ? await _history.getHistory(limit: _engine.window)
        : null;
    // If local history cannot be read, keep the current tier and let the game
    // start; this degrades gracefully instead of blocking play on storage.
    final history = historyResult?.valueOrNull ?? const [];
    final decision = manualLevel == null
        ? _engine.evaluate(history: history, current: currentLevel)
        : DifficultyDecision(
            level: manualLevel,
            trend: DifficultyTrend.unchanged,
          );
    var config = manualLevel == null
        ? _engine.configFor(decision)
        : DifficultyConfig.base(manualLevel);
    if (_qaShuffleMoves > 0 || _qaTimeLimitSeconds > 0) {
      config = DifficultyConfig(
        level: config.level,
        boardSize: config.boardSize,
        shuffleMoves: _qaShuffleMoves > 0
            ? _qaShuffleMoves
            : config.shuffleMoves,
        timeLimit: _qaTimeLimitSeconds > 0
            ? Duration(seconds: _qaTimeLimitSeconds)
            : config.timeLimit,
        minSolutionDepth: _qaShuffleMoves > 0 ? 0 : config.minSolutionDepth,
      );
    }
    final board = _shuffler.shuffle(config);
    return Result.ok(
      GameSetup(
        session: GameSession(initialBoard: board, board: board, config: config),
        decision: decision,
      ),
    );
  }
}
