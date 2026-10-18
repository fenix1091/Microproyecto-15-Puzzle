import 'package:flutter_test/flutter_test.dart';
import 'package:sliding_puzzle/features/game/domain/entities/board.dart';
import 'package:sliding_puzzle/features/game/domain/entities/difficulty_config.dart';
import 'package:sliding_puzzle/features/game/domain/entities/difficulty_decision.dart';
import 'package:sliding_puzzle/features/game/domain/entities/difficulty_level.dart';
import 'package:sliding_puzzle/features/game/domain/entities/game_result.dart';
import 'package:sliding_puzzle/features/game/domain/entities/game_session.dart';
import 'package:sliding_puzzle/features/game/domain/services/difficulty_engine.dart';
import 'package:sliding_puzzle/features/game/domain/usecases/game_actions.dart';

GameResult result(GameOutcome outcome, int seconds) => GameResult(
  level: DifficultyLevel.medium,
  boardSize: 4,
  moves: 40,
  duration: Duration(seconds: seconds),
  outcome: outcome,
  minSolutionDepth: 25,
  playedAt: DateTime.utc(2026),
  timeLimit: const Duration(minutes: 1),
);

void main() {
  const engine = DifficultyEngine();
  test('promotes after three fast wins', () {
    final d = engine.evaluate(
      history: List.generate(3, (_) => result(GameOutcome.won, 20)),
      current: DifficultyLevel.medium,
    );
    expect(d.level, DifficultyLevel.hard);
    expect(d.trend, DifficultyTrend.promoted);
  });
  test('demotes after two losses, including abandonment', () {
    final d = engine.evaluate(
      history: [
        result(GameOutcome.abandoned, 10),
        result(GameOutcome.lost, 20),
      ],
      current: DifficultyLevel.medium,
    );
    expect(d.level, DifficultyLevel.easy);
  });
  test('empty history stays at level and fine tuning is clamped', () {
    expect(
      engine.evaluate(history: [], current: DifficultyLevel.hard).level,
      DifficultyLevel.hard,
    );
    final slow = engine.evaluate(
      history: [result(GameOutcome.lost, 360)],
      current: DifficultyLevel.medium,
    );
    expect(slow.shuffleMultiplier, inInclusiveRange(.8, 1.2));
    expect(slow.timeMultiplier, inInclusiveRange(.8, 1.2));
  });
  test('config scales move and time targets', () {
    final cfg = engine.configFor(
      const DifficultyDecision(
        level: DifficultyLevel.easy,
        trend: DifficultyTrend.unchanged,
        shuffleMultiplier: 1.2,
        timeMultiplier: .8,
      ),
    );
    expect(cfg.shuffleMoves, 48);
    expect(cfg.timeLimit, const Duration(minutes: 4));
  });
  test('actions validate, tick, pause, resume, restart', () {
    final initial = Board(size: 3, tiles: [1, 2, 3, 4, 5, 6, 7, 0, 8]);
    final cfg = DifficultyConfig.base(DifficultyLevel.easy);
    final session = GameSession(
      initialBoard: initial,
      board: initial,
      config: cfg,
    );
    final move = const MoveTile().call(session, 8).valueOrNull!;
    expect(move.moves, 1);
    expect(move.status, GameStatus.won);
    expect(const MoveTile().call(session, 0).isOk, isFalse);
    final playing = session.copyWith(status: GameStatus.playing);
    expect(
      const TickGame().call(playing, const Duration(minutes: 6)).status,
      GameStatus.lost,
    );
    expect(
      const PauseGame().call(playing).valueOrNull!.status,
      GameStatus.paused,
    );
    expect(
      const ResumeGame()
          .call(playing.copyWith(status: GameStatus.paused))
          .valueOrNull!
          .status,
      GameStatus.playing,
    );
    expect(const RestartGame().call(playing).status, GameStatus.ready);
  });
}
