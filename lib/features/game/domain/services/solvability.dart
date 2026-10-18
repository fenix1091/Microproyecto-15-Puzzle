import '../entities/board.dart';

/// Parity check: odd widths need an even inversion count; even widths need
/// `inversions + emptyRowFromBottom` to be odd (row counted from 1).
bool isSolvable(Board board) {
  // TODO(backend): implement.
  throw UnimplementedError();
}

/// Number of tile pairs (a, b) with a before b and a > b, ignoring the empty cell.
int countInversions(Board board) {
  // TODO(backend): implement.
  throw UnimplementedError();
}
