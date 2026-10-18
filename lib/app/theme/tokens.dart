import 'package:flutter/material.dart';

/// Design tokens for Sliding Puzzle.
abstract final class AppTokens {
  // --- Durations & Curves ---
  static const Duration tileDuration = Duration(milliseconds: 140);
  static const Curve tileCurve = Curves.easeOutCubic;

  static const Duration shakeDuration = Duration(milliseconds: 250);
  static const Duration pulseDuration = Duration(milliseconds: 1000);
  static const Duration transitionDuration = Duration(milliseconds: 250);
  static const Duration splashMinDuration = Duration(milliseconds: 1200);

  // --- Sizing ---
  static const double minTouchTarget = 48.0;
  static const double maxBoardSize = 560.0;
  static const double boardScreenRatio = 0.9;
  static const double desktopBreakpoint = 760.0;

  // --- Radii ---
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 16.0;
  static const double radiusLarge = 24.0;
  static const double radiusTile = 12.0;

  // --- Spacing ---
  static const double spaceXSmall = 4.0;
  static const double spaceSmall = 8.0;
  static const double spaceMedium = 16.0;
  static const double spaceLarge = 24.0;
  static const double spaceXLarge = 32.0;

  /// Returns effective duration honoring motion preferences.
  static Duration getEffectiveDuration(
    BuildContext context,
    Duration normalDuration, {
    bool reduceMotion = false,
  }) {
    if (reduceMotion || MediaQuery.of(context).disableAnimations) {
      return Duration.zero;
    }
    return normalDuration;
  }
}
