import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../app/theme/tokens.dart';

/// Full-screen or board overlay displayed while game is paused.
/// Hides the board so the player cannot analyze positions while timer is stopped.
class PauseOverlay extends StatelessWidget {
  const PauseOverlay({
    super.key,
    required this.onResume,
    required this.onRestart,
    required this.onExit,
  });

  final VoidCallback onResume;
  final VoidCallback onRestart;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: Container(
        color: Colors.black.withValues(alpha: 0.65),
        alignment: Alignment.center,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppTokens.spaceLarge),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.pause_circle_filled_rounded,
                    size: 64,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(height: AppTokens.spaceMedium),
                  Text(
                    'Partida pausada',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppTokens.spaceSmall),
                  Text(
                    'Tómate un respiro antes de continuar.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppTokens.spaceXLarge),
                  FilledButton.icon(
                    key: const Key('pause_resume_button'),
                    onPressed: onResume,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Reanudar'),
                  ),
                  const SizedBox(height: AppTokens.spaceSmall),
                  OutlinedButton.icon(
                    key: const Key('pause_restart_button'),
                    onPressed: onRestart,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Reiniciar'),
                  ),
                  const SizedBox(height: AppTokens.spaceSmall),
                  TextButton.icon(
                    key: const Key('pause_exit_button'),
                    onPressed: onExit,
                    icon: const Icon(Icons.exit_to_app_rounded),
                    label: const Text('Salir'),
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
