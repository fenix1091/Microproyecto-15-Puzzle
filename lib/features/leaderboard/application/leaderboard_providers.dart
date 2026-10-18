import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di/providers.dart';
import '../../game/domain/entities/difficulty_decision.dart';
import '../../game/domain/entities/difficulty_level.dart';
import '../../game/domain/entities/player_stats.dart';
import '../domain/entities/leaderboard_entry.dart';

// Read-only views; invalidate them after a game finishes.

final leaderboardProvider =
    FutureProvider.family<List<LeaderboardEntry>, DifficultyLevel>(
      (ref, level) async =>
          (await ref.watch(getLeaderboardProvider)(level))
              .fold((entries) => entries, (failure) => throw failure),
    );

final personalBestProvider =
    FutureProvider.family<LeaderboardEntry?, DifficultyLevel>(
      (ref, level) async =>
          (await ref.watch(getPersonalBestProvider)(level))
              .fold((entry) => entry, (failure) => throw failure),
    );

final playerStatsProvider = FutureProvider<PlayerStats>(
  (ref) async => (await ref.watch(
    getPlayerStatsProvider,
  )()).fold((stats) => stats, (failure) => throw failure),
);

final nextDifficultyProvider =
    FutureProvider.family<DifficultyDecision, DifficultyLevel>(
      (ref, current) async =>
          (await ref.watch(computeNextDifficultyProvider)(current))
              .fold((decision) => decision, (failure) => throw failure),
    );
