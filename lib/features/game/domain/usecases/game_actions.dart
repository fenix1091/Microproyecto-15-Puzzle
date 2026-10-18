import '../../../../core/errors/failure.dart';
import '../../../../core/result.dart';
import '../entities/game_session.dart';

/// Taps tile [index]. A `ready` session becomes `playing` on its first valid
/// move; a solved board becomes `won`. Fails with `InvalidMoveFailure` when
/// the tile cannot move and `GameStateFailure` when not ready/playing.
class MoveTile {
  const MoveTile();

  Result<GameSession> call(GameSession session, int index) {
    if (session.status != GameStatus.ready &&
        session.status != GameStatus.playing) {
      return const Result.err(GameStateFailure('Game is not active'));
    }
    if (!session.board.canMove(index)) {
      return const Result.err(InvalidMoveFailure());
    }
    final board = session.board.move(index);
    return Result.ok(
      session.copyWith(
        board: board,
        moves: session.moves + 1,
        status: board.isSolved ? GameStatus.won : GameStatus.playing,
      ),
    );
  }
}

/// Adds [delta] of play time to a `playing` session; marks it `lost` when the
/// time limit is reached. Other statuses are returned unchanged.
class TickGame {
  const TickGame();

  GameSession call(GameSession session, Duration delta) {
    if (session.status != GameStatus.playing) return session;
    final elapsed = session.elapsed + delta;
    return session.copyWith(
      elapsed: elapsed,
      status:
          session.config.timeLimit != null &&
              elapsed >= session.config.timeLimit!
          ? GameStatus.lost
          : session.status,
    );
  }
}

/// `playing` → `paused`.
class PauseGame {
  const PauseGame();

  Result<GameSession> call(GameSession session) {
    return session.status == GameStatus.playing
        ? Result.ok(session.copyWith(status: GameStatus.paused))
        : const Result.err(GameStateFailure('Game is not playing'));
  }
}

/// `paused` → `playing`.
class ResumeGame {
  const ResumeGame();

  Result<GameSession> call(GameSession session) {
    return session.status == GameStatus.paused
        ? Result.ok(session.copyWith(status: GameStatus.playing))
        : const Result.err(GameStateFailure('Game is not paused'));
  }
}

/// Back to the initial scramble with zero moves/time and status `ready`.
class RestartGame {
  const RestartGame();

  GameSession call(GameSession session) {
    return GameSession(
      initialBoard: session.initialBoard,
      board: session.initialBoard,
      config: session.config,
    );
  }
}
