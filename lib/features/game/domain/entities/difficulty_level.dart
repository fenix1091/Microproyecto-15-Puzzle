/// Difficulty tiers, ordered from easiest to hardest.
enum DifficultyLevel {
  easy,
  medium,
  hard,
  expert,
  master;

  bool get isFirst => index == 0;
  bool get isLast => index == values.length - 1;

  DifficultyLevel get next => isLast ? this : values[index + 1];
  DifficultyLevel get previous => isFirst ? this : values[index - 1];

  /// Stable key for persistence; never rename.
  String get key => name;

  static DifficultyLevel fromKey(String key) =>
      values.firstWhere((l) => l.key == key, orElse: () => easy);
}
