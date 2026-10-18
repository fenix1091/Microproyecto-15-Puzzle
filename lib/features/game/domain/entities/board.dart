import 'package:equatable/equatable.dart';

/// Immutable N×N sliding-puzzle board.
///
/// [tiles] is row-major; value `0` is the empty cell and values `1..N²-1`
/// are tiles. The solved board is `[1, 2, ..., N²-1, 0]`.
class Board extends Equatable {
  Board({required this.size, required List<int> tiles})
    : assert(size >= 2),
      assert(tiles.length == size * size),
      tiles = List.unmodifiable(tiles),
      emptyIndex = tiles.indexOf(0);

  factory Board.solved(int size) =>
      Board(size: size, tiles: [for (var i = 1; i < size * size; i++) i, 0]);

  final int size;
  final List<int> tiles;
  final int emptyIndex;

  int get length => tiles.length;
  int rowOf(int index) => index ~/ size;
  int colOf(int index) => index % size;
  int indexOf(int row, int col) => row * size + col;

  /// True when every tile is in its home cell.
  bool get isSolved {
    for (var i = 0; i < tiles.length - 1; i++) {
      if (tiles[i] != i + 1) return false;
    }
    return tiles.last == 0;
  }

  /// True when [index] shares a row or column with the empty cell (and is
  /// not the empty cell). Tapping it slides every tile between it and the
  /// empty cell, like the reference game.
  bool canMove(int index) {
    if (index < 0 || index >= length || index == emptyIndex) return false;
    return rowOf(index) == rowOf(emptyIndex) ||
        colOf(index) == colOf(emptyIndex);
  }

  /// Indices whose tiles would slide if [index] were tapped, ordered from
  /// the one nearest the empty cell. Empty when the move is invalid.
  List<int> slideGroup(int index) {
    if (!canMove(index)) return const [];
    final result = <int>[];
    final er = rowOf(emptyIndex), ec = colOf(emptyIndex);
    final tr = rowOf(index), tc = colOf(index);
    final dr = (tr - er).sign, dc = (tc - ec).sign;
    var r = er + dr, c = ec + dc;
    while (r != tr || c != tc) {
      result.add(indexOf(r, c));
      r += dr;
      c += dc;
    }
    result.add(index);
    return result;
  }

  /// Returns the board after tapping [index]. Throws [StateError] if
  /// [canMove] is false.
  Board move(int index) {
    final group = slideGroup(index);
    if (group.isEmpty) throw StateError('Invalid move');
    final next = List<int>.of(tiles);
    var hole = emptyIndex;
    for (final tileIndex in group) {
      next[hole] = next[tileIndex];
      hole = tileIndex;
    }
    next[hole] = 0;
    return Board(size: size, tiles: next);
  }

  /// Indices adjacent (up/down/left/right) to the empty cell.
  List<int> neighborsOfEmpty() {
    final r = rowOf(emptyIndex), c = colOf(emptyIndex);
    return [
      if (r > 0) indexOf(r - 1, c),
      if (c > 0) indexOf(r, c - 1),
      if (c + 1 < size) indexOf(r, c + 1),
      if (r + 1 < size) indexOf(r + 1, c),
    ];
  }

  /// True when the tile at [index] sits in its home cell.
  bool isTileHome(int index) {
    if (index < 0 || index >= length) return false;
    final tile = tiles[index];
    return tile == 0 ? index == length - 1 : index == tile - 1;
  }

  @override
  List<Object?> get props => [size, tiles];
}
