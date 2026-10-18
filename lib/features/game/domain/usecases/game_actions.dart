import '../../../../core/result.dart';
import '../entities/game_session.dart';

/// Taps tile [index]. A `ready` session becomes `playing` on its first valid
/// move; a solved board becomes `won`. Fails with `InvalidMoveFailure` when
/// the tile cannot move and `GameStateFailure` when not ready/playing.
class MoveTile {
  const MoveTile();

  Result<GameSession> call(GameSession session, int index) {
    // TODO(backend): implement.
    throw UnimplementedError();
  }
}

/// Adds [delta] of play time to a `playing` session; marks it `lost` when the
/// time limit is reached. Other statuses are returned unchanged.
class TickGame {
  const TickGame();

  GameSession call(GameSession session, Duration delta) {
    // TODO(backend): implement.
    throw UnimplementedError();
  }
}

/// `playing` → `paused`.
class PauseGame {
  const PauseGame();

  Result<GameSession> call(GameSession session) {
    // TODO(backend): implement.
    throw UnimplementedError();
  }
}

/// `paused` → `playing`.
class ResumeGame {
  const ResumeGame();

  Result<GameSession> call(GameSession session) {
    // TODO(backend): implement.
    throw UnimplementedError();
  }
}

/// Back to the initial scramble with zero moves/time and status `ready`.
class RestartGame {
  const RestartGame();

  GameSession call(GameSession session) {
    // TODO(backend): implement.
    throw UnimplementedError();
  }
}
