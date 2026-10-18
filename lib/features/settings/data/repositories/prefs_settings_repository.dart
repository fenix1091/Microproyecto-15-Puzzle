import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/result.dart';
import '../../domain/entities/user_settings.dart';
import '../../domain/repositories/settings_repository.dart';

/// One SharedPreferences key per field, prefixed `settings.`.
class PrefsSettingsRepository implements SettingsRepository {
  const PrefsSettingsRepository(this._prefs);

  // ignore: unused_field
  final SharedPreferences _prefs;

  @override
  Future<Result<UserSettings>> load() {
    // TODO(backend): implement.
    throw UnimplementedError();
  }

  @override
  Future<Result<void>> save(UserSettings settings) {
    // TODO(backend): implement.
    throw UnimplementedError();
  }
}
