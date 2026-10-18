import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/theme/tokens.dart';
import '../../game/domain/entities/difficulty_level.dart';
import '../../game/domain/entities/player_stats.dart';
import '../application/leaderboard_providers.dart';

/// Leaderboard page with global stats header and tabs for each difficulty level.
class LeaderboardPage extends ConsumerStatefulWidget {
  const LeaderboardPage({super.key});

  @override
  ConsumerState<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends ConsumerState<LeaderboardPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: DifficultyLevel.values.length,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(playerStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Marcadores'),
        leading: Semantics(
          label: 'Volver',
          button: true,
          excludeSemantics: true,
          child: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.go(AppRoutes.menu),
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            for (final level in DifficultyLevel.values)
              Tab(text: level.displayName),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Stats Header
            Padding(
              padding: const EdgeInsets.all(AppTokens.spaceMedium),
              child: statsAsync.when(
                data: (stats) => _buildStatsHeader(context, stats),
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppTokens.spaceMedium),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (_, _) => const SizedBox.shrink(),
              ),
            ),
            const Divider(height: 1),

            // Tabs for each Difficulty Level
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  for (final level in DifficultyLevel.values)
                    _buildLeaderboardList(context, level),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsHeader(BuildContext context, PlayerStats stats) {
    final theme = Theme.of(context);
    final winPercentage = (stats.winRate * 100).toStringAsFixed(0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.spaceMedium,
          vertical: AppTokens.spaceSmall,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatCol('Partidas', '${stats.gamesPlayed}', theme),
            _buildStatCol(
              'Victorias',
              '${stats.wins} ($winPercentage%)',
              theme,
            ),
            _buildStatCol('Racha actual', '${stats.winStreak}', theme),
            _buildStatCol('Mejor racha', '${stats.bestWinStreak}', theme),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCol(String label, String value, ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboardList(BuildContext context, DifficultyLevel level) {
    final entriesAsync = ref.watch(leaderboardProvider(level));
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return entriesAsync.when(
      data: (entries) {
        if (entries.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.emoji_events_outlined,
                  size: 64,
                  color: colorScheme.outlineVariant,
                ),
                const SizedBox(height: AppTokens.spaceMedium),
                Text(
                  'No hay récords registrados todavía',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.spaceMedium,
            vertical: AppTokens.spaceSmall,
          ),
          itemCount: entries.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final entry = entries[index];
            final rank = entry.rank;
            final isTop3 = rank <= 3;

            return ListTile(
              leading: CircleAvatar(
                backgroundColor: isTop3
                    ? AppTheme.goldColor.withValues(alpha: 0.2)
                    : colorScheme.surfaceContainerHighest,
                foregroundColor: isTop3
                    ? AppTheme.goldColor
                    : colorScheme.onSurfaceVariant,
                child: Text(
                  '#$rank',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              title: Text(
                _formatDuration(entry.duration),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                '${entry.moves} movimientos • ${entry.playedAt.day.toString().padLeft(2, '0')}/${entry.playedAt.month.toString().padLeft(2, '0')}/${entry.playedAt.year}',
              ),
              trailing: isTop3
                  ? const Icon(Icons.star_rounded, color: AppTheme.goldColor)
                  : null,
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Text(
          'Error al cargar marcadores: $error',
          style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.error),
        ),
      ),
    );
  }
}
