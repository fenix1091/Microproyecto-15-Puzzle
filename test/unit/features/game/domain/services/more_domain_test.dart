import 'package:flutter_test/flutter_test.dart';
import 'package:sliding_puzzle/features/game/domain/entities/difficulty_level.dart';
import 'package:sliding_puzzle/features/game/domain/entities/game_result.dart';
import 'package:sliding_puzzle/features/game/domain/entities/player_stats.dart';
import 'package:sliding_puzzle/features/game/domain/services/difficulty_engine.dart';

void main() {
  test('stats empty and win rate aggregate fields', () {
    expect(PlayerStats.empty.winRate, 0);
    const s = PlayerStats(
      gamesPlayed: 4,
      wins: 2,
      averageTime: Duration(seconds: 3),
      averageMoves: 9,
      winStreak: 1,
      lossStreak: 0,
      bestWinStreak: 2,
    );
    expect(s.winRate, .5);
    expect(s.props, hasLength(7));
  });
  test('loss result flags, optional time limit, and props', () {
    final r = GameResult(
      level: DifficultyLevel.medium,
      boardSize: 4,
      moves: 9,
      duration: Duration.zero,
      outcome: GameOutcome.lost,
      minSolutionDepth: 20,
      playedAt: DateTime.utc(2026),
    );
    expect(r.isWin, isFalse);
    expect(r.timeLimit, isNull);
    expect(r.props, hasLength(9));
    expect(r.copyWith().outcome, GameOutcome.lost);
  });
  test('difficulty stays and clamps adjustments at both extremes', () {
    const e = DifficultyEngine();
    GameResult r(int sec, int moves) => GameResult(
      level: DifficultyLevel.easy,
      boardSize: 3,
      moves: moves,
      duration: Duration(seconds: sec),
      outcome: GameOutcome.won,
      minSolutionDepth: 10,
      playedAt: DateTime.utc(2026),
      timeLimit: const Duration(seconds: 100),
    );
    final stay = e.evaluate(
      history: [r(80, 20)],
      current: DifficultyLevel.medium,
    );
    expect(stay.level, DifficultyLevel.medium);
    expect(stay.shuffleMultiplier, 1);
    final fast = e.evaluate(
      history: [r(0, 0)],
      current: DifficultyLevel.medium,
    );
    expect(fast.shuffleMultiplier, 1.2);
    expect(fast.timeMultiplier, .8);
    final slow = e.evaluate(
      history: [r(90, 60)],
      current: DifficultyLevel.medium,
    );
    expect(slow.shuffleMultiplier, closeTo(.9667, .001));
    expect(slow.timeMultiplier, closeTo(1.1333, .001));
  });
  test('losses and abandonments take the slow fine-tuning branch', () {
    GameResult result(GameOutcome outcome) => GameResult(
      level: DifficultyLevel.medium,
      boardSize: 4,
      moves: 1,
      duration: const Duration(seconds: 1),
      outcome: outcome,
      minSolutionDepth: 25,
      playedAt: DateTime.utc(2026),
      timeLimit: const Duration(minutes: 6),
    );
    const engine = DifficultyEngine();
    for (final outcome in [GameOutcome.lost, GameOutcome.abandoned]) {
      final decision = engine.evaluate(
        history: [result(outcome)],
        current: DifficultyLevel.medium,
      );
      expect(decision.shuffleMultiplier, lessThanOrEqualTo(1));
      expect(decision.timeMultiplier, greaterThan(1));
    }
    final olderAbandon = engine.evaluate(
      history: [result(GameOutcome.won), result(GameOutcome.abandoned)],
      current: DifficultyLevel.medium,
    );
    expect(olderAbandon.shuffleMultiplier, greaterThan(1));
  });
}
