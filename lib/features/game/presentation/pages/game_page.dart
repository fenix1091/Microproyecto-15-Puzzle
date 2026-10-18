import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../app/theme/tokens.dart';
import '../../../../shared/widgets/exit_confirmation_dialog.dart';
import '../../../settings/application/settings_controller.dart';
import '../../application/game_controller.dart';
import '../../application/game_state.dart';
import '../../domain/entities/game_session.dart';
import '../widgets/board_view.dart';
import '../widgets/game_hud.dart';
import '../widgets/pause_overlay.dart';

/// Game screen hosting the interactive board, HUD, pause overlay, and exit handling.
class GamePage extends ConsumerStatefulWidget {
  const GamePage({super.key});

  @override
  ConsumerState<GamePage> createState() => _GamePageState();
}

class _GamePageState extends ConsumerState<GamePage> {
  late final AppLifecycleListener _lifecycleListener;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(gameControllerProvider.notifier).start();
    });

    _lifecycleListener = AppLifecycleListener(
      onInactive: () {
        final session = ref.read(gameControllerProvider).session;
        if (session != null && session.status == GameStatus.playing) {
          ref.read(gameControllerProvider.notifier).pause();
        }
      },
      onPause: () {
        final session = ref.read(gameControllerProvider).session;
        if (session != null && session.status == GameStatus.playing) {
          ref.read(gameControllerProvider.notifier).pause();
        }
      },
    );
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    super.dispose();
  }

  Future<void> _handleExit() async {
    final session = ref.read(gameControllerProvider).session;
    // Auto-pause while dialog is displayed if playing
    if (session != null && session.status == GameStatus.playing) {
      ref.read(gameControllerProvider.notifier).pause();
    }

    final confirmed = await ExitConfirmationDialog.show(context);
    if (confirmed && mounted) {
      await ref.read(gameControllerProvider.notifier).abandon();
      if (mounted) {
        try {
          context.go(AppRoutes.menu);
        } catch (_) {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen for completion (won/lost/abandoned) and navigate to result
    ref.listen<GameState>(gameControllerProvider, (previous, next) {
      final result = next.result;
      if (result != null && previous?.result != result) {
        try {
          context.go(AppRoutes.result, extra: result);
        } catch (_) {}
      }
    });

    final gameState = ref.watch(gameControllerProvider);
    final session = gameState.session;
    final settings = ref.watch(settingsControllerProvider).asData?.value;
    final reduceMotion = settings?.reduceMotion ?? false;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _handleExit();
      },
      child: Scaffold(
        body: SafeArea(
          child: session == null
              ? const Center(child: CircularProgressIndicator())
              : Stack(
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isLandscape =
                            constraints.maxWidth > constraints.maxHeight ||
                            constraints.maxWidth >= AppTokens.desktopBreakpoint;

                        if (isLandscape) {
                          return Row(
                            children: [
                              SizedBox(
                                width: 280,
                                child: GameHud(
                                  session: session,
                                  isLandscape: true,
                                  reduceMotion: reduceMotion,
                                  onPause: () => ref
                                      .read(gameControllerProvider.notifier)
                                      .pause(),
                                  onRestart: () => ref
                                      .read(gameControllerProvider.notifier)
                                      .restart(),
                                  onExit: _handleExit,
                                ),
                              ),
                              const VerticalDivider(width: 1),
                              Expanded(
                                child: BoardView(
                                  session: session,
                                  invalidTapIndex: gameState.invalidTapIndex,
                                  invalidTapCount: gameState.invalidTapCount,
                                  reduceMotion: reduceMotion,
                                  onTileTap: (index) => ref
                                      .read(gameControllerProvider.notifier)
                                      .tap(index),
                                ),
                              ),
                            ],
                          );
                        }

                        return Column(
                          children: [
                            GameHud(
                              session: session,
                              isLandscape: false,
                              reduceMotion: reduceMotion,
                              onPause: () => ref
                                  .read(gameControllerProvider.notifier)
                                  .pause(),
                              onRestart: () => ref
                                  .read(gameControllerProvider.notifier)
                                  .restart(),
                              onExit: _handleExit,
                            ),
                            Expanded(
                              child: BoardView(
                                session: session,
                                invalidTapIndex: gameState.invalidTapIndex,
                                invalidTapCount: gameState.invalidTapCount,
                                reduceMotion: reduceMotion,
                                onTileTap: (index) => ref
                                    .read(gameControllerProvider.notifier)
                                    .tap(index),
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                    // Pause Overlay
                    if (session.status == GameStatus.paused)
                      Positioned.fill(
                        child: PauseOverlay(
                          onResume: () => ref
                              .read(gameControllerProvider.notifier)
                              .resume(),
                          onRestart: () => ref
                              .read(gameControllerProvider.notifier)
                              .restart(),
                          onExit: _handleExit,
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}
