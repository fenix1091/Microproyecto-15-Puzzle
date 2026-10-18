import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../app/theme/tokens.dart';
import '../../../../shared/widgets/stat_badge.dart';
import '../../../leaderboard/application/leaderboard_providers.dart';
import '../../../settings/application/settings_controller.dart';
import '../../domain/entities/difficulty_decision.dart';
import '../../domain/entities/game_result.dart';

/// Screen displayed after a game concludes (won, lost, or abandoned).
class ResultPage extends ConsumerWidget {
  const ResultPage({super.key, required this.result});

  final GameResult result;

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isWin = result.isWin;

    final personalBestAsync = ref.watch(personalBestProvider(result.level));

    final efficiency = result.minSolutionDepth > 0
        ? (result.moves / result.minSolutionDepth).toStringAsFixed(1)
        : '-';

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.spaceLarge,
              vertical: AppTokens.spaceMedium,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Outcome Header Icon & Title
                  Icon(
                    isWin
                        ? Icons.emoji_events_rounded
                        : Icons.sentiment_dissatisfied_rounded,
                    size: 80,
                    color: isWin ? AppTheme.goldColor : colorScheme.error,
                  ),
                  const SizedBox(height: AppTokens.spaceMedium),
                  Text(
                    isWin
                        ? '¡Victoria!'
                        : (result.outcome == GameOutcome.abandoned
                              ? 'Partida abandonada'
                              : 'Derrota'),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isWin ? colorScheme.primary : colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: AppTokens.spaceSmall),
                  Text(
                    'Nivel ${result.level.displayName} (${result.boardSize}×${result.boardSize})',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),

                  // "¡Nuevo récord!" Badge
                  if (result.isPersonalBest) ...[
                    const SizedBox(height: AppTokens.spaceMedium),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.goldColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(
                            AppTokens.radiusMedium,
                          ),
                          border: Border.all(
                            color: AppTheme.goldColor,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: AppTheme.goldColor,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '¡Nuevo récord!',
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: AppTheme.goldColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  // DifficultyDecision trend chip (MED-019)
                  if (ref
                          .watch(settingsControllerProvider)
                          .asData
                          ?.value
                          .adaptiveDifficulty ??
                      true)
                    ref
                        .watch(nextDifficultyProvider(result.level))
                        .maybeWhen(
                          data: (decision) {
                            if (decision.trend == DifficultyTrend.promoted) {
                              return Center(
                                child: Container(
                                  margin: const EdgeInsets.only(
                                    top: AppTokens.spaceSmall,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(
                                      AppTokens.radiusMedium,
                                    ),
                                    border: Border.all(
                                      color: Colors.green,
                                      width: 1.2,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.trending_up,
                                        size: 18,
                                        color: Colors.green,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '¡Subiste a ${decision.level.displayName}!',
                                        style: theme.textTheme.labelLarge
                                            ?.copyWith(
                                              color: Colors.green,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            } else if (decision.trend ==
                                DifficultyTrend.demoted) {
                              return Center(
                                child: Container(
                                  margin: const EdgeInsets.only(
                                    top: AppTokens.spaceSmall,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withValues(
                                      alpha: 0.15,
                                    ),
                                    borderRadius: BorderRadius.circular(
                                      AppTokens.radiusMedium,
                                    ),
                                    border: Border.all(
                                      color: Colors.orange,
                                      width: 1.2,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.trending_down,
                                        size: 18,
                                        color: Colors.orange,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Bajaste a ${decision.level.displayName}',
                                        style: theme.textTheme.labelLarge
                                            ?.copyWith(
                                              color: Colors.orange,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                          orElse: () => const SizedBox.shrink(),
                        ),

                  const SizedBox(height: AppTokens.spaceLarge),

                  // Metrics Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppTokens.spaceMedium),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: StatBadge(
                                  label: 'Tiempo',
                                  value: _formatDuration(result.duration),
                                  icon: Icons.timer_outlined,
                                  highlight: isWin,
                                ),
                              ),
                              const SizedBox(width: AppTokens.spaceSmall),
                              Expanded(
                                child: StatBadge(
                                  label: 'Movimientos',
                                  value: '${result.moves}',
                                  icon: Icons.touch_app_outlined,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppTokens.spaceSmall),
                          Row(
                            children: [
                              Expanded(
                                child: StatBadge(
                                  label: 'Eficiencia',
                                  value: '$efficiency×',
                                  icon: Icons.speed_rounded,
                                ),
                              ),
                              const SizedBox(width: AppTokens.spaceSmall),
                              Expanded(
                                child: personalBestAsync.maybeWhen(
                                  data: (best) => StatBadge(
                                    label: 'Mejor tiempo',
                                    value: best != null
                                        ? _formatDuration(best.duration)
                                        : '-',
                                    icon: Icons.military_tech_outlined,
                                  ),
                                  orElse: () => const StatBadge(
                                    label: 'Mejor tiempo',
                                    value: '-',
                                    icon: Icons.military_tech_outlined,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppTokens.spaceXLarge),

                  // Action buttons with QA labels
                  FilledButton.icon(
                    key: const Key('result_play_again_button'),
                    onPressed: () => context.go(AppRoutes.game),
                    icon: const Icon(Icons.replay_rounded),
                    label: const Text('Jugar de nuevo'),
                  ),
                  const SizedBox(height: AppTokens.spaceMedium),
                  OutlinedButton.icon(
                    key: const Key('result_menu_button'),
                    onPressed: () => context.go(AppRoutes.menu),
                    icon: const Icon(Icons.home_rounded),
                    label: const Text('Menú'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
