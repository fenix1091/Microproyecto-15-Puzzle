import '../../../../core/result.dart';
import '../entities/user_settings.dart';
import '../repositories/settings_repository.dart';

class LoadSettings {
  const LoadSettings(this._repository);

  final SettingsRepository _repository;

  Future<Result<UserSettings>> call() => _repository.load();
}

class UpdateSettings {
  const UpdateSettings(this._repository);

  final SettingsRepository _repository;

  Future<Result<void>> call(UserSettings settings) =>
      _repository.save(settings);
}
