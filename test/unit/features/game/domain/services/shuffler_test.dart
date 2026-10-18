import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:sliding_puzzle/core/utils/random_source.dart';
import 'package:sliding_puzzle/features/game/domain/entities/difficulty_config.dart';
import 'package:sliding_puzzle/features/game/domain/entities/difficulty_level.dart';
import 'package:sliding_puzzle/features/game/domain/services/heuristics.dart';
import 'package:sliding_puzzle/features/game/domain/services/shuffler.dart';
import 'package:sliding_puzzle/features/game/domain/services/solvability.dart';

class Seeded implements RandomSource {
  Seeded(int seed) : random = Random(seed);
  final Random random;
  @override
  int nextInt(int max) => random.nextInt(max);
}

void main() {
  test('seeded shuffles stay solvable and unsolved; meet requested bound when reachable', () {
    for (var seed = 0; seed < 1001; seed++) {
      final cfg = DifficultyConfig.base(DifficultyLevel.easy);
      final board = Shuffler(Seeded(seed)).shuffle(cfg);
      expect(isSolvable(board), isTrue, reason: 'seed $seed');
      expect(board.isSolved, isFalse, reason: 'seed $seed');
      expect(
        Heuristics.lowerBound(board),
        greaterThanOrEqualTo(cfg.minSolutionDepth),
        reason: 'seed $seed',
      );
    }
  });

  test('6x6 / 800 shuffling averages below 50 ms', () {
    final watch = Stopwatch()..start();
    for (var seed = 0; seed < 30; seed++) {
      Shuffler(Seeded(seed))
          .shuffle(DifficultyConfig.base(DifficultyLevel.master));
    }
    watch.stop();
    expect(watch.elapsedMicroseconds / 30, lessThan(50000));
  });
}
