import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sliding_puzzle/features/game/domain/entities/difficulty_level.dart';
import 'package:sliding_puzzle/features/settings/data/repositories/prefs_settings_repository.dart';

void main() {
  test('settings defaults then persists all fields using prefix', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repo = PrefsSettingsRepository(prefs);
    final defaults = (await repo.load()).valueOrNull!;
    expect(defaults.manualLevel, DifficultyLevel.easy);
    expect(defaults.soundEnabled, isTrue);
    final settings = defaults.copyWith(
      manualLevel: DifficultyLevel.expert,
      currentLevel: DifficultyLevel.hard,
      soundEnabled: false,
    );
    await repo.save(settings);
    expect((await repo.load()).valueOrNull, settings);
    expect(prefs.getString('settings.currentLevel'), 'hard');
  });
}
