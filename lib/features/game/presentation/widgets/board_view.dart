import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/theme/tokens.dart';
import '../../domain/entities/game_session.dart';
import 'tile_view.dart';

/// Interactive board view containing all tiles and supporting tap and swipe gestures.
class BoardView extends StatelessWidget {
  const BoardView({
    super.key,
    required this.session,
    required this.onTileTap,
    this.invalidTapIndex,
    this.invalidTapCount = 0,
    this.reduceMotion = false,
  });

  final GameSession session;
  final ValueChanged<int> onTileTap;
  final int? invalidTapIndex;
  final int invalidTapCount;
  final bool reduceMotion;

  void _handleSwipe(DragEndDetails details) {
    final velocity = details.velocity.pixelsPerSecond;
    final vx = velocity.dx;
    final vy = velocity.dy;

    // Minimum velocity to trigger swipe
    if (vx.abs() < 120 && vy.abs() < 120) return;

    final board = session.board;
    final size = board.size;
    final emptyRow = board.emptyIndex ~/ size;
    final emptyCol = board.emptyIndex % size;

    int targetRow = emptyRow;
    int targetCol = emptyCol;

    if (vx.abs() > vy.abs()) {
      // Horizontal swipe
      if (vx > 0) {
        // Swiping RIGHT: moves tile on the LEFT into empty space
        targetCol = emptyCol - 1;
      } else {
        // Swiping LEFT: moves tile on the RIGHT into empty space
        targetCol = emptyCol + 1;
      }
    } else {
      // Vertical swipe
      if (vy > 0) {
        // Swiping DOWN: moves tile ABOVE into empty space
        targetRow = emptyRow - 1;
      } else {
        // Swiping UP: moves tile BELOW into empty space
        targetRow = emptyRow + 1;
      }
    }

    if (targetRow >= 0 &&
        targetRow < size &&
        targetCol >= 0 &&
        targetCol < size) {
      final targetIndex = targetRow * size + targetCol;
      onTileTap(targetIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    final board = session.board;
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

        return Center(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragEnd: _handleSwipe,
            onVerticalDragEnd: _handleSwipe,
            child: Container(
              width: boardSize,
              height: boardSize,
              padding: const EdgeInsets.all(padding),
              decoration: BoxDecoration(
                color: isDark
                    ? colorScheme.surfaceContainerLowest
                    : colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.6,
                      ),
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
                  // Empty slot background grid
                  for (var r = 0; r < size; r++)
                    for (var c = 0; c < size; c++)
                      Positioned(
                        left: c * (tileSize + gap),
                        top: r * (tileSize + gap),
                        width: tileSize,
                        height: tileSize,
                        child: Container(
                          decoration: BoxDecoration(
                            color: isDark
                                ? colorScheme.surfaceContainer
                                : colorScheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(
                              AppTokens.radiusTile,
                            ),
                          ),
                        ),
                      ),

                  // Interactive sliding tiles
                  for (var i = 1; i < size * size; i++)
                    TileView(
                      key: ValueKey('tile_$i'),
                      tileNumber: i,
                      board: board,
                      tileSize: tileSize,
                      gap: gap,
                      shakeTrigger:
                          (invalidTapIndex != null &&
                              board.tiles.indexOf(i) == invalidTapIndex)
                          ? invalidTapCount
                          : 0,
                      reduceMotion: reduceMotion,
                      onTap: () {
                        final idx = board.tiles.indexOf(i);
                        if (idx != -1) {
                          onTileTap(idx);
                        }
                      },
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
