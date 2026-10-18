import 'dart:math';

/// Randomness source, injectable so shuffles are reproducible with a seed.
abstract interface class RandomSource {
  /// Returns a value in `[0, max)`.
  int nextInt(int max);
}

class DartRandomSource implements RandomSource {
  DartRandomSource([int? seed]) : _random = Random(seed);

  final Random _random;

  @override
  int nextInt(int max) => _random.nextInt(max);
}
