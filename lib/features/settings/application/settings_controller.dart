import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities/user_settings.dart';

final settingsControllerProvider =
    AsyncNotifierProvider<SettingsController, UserSettings>(
      SettingsController.new,
    );

/// Loads settings via `loadSettingsProvider`, persists every change via
/// `updateSettingsProvider`, and reconfigures `feedbackServiceProvider`.
class SettingsController extends AsyncNotifier<UserSettings> {
  @override
  Future<UserSettings> build() {
    // TODO(backend): implement.
    throw UnimplementedError();
  }

  /// Applies [transform] optimistically, then persists the result.
  Future<void> change(UserSettings Function(UserSettings) transform) {
    // TODO(backend): implement.
    throw UnimplementedError();
  }
}
