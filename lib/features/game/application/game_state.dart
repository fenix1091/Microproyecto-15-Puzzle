import 'package:equatable/equatable.dart';

import '../../../core/errors/failure.dart';
import '../domain/entities/difficulty_decision.dart';
import '../domain/entities/game_result.dart';
import '../domain/entities/game_session.dart';

/// Everything the game screen renders.
class GameState extends Equatable {
  const GameState({
    this.session,
    this.decision,
    this.result,
    this.isStarting = false,
    this.failure,
    this.invalidTapIndex,
    this.invalidTapCount = 0,
  });

  /// `null` until [GameController.start] completes.
  final GameSession? session;

  /// Why this level/config was picked (show "¡Subiste de nivel!" etc.).
  final DifficultyDecision? decision;

  /// Set once a game is won, lost, or abandoned, including when persistence
  /// fails. The UI navigates to the result screen only for wins and losses;
  /// abandoning returns to the menu.
  final GameResult? result;

  final bool isStarting;

  /// Last non-move failure (e.g. storage). Invalid moves use the fields below.
  final Failure? failure;

  /// Index of the last rejected tap; [invalidTapCount] increments on every
  /// rejection so the UI can replay the shake even for the same tile.
  final int? invalidTapIndex;
  final int invalidTapCount;

  GameState copyWith({
    GameSession? session,
    DifficultyDecision? decision,
    GameResult? result,
    bool? isStarting,
    Failure? failure,
    int? invalidTapIndex,
    int? invalidTapCount,
    bool clearResult = false,
    bool clearFailure = false,
    bool clearInvalidTap = false,
  }) => GameState(
    session: session ?? this.session,
    decision: decision ?? this.decision,
    result: clearResult ? null : (result ?? this.result),
    isStarting: isStarting ?? this.isStarting,
    failure: clearFailure ? null : (failure ?? this.failure),
    invalidTapIndex: clearInvalidTap
        ? null
        : (invalidTapIndex ?? this.invalidTapIndex),
    invalidTapCount: invalidTapCount ?? this.invalidTapCount,
  );

  @override
  List<Object?> get props => [
    session,
    decision,
    result,
    isStarting,
    failure,
    invalidTapIndex,
    invalidTapCount,
  ];
}
