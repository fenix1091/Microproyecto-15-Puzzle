import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:sliding_puzzle/features/game/data/repositories/hive_game_history_repository.dart';
import 'package:sliding_puzzle/features/game/domain/entities/difficulty_level.dart';
import 'package:sliding_puzzle/features/game/domain/entities/game_result.dart';
import 'package:sliding_puzzle/features/leaderboard/data/repositories/history_leaderboard_repository.dart';

void main() {
  late Directory dir;
  late Box<Map<dynamic, dynamic>> box;
  late HiveGameHistoryRepository history;
  setUp(() async {
    dir = await Directory.systemTemp.createTemp('puzzle-hive-');
    Hive.init(dir.path);
    box = await Hive.openBox<Map<dynamic, dynamic>>('history-test');
    history = HiveGameHistoryRepository(box);
  });
  tearDown(() async {
    await box.close();
    await Hive.deleteFromDisk();
    await dir.delete(recursive: true);
  });
  GameResult game(
    int moves,
    int seconds, {
    GameOutcome outcome = GameOutcome.won,
  }) => GameResult(
    level: DifficultyLevel.easy,
    boardSize: 3,
    moves: moves,
    duration: Duration(seconds: seconds),
    outcome: outcome,
    minSolutionDepth: 10,
    playedAt: DateTime.utc(2026, 1, 1).add(Duration(seconds: seconds)),
    timeLimit: const Duration(minutes: 5),
  );
  test('history saves newest first, filters and clears', () async {
    await history.save(game(4, 10));
    await history.save(game(3, 20));
    final all = (await history.getHistory()).valueOrNull!;
    expect(all.first.moves, 3);
    expect((await history.getHistory(limit: 1)).valueOrNull, hasLength(1));
    expect(
      (await history.getHistory(level: DifficultyLevel.master)).valueOrNull,
      isEmpty,
    );
    await history.clear();
    expect((await history.getHistory()).valueOrNull, isEmpty);
  });
  test(
    'leaderboard orders results and marks strict personal records',
    () async {
      final repo = HistoryLeaderboardRepository(history);
      await history.save(game(8, 20));
      final first = game(7, 10);
      expect((await repo.submit(first)).valueOrNull, true);
      await history.save(first);
      expect((await repo.submit(game(8, 20))).valueOrNull, false);
      final top = (await repo.getTop(DifficultyLevel.easy)).valueOrNull!;
      expect(top.first.moves, 7);
      expect(top.first.rank, 1);
      expect(
        (await repo.getPersonalBest(DifficultyLevel.easy)).valueOrNull!.moves,
        7,
      );
    },
  );
}
