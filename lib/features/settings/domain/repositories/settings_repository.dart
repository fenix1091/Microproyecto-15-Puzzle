import '../../../../core/result.dart';
import '../entities/user_settings.dart';

abstract interface class SettingsRepository {
  /// Returns defaults when nothing is stored yet.
  Future<Result<UserSettings>> load();

  Future<Result<void>> save(UserSettings settings);
}
