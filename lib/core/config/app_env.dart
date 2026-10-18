/// Compile-time switches passed with `--dart-define`.
///
/// QA builds: `flutter build web --dart-define=QA=true --dart-define=QA_SEED=42`
abstract final class AppEnv {
  /// Enables the semantics tree on web so Playwright can query roles/labels,
  /// and makes shuffles deterministic when [qaSeed] is set.
  static const bool qa = bool.fromEnvironment('QA');

  /// Fixed RNG seed for reproducible boards; `-1` means random.
  static const int qaSeed = int.fromEnvironment('QA_SEED', defaultValue: -1);

  /// Overrides every level's time limit (seconds) to test defeats; `0` = off.
  static const int qaTimeLimitSeconds = int.fromEnvironment(
    'QA_TIME_LIMIT',
    defaultValue: 0,
  );

  /// Overrides every level's shuffle moves to produce near-solved boards; `0` = off.
  static const int qaShuffleMoves = int.fromEnvironment(
    'QA_SHUFFLE_MOVES',
    defaultValue: 0,
  );
}
