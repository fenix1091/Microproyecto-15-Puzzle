import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities/difficulty_level.dart';
import 'game_state.dart';

final gameControllerProvider = NotifierProvider<GameController, GameState>(
  GameController.new,
);

/// Drives one game: generation, moves, 1 s ticking timer, pause, finish.
///
/// - The timer runs only while the session is `playing` (starts on the first
///   valid move) and is cancelled on pause/finish/dispose.
/// - Emits feedback via `feedbackServiceProvider` (move/invalid/win/lose).
/// - On win/loss/abandon calls `FinishGame`, stores [GameState.result], and
///   when adaptive difficulty is on, persists the new current level through
///   `settingsControllerProvider`.
class GameController extends Notifier<GameState> {
  @override
  GameState build() {
    // TODO(backend): register ref.onDispose to cancel the timer.
    return const GameState();
  }

  /// Generates a new game. [level] forces a manual level; otherwise settings
  /// decide (adaptive engine or `manualLevel`).
  Future<void> start({DifficultyLevel? level}) async {
    // TODO(backend): implement.
    throw UnimplementedError();
  }

  void tap(int index) {
    // TODO(backend): implement.
    throw UnimplementedError();
  }

  void pause() {
    // TODO(backend): implement.
    throw UnimplementedError();
  }

  void resume() {
    // TODO(backend): implement.
    throw UnimplementedError();
  }

  void restart() {
    // TODO(backend): implement.
    throw UnimplementedError();
  }

  /// Leaving mid-game records the game as abandoned (counts as a loss).
  /// Does nothing if no move was made yet.
  Future<void> abandon() async {
    // TODO(backend): implement.
    throw UnimplementedError();
  }
}
