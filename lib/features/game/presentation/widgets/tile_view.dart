import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/theme/tokens.dart';
import '../../domain/entities/board.dart';

/// Single interactive sliding tile.
/// Uses [AnimatedPositioned] to glide smoothly into position.
/// Renders subtle highlight when home and shakes on invalid moves.
class TileView extends StatefulWidget {
  const TileView({
    super.key,
    required this.tileNumber,
    required this.board,
    required this.tileSize,
    required this.gap,
    required this.onTap,
    required this.shakeTrigger,
    this.reduceMotion = false,
  });

  final int tileNumber;
  final Board board;
  final double tileSize;
  final double gap;
  final VoidCallback onTap;
  final int shakeTrigger;
  final bool reduceMotion;

  @override
  State<TileView> createState() => _TileViewState();
}

class _TileViewState extends State<TileView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: AppTokens.shakeDuration,
    );
  }

  @override
  void didUpdateWidget(covariant TileView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shakeTrigger != oldWidget.shakeTrigger &&
        widget.shakeTrigger > 0 &&
        !widget.reduceMotion) {
      _shakeController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  bool _isTileHome(int index) => widget.board.isTileHome(index);

  bool _canMove(int index) => widget.board.canMove(index);

  @override
  Widget build(BuildContext context) {
    final currentIndex = widget.board.tiles.indexOf(widget.tileNumber);
    if (currentIndex == -1) return const SizedBox.shrink();

    final size = widget.board.size;
    final row = currentIndex ~/ size;
    final col = currentIndex % size;

    final left = col * (widget.tileSize + widget.gap);
    final top = row * (widget.tileSize + widget.gap);

    final canMove = _canMove(currentIndex);
    final isHome = _isTileHome(currentIndex);

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;

    // QA / Playwright Accessibility semantics label:
    // "Ficha {n}, fila {r}, columna {c}" (+ ", movible" when canMove), 1-based row/col; button role.
    final semanticsLabel =
        'Ficha ${widget.tileNumber}, fila ${row + 1}, columna ${col + 1}'
        '${canMove ? ", movible" : ""}';

    final effectiveDuration = AppTokens.getEffectiveDuration(
      context,
      AppTokens.tileDuration,
      reduceMotion: widget.reduceMotion,
    );

    return AnimatedPositioned(
      key: ValueKey(widget.tileNumber),
      duration: effectiveDuration,
      curve: AppTokens.tileCurve,
      left: left,
      top: top,
      width: widget.tileSize,
      height: widget.tileSize,
      child: RepaintBoundary(
        child: Semantics(
          label: semanticsLabel,
          button: true,
          enabled: canMove,
          onTap: canMove ? widget.onTap : null,
          excludeSemantics: true,
          child: AnimatedBuilder(
            animation: _shakeController,
            builder: (context, child) {
              final shakeOffset = widget.reduceMotion
                  ? 0.0
                  : math.sin(_shakeController.value * math.pi * 6) * 6.0;
              return Transform.translate(
                offset: Offset(shakeOffset, 0),
                child: child,
              );
            },
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(AppTokens.radiusTile),
                onTap: widget.onTap,
                child: Ink(
                  decoration: BoxDecoration(
                    color: isHome
                        ? (isDark
                              ? colorScheme.primaryContainer.withValues(
                                  alpha: 0.9,
                                )
                              : colorScheme.primaryContainer)
                        : (isDark
                              ? colorScheme.surfaceContainerHigh
                              : colorScheme.surface),
                    borderRadius: BorderRadius.circular(AppTokens.radiusTile),
                    border: Border.all(
                      color: isHome
                          ? colorScheme.primary
                          : (canMove
                                ? colorScheme.outline.withValues(alpha: 0.5)
                                : colorScheme.outlineVariant.withValues(
                                    alpha: 0.3,
                                  )),
                      width: isHome ? 2.0 : 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.3 : 0.08,
                        ),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '${widget.tileNumber}',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: math.max(16, widget.tileSize * 0.4),
                        color: isHome
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
