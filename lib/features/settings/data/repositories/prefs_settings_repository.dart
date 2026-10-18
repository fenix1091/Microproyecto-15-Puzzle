import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/result.dart';
import '../../../game/domain/entities/difficulty_level.dart';
import '../../domain/entities/user_settings.dart';
import '../../domain/repositories/settings_repository.dart';

/// One SharedPreferences key per field, prefixed `settings.`.
class PrefsSettingsRepository implements SettingsRepository {
  const PrefsSettingsRepository(this._prefs);

  // ignore: unused_field
  final SharedPreferences _prefs;

  @override
  Future<Result<UserSettings>> load() async {
    try {
      AppThemeMode theme(String? key) =>
          AppThemeMode.values.where((v) => v.name == key).firstOrNull ??
          AppThemeMode.system;
      return Result.ok(
        UserSettings(
          themeMode: theme(_prefs.getString('settings.themeMode')),
          soundEnabled: _prefs.getBool('settings.soundEnabled') ?? true,
          vibrationEnabled: _prefs.getBool('settings.vibrationEnabled') ?? true,
          adaptiveDifficulty:
              _prefs.getBool('settings.adaptiveDifficulty') ?? true,
          manualLevel: DifficultyLevel.fromKey(
            _prefs.getString('settings.manualLevel') ?? 'easy',
          ),
          reduceMotion: _prefs.getBool('settings.reduceMotion') ?? false,
          currentLevel: DifficultyLevel.fromKey(
            _prefs.getString('settings.currentLevel') ?? 'easy',
          ),
        ),
      );
    } on Object catch (e) {
      return Result.err(StorageFailure('Unable to load settings: $e'));
    }
  }

  @override
  Future<Result<void>> save(UserSettings s) async {
    try {
      await _prefs.setString('settings.themeMode', s.themeMode.name);
      await _prefs.setBool('settings.soundEnabled', s.soundEnabled);
      await _prefs.setBool('settings.vibrationEnabled', s.vibrationEnabled);
      await _prefs.setBool('settings.adaptiveDifficulty', s.adaptiveDifficulty);
      await _prefs.setString('settings.manualLevel', s.manualLevel.key);
      await _prefs.setBool('settings.reduceMotion', s.reduceMotion);
      await _prefs.setString('settings.currentLevel', s.currentLevel.key);
      return const Result.ok(null);
    } on Object catch (e) {
      return Result.err(StorageFailure('Unable to save settings: $e'));
    }
  }
}
