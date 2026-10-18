import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../app/theme/tokens.dart';
import '../../../../shared/widgets/exit_confirmation_dialog.dart';
import '../../../settings/application/settings_controller.dart';
import '../../application/game_controller.dart';
import '../../application/game_state.dart';
import '../../domain/entities/game_result.dart';
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

  GameController? _controller;
  GameStatus? _lastStatus;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller = ref.read(gameControllerProvider.notifier);
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    try {
      if (_lastStatus == GameStatus.playing) {
        _controller?.pause();
      }
    } catch (_) {}
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
        // C1 & MED-005 & MED-017: Explicit navigation to /menu without try/catch
        context.go(AppRoutes.menu);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // C1 & MED-005: Result listener navigates to /result ONLY for won or lost
    ref.listen<GameState>(gameControllerProvider, (previous, next) {
      final result = next.result;
      if (result != null && previous?.result != result) {
        if (result.outcome == GameOutcome.won ||
            result.outcome == GameOutcome.lost) {
          context.go(AppRoutes.result, extra: result);
        }
      }
    });

    // MED-012: Fine-grained select watchers
    final isStarting = ref.watch(
      gameControllerProvider.select((s) => s.isStarting),
    );
    final failure = ref.watch(gameControllerProvider.select((s) => s.failure));
    final session = ref.watch(gameControllerProvider.select((s) => s.session));
    final invalidTapIndex = ref.watch(
      gameControllerProvider.select((s) => s.invalidTapIndex),
    );
    final invalidTapCount = ref.watch(
      gameControllerProvider.select((s) => s.invalidTapCount),
    );
    final decision = ref.watch(
      gameControllerProvider.select((s) => s.decision),
    );

    final settings = ref.watch(settingsControllerProvider).asData?.value;
    final reduceMotion = settings?.reduceMotion ?? false;
    _lastStatus = session?.status;

    // C3 & MED-006: Failure state with Reintentar & Volver
    if (failure != null && session == null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppTokens.spaceLarge),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 48,
                  color: colorScheme.error,
                ),
                const SizedBox(height: AppTokens.spaceMedium),
                Text(
                  'Error al iniciar la partida',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppTokens.spaceLarge),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton(
                      onPressed: () => context.go(AppRoutes.menu),
                      child: const Text('Volver'),
                    ),
                    const SizedBox(width: AppTokens.spaceMedium),
                    FilledButton.icon(
                      onPressed: () =>
                          ref.read(gameControllerProvider.notifier).start(),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Reintentar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    // C3 & MED-006: Spinner while starting or session is null
    if (isStarting || session == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isPaused = session.status == GameStatus.paused;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _handleExit();
      },
      child: Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              // MED-008: While paused exclude background from semantics and pointer
              ExcludeSemantics(
                excluding: isPaused,
                child: IgnorePointer(
                  ignoring: isPaused,
                  child: LayoutBuilder(
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
                                decision: decision,
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
                                board: session.board,
                                status: session.status,
                                invalidTapIndex: invalidTapIndex,
                                invalidTapCount: invalidTapCount,
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
                            decision: decision,
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
                              board: session.board,
                              status: session.status,
                              invalidTapIndex: invalidTapIndex,
                              invalidTapCount: invalidTapCount,
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
                ),
              ),

              // Pause Overlay
              if (isPaused)
                Positioned.fill(
                  child: PauseOverlay(
                    onResume: () =>
                        ref.read(gameControllerProvider.notifier).resume(),
                    onRestart: () =>
                        ref.read(gameControllerProvider.notifier).restart(),
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
