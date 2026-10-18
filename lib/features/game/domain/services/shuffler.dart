import '../../../../core/utils/random_source.dart';
import '../entities/board.dart';
import '../entities/difficulty_config.dart';
import 'heuristics.dart';

/// Scrambles a solved board with a random walk of legal single-tile moves,
/// which keeps every board solvable by construction.
class Shuffler {
  const Shuffler(this._random);

  final RandomSource _random;

  /// Walks [DifficultyConfig.shuffleMoves] steps without immediately undoing
  /// the previous step, then keeps walking until
  /// `Heuristics.lowerBound >= minSolutionDepth` (capped at 4× the moves so it
  /// always terminates). Never returns a solved board.
  Board shuffle(DifficultyConfig config) {
    var board = Board.solved(config.boardSize);
    var previous = -1;
    final cap = config.shuffleMoves * 4;
    for (var step = 0; step < cap; step++) {
      if (step >= config.shuffleMoves &&
          Heuristics.lowerBound(board) >= config.minSolutionDepth &&
          !board.isSolved) {
        return board;
      }
      var choices = board.neighborsOfEmpty();
      if (previous >= 0 && choices.length > 1) {
        choices = choices.where((i) => i != previous).toList();
      }
      final selected = choices[_random.nextInt(choices.length)];
      previous = board.emptyIndex;
      board = board.move(selected);
    }
    return board.isSolved ? board.move(board.neighborsOfEmpty().first) : board;
  }
}
