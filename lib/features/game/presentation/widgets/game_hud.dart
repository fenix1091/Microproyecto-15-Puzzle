import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../app/theme/tokens.dart';
import '../../domain/entities/game_session.dart';

/// HUD displaying timer, move count, difficulty level, and game controls.
class GameHud extends StatefulWidget {
  const GameHud({
    super.key,
    required this.session,
    required this.onPause,
    required this.onRestart,
    required this.onExit,
    this.isLandscape = false,
    this.reduceMotion = false,
  });

  final GameSession session;
  final VoidCallback onPause;
  final VoidCallback onRestart;
  final VoidCallback onExit;
  final bool isLandscape;
  final bool reduceMotion;

  @override
  State<GameHud> createState() => _GameHudState();
}

class _GameHudState extends State<GameHud> with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: AppTokens.pulseDuration,
    );
    _checkUrgent();
  }

  @override
  void didUpdateWidget(covariant GameHud oldWidget) {
    super.didUpdateWidget(oldWidget);
    _checkUrgent();
  }

  void _checkUrgent() {
    final hasLimit = widget.session.config.timeLimit != null;
    final timeDuration = hasLimit
        ? (widget.session.remaining ?? Duration.zero)
        : widget.session.elapsed;
    final isUrgent =
        hasLimit && timeDuration.inSeconds <= 10 && timeDuration.inSeconds > 0;

    if (isUrgent && !widget.reduceMotion) {
      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
    } else {
      if (_pulseController.isAnimating) {
        _pulseController.stop();
        _pulseController.value = 0.0;
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final session = widget.session;

    // Remaining time if countdown; otherwise elapsed
    final hasLimit = session.config.timeLimit != null;
    final timeDuration = hasLimit
        ? (session.remaining ?? Duration.zero)
        : session.elapsed;
    final formattedTime = _formatDuration(timeDuration);

    final isUrgent =
        hasLimit && timeDuration.inSeconds <= 10 && timeDuration.inSeconds > 0;

    final levelName = session.config.level.displayName;
    final boardDimension = '${session.board.size}×${session.board.size}';

    // HUD Semantics as specified: "Tiempo {mm:ss}", "Movimientos {n}", "Nivel {nombre}"
    final hudCards = [
      // Level
      Expanded(
        child: Semantics(
          label: 'Nivel $levelName',
          excludeSemantics: true,
          child: _HudItemCard(
            title: 'Nivel',
            value: levelName,
            subtitle: boardDimension,
            icon: Icons.grid_view_rounded,
          ),
        ),
      ),
      const SizedBox(width: AppTokens.spaceSmall),
      // Moves
      Expanded(
        child: Semantics(
          label: 'Movimientos ${session.moves}',
          excludeSemantics: true,
          child: _HudItemCard(
            title: 'Movimientos',
            value: '${session.moves}',
            icon: Icons.touch_app_outlined,
          ),
        ),
      ),
      const SizedBox(width: AppTokens.spaceSmall),
      // Timer
      Expanded(
        child: Semantics(
          label: 'Tiempo $formattedTime',
          excludeSemantics: true,
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final color = isUrgent && !widget.reduceMotion
                  ? Color.lerp(
                      colorScheme.error,
                      colorScheme.errorContainer,
                      _pulseController.value,
                    )
                  : null;
              final textColor = isUrgent ? colorScheme.error : null;

              return _HudItemCard(
                title: hasLimit ? 'Tiempo restante' : 'Tiempo',
                value: formattedTime,
                icon: Icons.timer_outlined,
                backgroundColor: color,
                textColor: textColor,
              );
            },
          ),
        ),
      ),
    ];

    final controlButtons = [
      FilledButton.tonalIcon(
        key: const Key('game_pause_button'),
        onPressed: widget.onPause,
        icon: const Icon(Icons.pause_rounded, size: 20),
        label: const Text('Pausa'),
      ),
      OutlinedButton.icon(
        key: const Key('game_restart_button'),
        onPressed: widget.onRestart,
        icon: const Icon(Icons.refresh_rounded, size: 20),
        label: const Text('Reiniciar'),
      ),
      OutlinedButton.icon(
        key: const Key('game_exit_button'),
        onPressed: widget.onExit,
        icon: const Icon(Icons.exit_to_app_rounded, size: 20),
        label: const Text('Salir'),
      ),
    ];

    if (widget.isLandscape) {
      return Container(
        padding: const EdgeInsets.all(AppTokens.spaceMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final card in hudCards) ...[
              card,
              const SizedBox(height: AppTokens.spaceSmall),
            ],
            const Spacer(),
            for (final btn in controlButtons) ...[
              btn,
              const SizedBox(height: AppTokens.spaceSmall),
            ],
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.spaceMedium,
        vertical: AppTokens.spaceSmall,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(children: hudCards),
          const SizedBox(height: AppTokens.spaceMedium),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (final btn in controlButtons)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: btn,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HudItemCard extends StatelessWidget {
  const _HudItemCard({
    required this.title,
    required this.value,
    required this.icon,
    this.subtitle,
    this.backgroundColor,
    this.textColor,
  });

  final String title;
  final String value;
  final IconData icon;
  final String? subtitle;
  final Color? backgroundColor;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.spaceSmall,
        vertical: AppTokens.spaceSmall,
      ),
      decoration: BoxDecoration(
        color:
            backgroundColor ??
            (isDark
                ? colorScheme.surfaceContainer
                : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: textColor ?? colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: textColor ?? colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: textColor ?? colorScheme.onSurface,
            ),
          ),
          if (subtitle != null) ...[
            Text(
              subtitle!,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                fontSize: 10,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
