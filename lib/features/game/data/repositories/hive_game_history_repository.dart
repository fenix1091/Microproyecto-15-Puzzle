import 'package:hive_ce/hive.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/result.dart';
import '../../domain/entities/difficulty_level.dart';
import '../../domain/entities/game_result.dart';
import '../../domain/repositories/game_history_repository.dart';
import '../models/game_result_dto.dart';

/// Stores each [GameResult] as a plain map (see `GameResultDto`) in
/// [box]; no Hive adapters/codegen. Keep at most 500 entries.
class HiveGameHistoryRepository implements GameHistoryRepository {
  HiveGameHistoryRepository(this._box);

  static const boxName = 'game_history';

  // ignore: unused_field
  final Box<Map<dynamic, dynamic>> _box;

  @override
  Future<Result<void>> save(GameResult result) async {
    try {
      await _box.add(GameResultDto.toMap(result));
      while (_box.length > 500) {
        await _box.deleteAt(0);
      }
      return const Result.ok(null);
    } on Object catch (e) {
      return Result.err(StorageFailure('Unable to save game history: $e'));
    }
  }

  @override
  Future<Result<List<GameResult>>> getHistory({
    DifficultyLevel? level,
    int? limit,
  }) async {
    try {
      final records =
          _box.values
              .map(GameResultDto.fromMap)
              .whereType<GameResult>()
              .toList()
            ..sort((a, b) => b.playedAt.compareTo(a.playedAt));
      final filtered = records
          .where((r) => level == null || r.level == level)
          .toList();
      return Result.ok(
        limit == null ? filtered : filtered.take(limit).toList(),
      );
    } on Object catch (e) {
      return Result.err(StorageFailure('Unable to read game history: $e'));
    }
  }

  @override
  Future<Result<void>> clear() async {
    try {
      await _box.clear();
      return const Result.ok(null);
    } on Object catch (e) {
      return Result.err(StorageFailure('Unable to clear game history: $e'));
    }
  }
}
