import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di/providers.dart';
import '../../../core/errors/failure.dart';
import '../../leaderboard/application/leaderboard_providers.dart';
import '../../settings/application/settings_controller.dart';
import '../../settings/domain/entities/user_settings.dart';
import '../domain/entities/difficulty_level.dart';
import '../domain/entities/game_result.dart';
import '../domain/entities/game_session.dart';
import '../domain/services/heuristics.dart';
import 'game_state.dart';

final gameControllerProvider = NotifierProvider<GameController, GameState>(
  GameController.new,
);

/// Drives one game: generation, moves, 1 s ticking timer, pause, finish.
///
/// - The timer runs only while the session is `playing` (starts on the first
///   valid move) and is cancelled on pause/finish/dispose.
/// - Emits feedback via `feedbackServiceProvider` (move/invalid/win/lose).
/// - On win/loss/abandon calls `FinishGame`, stores [GameState.result], and
///   when adaptive difficulty is on, persists the new current level through
///   `settingsControllerProvider`.
class GameController extends Notifier<GameState> {
  Timer? _timer;
  DateTime? _lastTick;
  bool _levelWasExplicit = false;

  @override
  GameState build() {
    ref.onDispose(_cancelTimer);
    return const GameState();
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
    _lastTick = null;
  }

  void _startTimer() {
    if (_timer != null) return;
    _lastTick = ref.read(clockProvider).now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final now = ref.read(clockProvider).now();
      final previous = _lastTick ?? now;
      _lastTick = now;
      final session = state.session;
      if (session == null || session.status != GameStatus.playing) {
        _cancelTimer();
        return;
      }
      final next = ref.read(tickGameProvider)(
        session,
        now.difference(previous),
      );
      state = state.copyWith(session: next);
      if (next.status == GameStatus.lost) {
        _cancelTimer();
        ref.read(feedbackServiceProvider).gameLost();
        _finish(GameOutcome.lost);
      }
    });
  }

  Future<void> _finish(GameOutcome outcome) async {
    _cancelTimer();
    final session = state.session;
    if (session == null) return;
    final result = await ref.read(finishGameProvider)(session, outcome);
    result.fold(
      (value) {
        state = state.copyWith(result: value, clearFailure: true);
        ref.invalidate(leaderboardProvider(value.level));
        ref.invalidate(personalBestProvider(value.level));
        ref.invalidate(playerStatsProvider);
        ref.invalidate(nextDifficultyProvider(value.level));
        final settings = ref.read(settingsControllerProvider).value;
        if (!_levelWasExplicit && (settings?.adaptiveDifficulty ?? false)) {
          ref
              .read(settingsControllerProvider.notifier)
              .change(
                (s) => s.copyWith(
                  currentLevel: state.decision?.level ?? s.currentLevel,
                ),
              );
        }
      },
      (failure) {
        ref.invalidate(leaderboardProvider(session.config.level));
        ref.invalidate(personalBestProvider(session.config.level));
        ref.invalidate(playerStatsProvider);
        ref.invalidate(nextDifficultyProvider(session.config.level));
        final fallback = GameResult(
          level: session.config.level,
          boardSize: session.config.boardSize,
          moves: session.moves,
          duration: session.elapsed,
          outcome: outcome,
          minSolutionDepth: Heuristics.lowerBound(session.initialBoard),
          playedAt: ref.read(clockProvider).now(),
          timeLimit: session.config.timeLimit,
        );
        state = state.copyWith(result: fallback, failure: failure);
      },
    );
  }

  /// Generates a new game. [level] forces a manual level; otherwise settings
  /// decide (adaptive engine or `manualLevel`).
  Future<void> start({DifficultyLevel? level}) async {
    state = const GameState(isStarting: true);
    _levelWasExplicit = level != null;
    final settings =
        ref.read(settingsControllerProvider).value ?? const UserSettings();
    final current = settings.adaptiveDifficulty
        ? settings.currentLevel
        : settings.manualLevel;
    final setup = await ref.read(startGameProvider)(
      currentLevel: current,
      manualLevel:
          level ?? (settings.adaptiveDifficulty ? null : settings.manualLevel),
    );
    setup.fold(
      (value) {
        state = GameState(session: value.session, decision: value.decision);
      },
      (failure) {
        state = GameState(failure: failure);
      },
    );
  }

  void tap(int index) {
    final session = state.session;
    if (session == null || session.isFinished) return;
    final moved = ref.read(moveTileProvider)(session, index);
    moved.fold(
      (next) {
        state = state.copyWith(session: next, clearInvalidTap: true);
        ref.read(feedbackServiceProvider).tileMoved();
        if (next.status == GameStatus.playing) _startTimer();
        if (next.status == GameStatus.won) {
          _cancelTimer();
          ref.read(feedbackServiceProvider).gameWon();
          _finish(GameOutcome.won);
        }
      },
      (failure) {
        if (failure is InvalidMoveFailure) {
          state = state.copyWith(
            invalidTapIndex: index,
            invalidTapCount: state.invalidTapCount + 1,
          );
          ref.read(feedbackServiceProvider).invalidMove();
        } else {
          state = state.copyWith(failure: failure);
        }
      },
    );
  }

  void pause() {
    final session = state.session;
    if (session == null) return;
    _cancelTimer();
    ref
        .read(pauseGameProvider)(session)
        .fold(
          (s) => state = state.copyWith(session: s),
          (f) => state = state.copyWith(failure: f),
        );
  }

  void resume() {
    final session = state.session;
    if (session == null) return;
    ref.read(resumeGameProvider)(session).fold((s) {
      state = state.copyWith(session: s);
      _startTimer();
    }, (f) => state = state.copyWith(failure: f));
  }

  void restart() {
    final session = state.session;
    if (session == null) return;
    _cancelTimer();
    state = state.copyWith(
      session: ref.read(restartGameProvider)(session),
      clearResult: true,
      clearFailure: true,
    );
  }

  /// Leaving mid-game records the game as abandoned (counts as a loss).
  /// Does nothing if no move was made yet.
  Future<void> abandon() async {
    final session = state.session;
    if (session == null || session.moves == 0 || session.isFinished) return;
    await _finish(GameOutcome.abandoned);
  }
}
