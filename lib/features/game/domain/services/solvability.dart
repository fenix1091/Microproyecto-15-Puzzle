import '../entities/board.dart';

bool isSolvable(Board board) {
  final inversions = countInversions(board);
  if (board.size.isOdd) return inversions.isEven;
  final rowFromBottom = board.size - board.rowOf(board.emptyIndex);
  return (inversions + rowFromBottom).isOdd;
}

int countInversions(Board board) {
  var count = 0;
  for (var i = 0; i < board.length; i++) {
    if (board.tiles[i] == 0) continue;
    for (var j = i + 1; j < board.length; j++) {
      if (board.tiles[j] != 0 && board.tiles[i] > board.tiles[j]) count++;
    }
  }
  return count;
}
