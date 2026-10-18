import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sliding_puzzle/app/di/providers.dart';
import 'package:sliding_puzzle/core/services/feedback_service.dart';
import 'package:sliding_puzzle/features/game/application/game_controller.dart';
import 'package:sliding_puzzle/features/game/application/game_state.dart';
import 'package:sliding_puzzle/features/game/domain/entities/board.dart';
import 'package:sliding_puzzle/features/game/domain/entities/difficulty_config.dart';
import 'package:sliding_puzzle/features/game/domain/entities/difficulty_level.dart';
import 'package:sliding_puzzle/features/game/domain/entities/game_session.dart';
import 'package:sliding_puzzle/features/settings/application/settings_controller.dart';
import 'package:sliding_puzzle/features/settings/domain/entities/user_settings.dart';

class FakeGameController extends GameController {
  FakeGameController({this.initialState});

  final GameState? initialState;
  final List<int> tappedIndices = [];
  bool startCalled = false;
  bool pauseCalled = false;
  bool resumeCalled = false;
  bool restartCalled = false;
  bool abandonCalled = false;

  @override
  GameState build() {
    if (initialState != null) return initialState!;
    final board = Board(
      size: 3,
      // 3x3 board where 0 is at index 7 (row 2, col 1):
      // [1, 2, 3]
      // [4, 5, 6]
      // [7, 0, 8]
      tiles: const [1, 2, 3, 4, 5, 6, 7, 0, 8],
    );
    return GameState(
      session: GameSession(
        initialBoard: board,
        board: board,
        config: DifficultyConfig.base(DifficultyLevel.easy),
        moves: 5,
        elapsed: const Duration(seconds: 42),
        status: GameStatus.playing,
      ),
    );
  }

  @override
  Future<void> start({DifficultyLevel? level}) async {
    startCalled = true;
  }

  @override
  void tap(int index) {
    tappedIndices.add(index);
  }

  @override
  void pause() {
    pauseCalled = true;
    if (state.session != null) {
      state = state.copyWith(
        session: state.session!.copyWith(status: GameStatus.paused),
      );
    }
  }

  @override
  void resume() {
    resumeCalled = true;
    if (state.session != null) {
      state = state.copyWith(
        session: state.session!.copyWith(status: GameStatus.playing),
      );
    }
  }

  @override
  void restart() {
    restartCalled = true;
    if (state.session != null) {
      state = state.copyWith(
        session: state.session!.copyWith(
          moves: 0,
          elapsed: Duration.zero,
          status: GameStatus.ready,
        ),
      );
    }
  }

  @override
  Future<void> abandon() async {
    abandonCalled = true;
  }
}

class FakeSettingsController extends SettingsController {
  FakeSettingsController({UserSettings? initial})
      : _current = initial ?? const UserSettings();

  UserSettings _current;
  final List<UserSettings Function(UserSettings)> changeCalls = [];

  @override
  Future<UserSettings> build() async => _current;

  @override
  Future<void> change(UserSettings Function(UserSettings) transform) async {
    changeCalls.add(transform);
    _current = transform(_current);
    state = AsyncData(_current);
  }
}

/// Helper to wrap widgets with standard provider overrides and theme.
Widget createTestApp({
  required Widget child,
  List<dynamic> overrides = const [],
  UserSettings? settings,
}) {
  final hasSettingsOverride = overrides.any(
    (o) => o.toString().contains('SettingsController'),
  );

  return ProviderScope(
    overrides: [
      feedbackServiceProvider.overrideWithValue(const NoopFeedbackService()),
      if (!hasSettingsOverride)
        settingsControllerProvider.overrideWith(
          () => FakeSettingsController(initial: settings),
        ),
      ...overrides.cast(),
    ],
    child: MaterialApp(
      home: child,
    ),
  );
}
