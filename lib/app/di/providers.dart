import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_env.dart';
import '../../core/services/feedback_service.dart';
import '../../core/utils/clock.dart';
import '../../core/utils/random_source.dart';
import '../../features/game/data/repositories/hive_game_history_repository.dart';
import '../../features/game/domain/repositories/game_history_repository.dart';
import '../../features/game/domain/services/difficulty_engine.dart';
import '../../features/game/domain/services/shuffler.dart';
import '../../features/game/domain/usecases/finish_game.dart';
import '../../features/game/domain/usecases/game_actions.dart';
import '../../features/game/domain/usecases/start_game.dart';
import '../../features/game/domain/usecases/stats_usecases.dart';
import '../../features/leaderboard/data/repositories/history_leaderboard_repository.dart';
import '../../features/leaderboard/domain/repositories/leaderboard_repository.dart';
import '../../features/leaderboard/domain/usecases/get_leaderboard.dart';
import '../../features/settings/data/repositories/prefs_settings_repository.dart';
import '../../features/settings/domain/repositories/settings_repository.dart';
import '../../features/settings/domain/usecases/settings_usecases.dart';
import 'bootstrap.dart';

// Composition root. Tests replace any of these with
// `ProviderScope(overrides: [...])`.

// --- Infrastructure -------------------------------------------------------

/// Opens Hive + SharedPreferences. The splash screen awaits it; everything
/// that reads storage must only be used after it completes.
final appDependenciesProvider = FutureProvider<AppDependencies>(
  (ref) => bootstrapDependencies(),
);

final clockProvider = Provider<Clock>((ref) => const SystemClock());

final randomSourceProvider = Provider<RandomSource>(
  (ref) => DartRandomSource(AppEnv.qaSeed >= 0 ? AppEnv.qaSeed : null),
);

/// Overridden in `main.dart` with the audio/haptics implementation.
final feedbackServiceProvider = Provider<FeedbackService>(
  (ref) => const NoopFeedbackService(),
);

// --- Repositories ---------------------------------------------------------

final gameHistoryRepositoryProvider = Provider<GameHistoryRepository>(
  (ref) => HiveGameHistoryRepository(
    ref.watch(appDependenciesProvider).requireValue.historyBox,
  ),
);

final leaderboardRepositoryProvider = Provider<LeaderboardRepository>(
  (ref) =>
      HistoryLeaderboardRepository(ref.watch(gameHistoryRepositoryProvider)),
);

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => PrefsSettingsRepository(
    ref.watch(appDependenciesProvider).requireValue.prefs,
  ),
);

// --- Domain services ------------------------------------------------------

final difficultyEngineProvider = Provider<DifficultyEngine>(
  (ref) => const DifficultyEngine(),
);

final shufflerProvider = Provider<Shuffler>(
  (ref) => Shuffler(ref.watch(randomSourceProvider)),
);

// --- Use cases ------------------------------------------------------------

final startGameProvider = Provider<StartGame>(
  (ref) => StartGame(
    engine: ref.watch(difficultyEngineProvider),
    shuffler: ref.watch(shufflerProvider),
    history: ref.watch(gameHistoryRepositoryProvider),
  ),
);

final moveTileProvider = Provider<MoveTile>((ref) => const MoveTile());
final tickGameProvider = Provider<TickGame>((ref) => const TickGame());
final pauseGameProvider = Provider<PauseGame>((ref) => const PauseGame());
final resumeGameProvider = Provider<ResumeGame>((ref) => const ResumeGame());
final restartGameProvider = Provider<RestartGame>((ref) => const RestartGame());

final finishGameProvider = Provider<FinishGame>(
  (ref) => FinishGame(
    history: ref.watch(gameHistoryRepositoryProvider),
    leaderboard: ref.watch(leaderboardRepositoryProvider),
    clock: ref.watch(clockProvider),
  ),
);

final computeNextDifficultyProvider = Provider<ComputeNextDifficulty>(
  (ref) => ComputeNextDifficulty(
    engine: ref.watch(difficultyEngineProvider),
    history: ref.watch(gameHistoryRepositoryProvider),
  ),
);

final getPlayerStatsProvider = Provider<GetPlayerStats>(
  (ref) => GetPlayerStats(ref.watch(gameHistoryRepositoryProvider)),
);

final getLeaderboardProvider = Provider<GetLeaderboard>(
  (ref) => GetLeaderboard(ref.watch(leaderboardRepositoryProvider)),
);

final getPersonalBestProvider = Provider<GetPersonalBest>(
  (ref) => GetPersonalBest(ref.watch(leaderboardRepositoryProvider)),
);

final loadSettingsProvider = Provider<LoadSettings>(
  (ref) => LoadSettings(ref.watch(settingsRepositoryProvider)),
);

final updateSettingsProvider = Provider<UpdateSettings>(
  (ref) => UpdateSettings(ref.watch(settingsRepositoryProvider)),
);
