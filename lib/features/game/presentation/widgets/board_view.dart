import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/theme/tokens.dart';
import '../../domain/entities/board.dart';
import '../../domain/entities/game_session.dart';
import 'tile_view.dart';

/// Interactive board view containing all tiles and supporting tap and swipe gestures.
/// Optimized with value-based Board input, cached background grid, swipe by distance/speed,
/// and a celebration win pulse per MED-007, MED-012, MED-020, MED-021.
class BoardView extends StatefulWidget {
  const BoardView({
    super.key,
    required this.board,
    required this.status,
    required this.onTileTap,
    this.invalidTapIndex,
    this.invalidTapCount = 0,
    this.reduceMotion = false,
  });

  final Board board;
  final GameStatus status;
  final ValueChanged<int> onTileTap;
  final int? invalidTapIndex;
  final int invalidTapCount;
  final bool reduceMotion;

  @override
  State<BoardView> createState() => _BoardViewState();
}

class _BoardViewState extends State<BoardView>
    with SingleTickerProviderStateMixin {
  Offset _dragOffset = Offset.zero;
  int? _shakingTileNumber;
  late final AnimationController _winPulseController;
  late final Animation<double> _winScaleAnimation;

  @override
  void initState() {
    super.initState();
    _winPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _winScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.0,
          end: 1.04,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.04,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 60,
      ),
    ]).animate(_winPulseController);

    if (widget.status == GameStatus.won && !widget.reduceMotion) {
      _winPulseController.forward();
    }
  }

  @override
  void didUpdateWidget(covariant BoardView oldWidget) {
    super.didUpdateWidget(oldWidget);

    // C4 & MED-007: Trigger shake only when invalidTapCount changes, targeting the tile
    // at invalidTapIndex at that exact moment.
    if (widget.invalidTapCount > oldWidget.invalidTapCount &&
        widget.invalidTapIndex != null &&
        widget.invalidTapIndex! >= 0 &&
        widget.invalidTapIndex! < widget.board.tiles.length) {
      _shakingTileNumber = widget.board.tiles[widget.invalidTapIndex!];
    }

    // MED-020: Win pulse celebration
    if (widget.status == GameStatus.won &&
        oldWidget.status != GameStatus.won &&
        !widget.reduceMotion) {
      _winPulseController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _winPulseController.dispose();
    super.dispose();
  }

  void _handlePanStart(DragStartDetails details) {
    _dragOffset = Offset.zero;
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    _dragOffset += details.delta;
  }

  void _handlePanEnd(DragEndDetails details) {
    final velocity = details.velocity.pixelsPerSecond;
    final vx = velocity.dx;
    final vy = velocity.dy;
    final dx = _dragOffset.dx;
    final dy = _dragOffset.dy;

    // MED-021: Trigger by distance >= 24 px OR velocity >= 120 px/s
    final hasDistance = dx.abs() >= 24.0 || dy.abs() >= 24.0;
    final hasVelocity = vx.abs() >= 120.0 || vy.abs() >= 120.0;
    if (!hasDistance && !hasVelocity) return;

    final board = widget.board;
    final size = board.size;
    final emptyRow = board.emptyIndex ~/ size;
    final emptyCol = board.emptyIndex % size;

    int targetRow = emptyRow;
    int targetCol = emptyCol;

    // Determine direction from dominant axis (prefer distance if strong, else velocity)
    final isHorizontal = hasDistance
        ? dx.abs() >= dy.abs()
        : vx.abs() >= vy.abs();

    if (isHorizontal) {
      final isRight = hasDistance ? dx > 0 : vx > 0;
      if (isRight) {
        // Swiping RIGHT moves tile on the LEFT into empty space
        targetCol = emptyCol - 1;
      } else {
        // Swiping LEFT moves tile on the RIGHT into empty space
        targetCol = emptyCol + 1;
      }
    } else {
      final isDown = hasDistance ? dy > 0 : vy > 0;
      if (isDown) {
        // Swiping DOWN moves tile ABOVE into empty space
        targetRow = emptyRow - 1;
      } else {
        // Swiping UP moves tile BELOW into empty space
        targetRow = emptyRow + 1;
      }
    }

    if (targetRow >= 0 &&
        targetRow < size &&
        targetCol >= 0 &&
        targetCol < size) {
      final targetIndex = targetRow * size + targetCol;
      widget.onTileTap(targetIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    final board = widget.board;
    final size = board.size;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Square board = min(w, h) * 0.9 capped at 560
        final availableSize = math.min(
          constraints.maxWidth,
          constraints.maxHeight,
        );
        final boardSize = math.min(
          availableSize * AppTokens.boardScreenRatio,
          AppTokens.maxBoardSize,
        );

        const padding = AppTokens.spaceMedium;
        final gap = math.max(4.0, (16.0 - size * 2.0));
        final boardInnerSize = boardSize - (padding * 2);
        final tileSize = (boardInnerSize - (gap * (size - 1))) / size;

        Widget boardContent = Container(
          width: boardSize,
          height: boardSize,
          padding: const EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: isDark
                ? colorScheme.surfaceContainerLowest
                : colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // MED-012: Static empty-cell background cached widget
              _EmptySlotsGrid(
                size: size,
                tileSize: tileSize,
                gap: gap,
                isDark: isDark,
              ),

              // Interactive sliding tiles
              for (var i = 1; i < size * size; i++)
                TileView(
                  key: ValueKey('tile_$i'),
                  tileNumber: i,
                  board: board,
                  tileSize: tileSize,
                  gap: gap,
                  shakeTrigger: (i == _shakingTileNumber)
                      ? widget.invalidTapCount
                      : 0,
                  reduceMotion: widget.reduceMotion,
                  onTap: () {
                    final idx = board.tiles.indexOf(i);
                    if (idx != -1) {
                      widget.onTileTap(idx);
                    }
                  },
                ),
            ],
          ),
        );

        if (!widget.reduceMotion) {
          boardContent = ScaleTransition(
            scale: _winScaleAnimation,
            child: boardContent,
          );
        }

        return Center(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanStart: _handlePanStart,
            onPanUpdate: _handlePanUpdate,
            onPanEnd: _handlePanEnd,
            child: boardContent,
          ),
        );
      },
    );
  }
}

/// Static empty slot background cached to avoid unnecessary element rebuilding.
class _EmptySlotsGrid extends StatelessWidget {
  const _EmptySlotsGrid({
    required this.size,
    required this.tileSize,
    required this.gap,
    required this.isDark,
  });

  final int size;
  final double tileSize;
  final double gap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final slotColor = isDark
        ? colorScheme.surfaceContainer
        : colorScheme.surfaceContainerLow;

    return Stack(
      children: [
        for (var r = 0; r < size; r++)
          for (var c = 0; c < size; c++)
            Positioned(
              left: c * (tileSize + gap),
              top: r * (tileSize + gap),
              width: tileSize,
              height: tileSize,
              child: Container(
                decoration: BoxDecoration(
                  color: slotColor,
                  borderRadius: BorderRadius.circular(AppTokens.radiusTile),
                ),
              ),
            ),
      ],
    );
  }
}
