import 'package:flutter/material.dart';

import '../../app/theme/tokens.dart';

/// Animated 2x2 puzzle logo representing sliding tiles.
/// Staggered scale and fade animation.
class AnimatedLogo extends StatefulWidget {
  const AnimatedLogo({
    super.key,
    this.size = 140.0,
    this.animate = true,
    this.reduceMotion = false,
  });

  final double size;
  final bool animate;
  final bool reduceMotion;

  @override
  State<AnimatedLogo> createState() => _AnimatedLogoState();
}

class _AnimatedLogoState extends State<AnimatedLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    if (widget.animate) {
      _controller.forward();
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedLogo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate &&
        !_controller.isAnimating &&
        !_controller.isCompleted) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        widget.reduceMotion || MediaQuery.of(context).disableAnimations;
    final colorScheme = Theme.of(context).colorScheme;
    final tileSize = (widget.size - 12) / 2;

    // 4 tiles: [1, 5], [★, empty]
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        children: [
          // Empty slot background in bottom right
          Positioned(
            left: tileSize + 12,
            top: tileSize + 12,
            width: tileSize,
            height: tileSize,
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.4,
                ),
                borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
            ),
          ),
          // Tile 1 (top-left)
          _buildAnimatedTile(
            label: '1',
            left: 0,
            top: 0,
            size: tileSize,
            startInterval: 0.0,
            endInterval: 0.5,
            color: colorScheme.primary,
            textColor: colorScheme.onPrimary,
            reduceMotion: reduceMotion,
          ),
          // Tile 2 (top-right)
          _buildAnimatedTile(
            label: '5',
            left: tileSize + 12,
            top: 0,
            size: tileSize,
            startInterval: 0.15,
            endInterval: 0.65,
            color: colorScheme.primaryContainer,
            textColor: colorScheme.onPrimaryContainer,
            reduceMotion: reduceMotion,
          ),
          // Tile 3 (bottom-left)
          _buildAnimatedTile(
            label: '★',
            left: 0,
            top: tileSize + 12,
            size: tileSize,
            startInterval: 0.3,
            endInterval: 0.8,
            color: colorScheme.tertiaryContainer,
            textColor: colorScheme.onTertiaryContainer,
            reduceMotion: reduceMotion,
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedTile({
    required String label,
    required double left,
    required double top,
    required double size,
    required double startInterval,
    required double endInterval,
    required Color color,
    required Color textColor,
    required bool reduceMotion,
  }) {
    if (reduceMotion) {
      return Positioned(
        left: left,
        top: top,
        width: size,
        height: size,
        child: _TileBox(label: label, color: color, textColor: textColor),
      );
    }

    final curved = CurvedAnimation(
      parent: _controller,
      curve: Interval(startInterval, endInterval, curve: Curves.easeOutBack),
    );

    return Positioned(
      left: left,
      top: top,
      width: size,
      height: size,
      child: FadeTransition(
        opacity: CurvedAnimation(
          parent: _controller,
          curve: Interval(startInterval, endInterval, curve: Curves.easeIn),
        ),
        child: ScaleTransition(
          scale: curved,
          child: _TileBox(label: label, color: color, textColor: textColor),
        ),
      ),
    );
  }
}

class _TileBox extends StatelessWidget {
  const _TileBox({
    required this.label,
    required this.color,
    required this.textColor,
  });

  final String label;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
