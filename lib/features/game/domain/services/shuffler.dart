import '../../../../core/utils/random_source.dart';
import '../entities/board.dart';
import '../entities/difficulty_config.dart';

/// Scrambles a solved board with a random walk of legal single-tile moves,
/// which keeps every board solvable by construction.
class Shuffler {
  const Shuffler(this._random);

  // ignore: unused_field
  final RandomSource _random;

  /// Walks [DifficultyConfig.shuffleMoves] steps without immediately undoing
  /// the previous step, then keeps walking until
  /// `Heuristics.lowerBound >= minSolutionDepth` (capped at 4× the moves so it
  /// always terminates). Never returns a solved board.
  Board shuffle(DifficultyConfig config) {
    // TODO(backend): implement. Must stay < 50 ms for 6×6 / 800 moves.
    throw UnimplementedError();
  }
}
