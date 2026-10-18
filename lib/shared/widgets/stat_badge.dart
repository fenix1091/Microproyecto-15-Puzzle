import 'package:flutter/material.dart';

import '../../app/theme/tokens.dart';

/// Small visual badge or card for displaying key metrics like moves, timer, streaks.
class StatBadge extends StatelessWidget {
  const StatBadge({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.highlight = false,
    this.semanticsLabel,
  });

  final String label;
  final String value;
  final IconData? icon;
  final bool highlight;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final bg = highlight
        ? colorScheme.primaryContainer
        : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5);
    final fg = highlight
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSurface;

    Widget content = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.spaceSmall,
        vertical: AppTokens.spaceSmall,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
        border: Border.all(
          color: highlight ? colorScheme.primary : colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: fg),
                const SizedBox(width: AppTokens.spaceXSmall),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: fg.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w500,
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
              color: fg,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );

    if (semanticsLabel != null) {
      content = Semantics(
        label: semanticsLabel,
        excludeSemantics: true,
        child: content,
      );
    }

    return content;
  }
}
