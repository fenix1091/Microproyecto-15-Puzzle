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
    // TODO(backend): implement.
    throw UnimplementedError();
  }

  /// True when [index] shares a row or column with the empty cell (and is
  /// not the empty cell). Tapping it slides every tile between it and the
  /// empty cell, like the reference game.
  bool canMove(int index) {
    // TODO(backend): implement.
    throw UnimplementedError();
  }

  /// Indices whose tiles would slide if [index] were tapped, ordered from
  /// the one nearest the empty cell. Empty when the move is invalid.
  List<int> slideGroup(int index) {
    // TODO(backend): implement.
    throw UnimplementedError();
  }

  /// Returns the board after tapping [index]. Throws [StateError] if
  /// [canMove] is false.
  Board move(int index) {
    // TODO(backend): implement.
    throw UnimplementedError();
  }

  /// Indices adjacent (up/down/left/right) to the empty cell.
  List<int> neighborsOfEmpty() {
    // TODO(backend): implement.
    throw UnimplementedError();
  }

  /// True when the tile at [index] sits in its home cell.
  bool isTileHome(int index) {
    // TODO(backend): implement.
    throw UnimplementedError();
  }

  @override
  List<Object?> get props => [size, tiles];
}
