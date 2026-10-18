import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/theme/tokens.dart';
import '../../game/domain/entities/difficulty_level.dart';
import '../application/settings_controller.dart';
import '../domain/entities/user_settings.dart';

/// Settings screen for audio, vibrations, theme, adaptive difficulty, and motion.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final settingsAsync = ref.watch(settingsControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
        leading: Semantics(
          label: 'Volver',
          button: true,
          excludeSemantics: true,
          child: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.go(AppRoutes.menu),
          ),
        ),
      ),
      body: SafeArea(
        child: settingsAsync.when(
          data: (settings) => _buildSettingsList(context, ref, settings),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Text(
              'Error al cargar configuración: $error',
              style: TextStyle(color: colorScheme.error),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsList(
    BuildContext context,
    WidgetRef ref,
    UserSettings settings,
  ) {
    final theme = Theme.of(context);
    final notifier = ref.read(settingsControllerProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.spaceMedium,
        vertical: AppTokens.spaceSmall,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Theme Section
              _buildSectionHeader(context, 'Apariencia'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppTokens.spaceMedium),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tema visual',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppTokens.spaceSmall),
                      SegmentedButton<AppThemeMode>(
                        segments: const [
                          ButtonSegment(
                            value: AppThemeMode.system,
                            label: Text('Sistema'),
                            icon: Icon(Icons.brightness_auto_rounded),
                          ),
                          ButtonSegment(
                            value: AppThemeMode.light,
                            label: Text('Claro'),
                            icon: Icon(Icons.light_mode_rounded),
                          ),
                          ButtonSegment(
                            value: AppThemeMode.dark,
                            label: Text('Oscuro'),
                            icon: Icon(Icons.dark_mode_rounded),
                          ),
                        ],
                        selected: {settings.themeMode},
                        onSelectionChanged: (selection) {
                          notifier.change(
                            (s) => s.copyWith(themeMode: selection.first),
                          );
                        },
                      ),
                      const SizedBox(height: AppTokens.spaceMedium),
                      SwitchListTile(
                        title: const Text('Reducir animaciones'),
                        subtitle: const Text(
                          'Desactiva o acorta los efectos de movimiento y sacudidas',
                        ),
                        value: settings.reduceMotion,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (val) {
                          notifier.change((s) => s.copyWith(reduceMotion: val));
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppTokens.spaceMedium),

              // Audio & Feedback
              _buildSectionHeader(context, 'Audio y vibración'),
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Sonido'),
                      subtitle: const Text(
                        'Efectos de sonido al deslizar y terminar',
                      ),
                      secondary: const Icon(Icons.volume_up_rounded),
                      value: settings.soundEnabled,
                      onChanged: (val) {
                        notifier.change((s) => s.copyWith(soundEnabled: val));
                      },
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text('Vibración'),
                      subtitle: const Text('Retroalimentación háptica táctil'),
                      secondary: const Icon(Icons.vibration_rounded),
                      value: settings.vibrationEnabled,
                      onChanged: (val) {
                        notifier.change(
                          (s) => s.copyWith(vibrationEnabled: val),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppTokens.spaceMedium),

              // Difficulty
              _buildSectionHeader(context, 'Dificultad'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTokens.spaceMedium,
                    vertical: AppTokens.spaceSmall,
                  ),
                  child: Column(
                    children: [
                      Semantics(
                        container: true,
                        child: SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Dificultad adaptativa'),
                          subtitle: const Text(
                            'Ajusta el nivel automáticamente según tu rendimiento reciente',
                          ),
                          value: settings.adaptiveDifficulty,
                          onChanged: (val) {
                            notifier.change(
                              (s) => s.copyWith(adaptiveDifficulty: val),
                            );
                          },
                        ),
                      ),
                      const Divider(height: 1),
                      const SizedBox(height: AppTokens.spaceSmall),
                      Semantics(
                        container: true,
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          enabled: !settings.adaptiveDifficulty,
                          title: const Text('Nivel manual'),
                          subtitle: Text(
                            settings.adaptiveDifficulty
                                ? 'Desactiva la dificultad adaptativa para elegir manualmente'
                                : 'Selecciona el nivel fijo que deseas jugar',
                          ),
                          trailing: DropdownButton<DifficultyLevel>(
                            value: settings.manualLevel,
                            onChanged: settings.adaptiveDifficulty
                                ? null
                                : (level) {
                                    if (level != null) {
                                      notifier.change(
                                        (s) => s.copyWith(manualLevel: level),
                                      );
                                    }
                                  },
                            items: [
                              for (final level in DifficultyLevel.values)
                                DropdownMenuItem(
                                  value: level,
                                  child: Text(level.displayName),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppTokens.spaceSmall,
        bottom: AppTokens.spaceSmall,
      ),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
