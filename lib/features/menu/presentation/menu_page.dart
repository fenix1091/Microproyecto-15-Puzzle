import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/theme/tokens.dart';
import '../../../shared/widgets/animated_logo.dart';
import '../../game/domain/entities/difficulty_decision.dart';
import '../../game/domain/entities/difficulty_level.dart';
import '../../leaderboard/application/leaderboard_providers.dart';
import '../../settings/application/settings_controller.dart';

/// Main Menu Screen.
/// Provides buttons for Jugar, Marcadores, Configuración, and Instrucciones.
/// Displays current difficulty level and adaptive trend.
class MenuPage extends ConsumerWidget {
  const MenuPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final settings = ref.watch(settingsControllerProvider).asData?.value;
    final isAdaptive = settings?.adaptiveDifficulty ?? true;
    final effectiveLevel = isAdaptive
        ? (settings?.currentLevel ?? DifficultyLevel.easy)
        : (settings?.manualLevel ?? DifficultyLevel.easy);

    final nextDecisionAsync = isAdaptive
        ? ref.watch(nextDifficultyProvider(effectiveLevel))
        : null;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTokens.spaceMedium,
                vertical: AppTokens.spaceMedium,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                        const Center(
                          child: AnimatedLogo(size: 96, animate: false),
                        ),
                        const SizedBox(height: AppTokens.spaceMedium),
                        Text(
                          'Sliding Puzzle',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: AppTokens.spaceSmall),
                        Text(
                          'Rompecabezas clásico 15-puzzle',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: AppTokens.spaceLarge),

                        // Difficulty level card
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(
                              AppTokens.spaceMedium,
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        'Nivel actual',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.labelLarge
                                            ?.copyWith(
                                              color:
                                                  colorScheme.onSurfaceVariant,
                                            ),
                                      ),
                                    ),
                                    const SizedBox(width: AppTokens.spaceSmall),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isAdaptive
                                            ? colorScheme.primaryContainer
                                            : colorScheme.secondaryContainer,
                                        borderRadius: BorderRadius.circular(
                                          AppTokens.radiusSmall,
                                        ),
                                      ),
                                      child: Text(
                                        isAdaptive ? 'Adaptativo' : 'Manual',
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                              color: isAdaptive
                                                  ? colorScheme
                                                      .onPrimaryContainer
                                                  : colorScheme
                                                      .onSecondaryContainer,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppTokens.spaceSmall),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        effectiveLevel.displayName,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.titleLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: colorScheme.primary,
                                            ),
                                      ),
                                    ),
                                    if (isAdaptive && nextDecisionAsync != null)
                                      Flexible(
                                        child: nextDecisionAsync.maybeWhen(
                                          data: (decision) => _buildTrendBadge(
                                            context,
                                            decision.trend,
                                          ),
                                          orElse: () => const SizedBox.shrink(),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                  const SizedBox(height: AppTokens.spaceXLarge),

                  // Action buttons with QA-required exact labels
                  FilledButton.icon(
                    key: const Key('menu_play_button'),
                    onPressed: () => context.go(AppRoutes.game),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Jugar'),
                  ),
                  const SizedBox(height: AppTokens.spaceMedium),
                  OutlinedButton.icon(
                    key: const Key('menu_leaderboard_button'),
                    onPressed: () => context.go(AppRoutes.leaderboard),
                    icon: const Icon(Icons.leaderboard_outlined),
                    label: const Text('Marcadores'),
                  ),
                  const SizedBox(height: AppTokens.spaceMedium),
                  OutlinedButton.icon(
                    key: const Key('menu_settings_button'),
                    onPressed: () => context.go(AppRoutes.settings),
                    icon: const Icon(Icons.settings_outlined),
                    label: const Text('Configuración'),
                  ),
                  const SizedBox(height: AppTokens.spaceMedium),
                  OutlinedButton.icon(
                    key: const Key('menu_instructions_button'),
                    onPressed: () => context.go(AppRoutes.instructions),
                    icon: const Icon(Icons.help_outline_rounded),
                    label: const Text('Instrucciones'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrendBadge(BuildContext context, DifficultyTrend trend) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final (text, color, icon) = switch (trend) {
      DifficultyTrend.promoted => (
        '↑ En ascenso',
        Colors.green,
        Icons.trending_up,
      ),
      DifficultyTrend.demoted => (
        '↓ Ajustando',
        Colors.orange,
        Icons.trending_down,
      ),
      DifficultyTrend.unchanged => (
        'Estable',
        colorScheme.onSurfaceVariant,
        Icons.trending_flat,
      ),
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
