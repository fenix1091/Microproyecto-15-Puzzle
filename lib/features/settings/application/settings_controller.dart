import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di/providers.dart';
import '../domain/entities/user_settings.dart';

final settingsControllerProvider =
    AsyncNotifierProvider<SettingsController, UserSettings>(
      SettingsController.new,
    );

/// Loads settings via `loadSettingsProvider`, persists every change via
/// `updateSettingsProvider`, and reconfigures `feedbackServiceProvider`.
class SettingsController extends AsyncNotifier<UserSettings> {
  @override
  Future<UserSettings> build() async {
    final loaded = await ref.watch(loadSettingsProvider)();
    return loaded.fold((settings) {
      ref
          .read(feedbackServiceProvider)
          .configure(
            sound: settings.soundEnabled,
            vibration: settings.vibrationEnabled,
          );
      return settings;
    }, (failure) => throw failure);
  }

  /// Applies [transform] optimistically, then persists the result.
  Future<void> change(UserSettings Function(UserSettings) transform) async {
    final old = state is AsyncData<UserSettings>
        ? (state as AsyncData<UserSettings>).value
        : null;
    if (old == null) return;
    final next = transform(old);
    state = AsyncData(next);
    ref
        .read(feedbackServiceProvider)
        .configure(sound: next.soundEnabled, vibration: next.vibrationEnabled);
    final saved = await ref.read(updateSettingsProvider)(next);
    saved.fold((_) {}, (failure) {
      state = AsyncError(failure, StackTrace.current);
    });
  }
}
