import '../entities/board.dart';

/// Admissible lower bounds on the number of single-tile moves to solve.
abstract final class Heuristics {
  /// Sum of each tile's Manhattan distance to its home cell.
  static int manhattan(Board board) {
    // TODO(backend): implement.
    throw UnimplementedError();
  }

  /// Extra moves forced by tiles in their home row/column but reversed
  /// (2 per conflict, computed per line).
  static int linearConflict(Board board) {
    // TODO(backend): implement.
    throw UnimplementedError();
  }

  /// `manhattan + linearConflict`; this is the "solution depth" the
  /// difficulty system requires.
  static int lowerBound(Board board) =>
      manhattan(board) + linearConflict(board);
}
