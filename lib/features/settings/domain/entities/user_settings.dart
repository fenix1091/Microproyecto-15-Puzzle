import 'package:equatable/equatable.dart';

import '../../../game/domain/entities/difficulty_level.dart';

enum AppThemeMode { system, light, dark }

class UserSettings extends Equatable {
  const UserSettings({
    this.themeMode = AppThemeMode.system,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.adaptiveDifficulty = true,
    this.manualLevel = DifficultyLevel.easy,
    this.reduceMotion = false,
    this.currentLevel = DifficultyLevel.easy,
  });

  final AppThemeMode themeMode;
  final bool soundEnabled;
  final bool vibrationEnabled;

  /// When true the next level comes from `ComputeNextDifficulty`;
  /// otherwise [manualLevel] is used.
  final bool adaptiveDifficulty;
  final DifficultyLevel manualLevel;

  /// Shortens/disables animations (also honoured from the OS setting).
  final bool reduceMotion;

  /// Level reached by the adaptive engine, persisted between sessions.
  final DifficultyLevel currentLevel;

  UserSettings copyWith({
    AppThemeMode? themeMode,
    bool? soundEnabled,
    bool? vibrationEnabled,
    bool? adaptiveDifficulty,
    DifficultyLevel? manualLevel,
    bool? reduceMotion,
    DifficultyLevel? currentLevel,
  }) => UserSettings(
    themeMode: themeMode ?? this.themeMode,
    soundEnabled: soundEnabled ?? this.soundEnabled,
    vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
    adaptiveDifficulty: adaptiveDifficulty ?? this.adaptiveDifficulty,
    manualLevel: manualLevel ?? this.manualLevel,
    reduceMotion: reduceMotion ?? this.reduceMotion,
    currentLevel: currentLevel ?? this.currentLevel,
  );

  @override
  List<Object?> get props => [
    themeMode,
    soundEnabled,
    vibrationEnabled,
    adaptiveDifficulty,
    manualLevel,
    reduceMotion,
    currentLevel,
  ];
}
