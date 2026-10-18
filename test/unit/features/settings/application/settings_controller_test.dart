import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sliding_puzzle/app/di/providers.dart';
import 'package:sliding_puzzle/core/errors/failure.dart';
import 'package:sliding_puzzle/core/result.dart';
import 'package:sliding_puzzle/core/services/feedback_service.dart';
import 'package:sliding_puzzle/features/settings/application/settings_controller.dart';
import 'package:sliding_puzzle/features/settings/domain/entities/user_settings.dart';
import 'package:sliding_puzzle/features/settings/domain/repositories/settings_repository.dart';

class MemorySettings implements SettingsRepository {
  MemorySettings(this.value);
  UserSettings value;
  int writes = 0;
  Failure? saveFailure;
  @override
  Future<Result<UserSettings>> load() async => Result.ok(value);
  @override
  Future<Result<void>> save(UserSettings settings) async {
    writes++;
    if (saveFailure case final failure?) return Result.err(failure);
    value = settings;
    return const Result.ok(null);
  }
}

class RecordingFeedback implements FeedbackService {
  final configured = <(bool, bool)>[];
  @override
  void configure({required bool sound, required bool vibration}) =>
      configured.add((sound, vibration));
  @override
  void gameLost() {}
  @override
  void gameWon() {}
  @override
  void invalidMove() {}
  @override
  Future<void> preload() async {}
  @override
  void tileMoved() {}
}

void main() {
  test('loads settings and change persists optimistically and reconfigures feedback', () async {
    const initial = UserSettings();
    final repository = MemorySettings(initial);
    final feedback = RecordingFeedback();
    final container = ProviderContainer(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(repository),
        feedbackServiceProvider.overrideWithValue(feedback),
      ],
    );
    addTearDown(container.dispose);

    final loaded = await container.read(settingsControllerProvider.future);
    expect(loaded, initial);
    expect(feedback.configured, [(true, true)]);
    await container
        .read(settingsControllerProvider.notifier)
        .change(
          (settings) =>
              settings.copyWith(soundEnabled: false, vibrationEnabled: false),
        );
    expect(
      container.read(settingsControllerProvider).requireValue.soundEnabled,
      isFalse,
    );
    expect(repository.value.vibrationEnabled, isFalse);
    expect(repository.writes, 1);
    expect(feedback.configured.last, (false, false));
  });
  test(
    'keeps optimistic AsyncData and exposes failure when persistence fails',
    () async {
      final repository = MemorySettings(const UserSettings());
      repository.saveFailure = const StorageFailure('settings unavailable');
      final container = ProviderContainer(
        overrides: [settingsRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      await container.read(settingsControllerProvider.future);
      final notifier = container.read(settingsControllerProvider.notifier);
      await notifier.change(
        (settings) => settings.copyWith(soundEnabled: false),
      );
      expect(
        container.read(settingsControllerProvider).requireValue.soundEnabled,
        isFalse,
      );
      expect(notifier.lastFailure, isA<StorageFailure>());
    },
  );
}
