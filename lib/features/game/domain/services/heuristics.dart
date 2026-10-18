import '../entities/board.dart';

abstract final class Heuristics {
  static int manhattan(Board board) {
    var sum = 0;
    for (var i = 0; i < board.length; i++) {
      final tile = board.tiles[i];
      if (tile == 0) continue;
      final home = tile - 1;
      sum +=
          (board.rowOf(i) - board.rowOf(home)).abs() +
          (board.colOf(i) - board.colOf(home)).abs();
    }
    return sum;
  }

  static int linearConflict(Board board) {
    var conflicts = 0;
    for (var r = 0; r < board.size; r++) {
      for (var a = 0; a < board.size; a++) {
        final ta = board.tiles[board.indexOf(r, a)];
        if (ta == 0 || board.rowOf(ta - 1) != r) continue;
        for (var b = a + 1; b < board.size; b++) {
          final tb = board.tiles[board.indexOf(r, b)];
          if (tb != 0 &&
              board.rowOf(tb - 1) == r &&
              board.colOf(ta - 1) > board.colOf(tb - 1)) {
            conflicts++;
          }
        }
      }
    }
    for (var c = 0; c < board.size; c++) {
      for (var a = 0; a < board.size; a++) {
        final ta = board.tiles[board.indexOf(a, c)];
        if (ta == 0 || board.colOf(ta - 1) != c) continue;
        for (var b = a + 1; b < board.size; b++) {
          final tb = board.tiles[board.indexOf(b, c)];
          if (tb != 0 &&
              board.colOf(tb - 1) == c &&
              board.rowOf(ta - 1) > board.rowOf(tb - 1)) {
            conflicts++;
          }
        }
      }
    }
    return conflicts * 2;
  }

  static int lowerBound(Board board) =>
      manhattan(board) + linearConflict(board);
}
