import 'package:hive_ce/hive.dart';

import '../../../../core/result.dart';
import '../../domain/entities/difficulty_level.dart';
import '../../domain/entities/game_result.dart';
import '../../domain/repositories/game_history_repository.dart';

/// Stores each [GameResult] as a plain map (see `GameResultDto`) in
/// [box]; no Hive adapters/codegen. Keep at most 500 entries.
class HiveGameHistoryRepository implements GameHistoryRepository {
  HiveGameHistoryRepository(this._box);

  static const boxName = 'game_history';

  // ignore: unused_field
  final Box<Map<dynamic, dynamic>> _box;

  @override
  Future<Result<void>> save(GameResult result) {
    // TODO(backend): implement.
    throw UnimplementedError();
  }

  @override
  Future<Result<List<GameResult>>> getHistory({
    DifficultyLevel? level,
    int? limit,
  }) {
    // TODO(backend): implement.
    throw UnimplementedError();
  }

  @override
  Future<Result<void>> clear() {
    // TODO(backend): implement.
    throw UnimplementedError();
  }
}
