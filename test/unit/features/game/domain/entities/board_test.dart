import 'package:flutter_test/flutter_test.dart';
import 'package:sliding_puzzle/features/game/domain/entities/board.dart';

void main() {
  test('solved state and tile home', () {
    final board = Board.solved(3);
    expect(board.isSolved, isTrue);
    expect(board.isTileHome(8), isTrue);
    expect(board.isTileHome(-1), isFalse);
  });

  test('group slide shifts all intervening tiles in one move', () {
    final board = Board(size: 3, tiles: [1, 2, 3, 4, 0, 6, 7, 5, 8]);
    expect(board.canMove(7), isTrue);
    expect(board.slideGroup(7), [7]);
    expect(board.move(7).tiles, [1, 2, 3, 4, 5, 6, 7, 0, 8]);
    expect(board.canMove(0), isFalse);
    expect(() => board.move(0), throwsStateError);
  });

  test('multi tile slide, invalid edges, neighbors', () {
    final board = Board(size: 3, tiles: [1, 2, 3, 0, 4, 5, 6, 7, 8]);
    expect(board.slideGroup(5), [4, 5]);
    expect(board.move(5).tiles, [1, 2, 3, 4, 5, 0, 6, 7, 8]);
    expect(board.neighborsOfEmpty(), [0, 4, 6]);
    expect(board.canMove(9), isFalse);
  });
}
