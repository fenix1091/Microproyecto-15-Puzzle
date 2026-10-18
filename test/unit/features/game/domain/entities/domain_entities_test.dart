import 'package:flutter_test/flutter_test.dart';
import 'package:sliding_puzzle/features/game/domain/entities/board.dart';
import 'package:sliding_puzzle/features/game/domain/entities/difficulty_config.dart';
import 'package:sliding_puzzle/features/game/domain/entities/difficulty_decision.dart';
import 'package:sliding_puzzle/features/game/domain/entities/difficulty_level.dart';
import 'package:sliding_puzzle/features/game/domain/entities/game_result.dart';
import 'package:sliding_puzzle/features/game/domain/entities/game_session.dart';

void main() {
  test('difficulty levels clamp ends and parse keys', () {
    expect(DifficultyLevel.easy.previous, DifficultyLevel.easy);
    expect(DifficultyLevel.master.next, DifficultyLevel.master);
    expect(DifficultyLevel.fromKey('expert'), DifficultyLevel.expert);
    expect(DifficultyLevel.fromKey('unknown'), DifficultyLevel.easy);
    expect(DifficultyLevel.master.isLast, isTrue);
    expect(DifficultyLevel.easy.isFirst, isTrue);
  });
  test('configs cover tiers and copyWith', () {
    for (final level in DifficultyLevel.values) {
      final c = DifficultyConfig.base(level);
      expect(c.boardSize, inInclusiveRange(3, 6));
      expect(c.copyWith(minSolutionDepth: 5).minSolutionDepth, 5);
      expect(c.copyWith().shuffleMoves, c.shuffleMoves);
    }
  });
  test('decision and result values', () {
    const d = DifficultyDecision(
      level: DifficultyLevel.hard,
      trend: DifficultyTrend.demoted,
    );
    expect(d.props, [DifficultyLevel.hard, DifficultyTrend.demoted, 1.0, 1.0]);
    final r = GameResult(
      level: DifficultyLevel.easy,
      boardSize: 3,
      moves: 20,
      duration: const Duration(seconds: 5),
      outcome: GameOutcome.won,
      minSolutionDepth: 10,
      playedAt: DateTime.utc(2026),
    );
    expect(r.isWin, isTrue);
    expect(r.copyWith(isPersonalBest: true).isPersonalBest, isTrue);
  });
  test('session remaining and status helpers', () {
    final b = Board.solved(3), c = DifficultyConfig.base(DifficultyLevel.easy);
    final s = GameSession(initialBoard: b, board: b, config: c);
    expect(s.remaining, c.timeLimit);
    expect(
      s.copyWith(elapsed: const Duration(minutes: 6)).remaining,
      Duration.zero,
    );
    expect(s.copyWith(status: GameStatus.won).isFinished, isTrue);
    expect(s.copyWith(status: GameStatus.lost).isFinished, isTrue);
    expect(s.copyWith(moves: 2).moves, 2);
    expect(
      GameSession(
        initialBoard: b,
        board: b,
        config: DifficultyConfig(
          level: c.level,
          boardSize: c.boardSize,
          shuffleMoves: c.shuffleMoves,
          timeLimit: null,
          minSolutionDepth: c.minSolutionDepth,
        ),
      ).remaining,
      isNull,
    );
  });
}
