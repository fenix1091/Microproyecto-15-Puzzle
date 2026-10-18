import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sliding_puzzle/features/game/application/game_controller.dart';
import 'package:sliding_puzzle/features/game/presentation/pages/game_page.dart';
import 'package:sliding_puzzle/shared/widgets/exit_confirmation_dialog.dart';

import 'helpers/widget_test_helpers.dart';

void main() {
  group('GamePage Widget Tests', () {
    testWidgets('tapping a movable tile calls notifier.tap(index)', (
      tester,
    ) async {
      final fakeController = FakeGameController();

      await tester.pumpWidget(
        createTestApp(
          overrides: [
            gameControllerProvider.overrideWith(() => fakeController),
          ],
          child: const GamePage(),
        ),
      );
      await tester.pumpAndSettle();

      // Controller start was called on mount
      expect(fakeController.startCalled, isTrue);

      // In our board: [1, 2, 3, 4, 5, 6, 7, 0, 8]
      // 0 is at index 7. Movable tiles are 7 (at index 6), 8 (at index 8), and 2, 5 (at col 1).
      // Let's find tile 8 and tap it.
      final tile8Finder = find.widgetWithText(InkWell, '8');
      expect(tile8Finder, findsOneWidget);

      await tester.tap(tile8Finder);
      await tester.pump();

      // Index of tile 8 in tiles is 8
      expect(fakeController.tappedIndices, contains(8));
    });

    testWidgets('accessibility tap action triggers tile move via semantics', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final fakeController = FakeGameController();

      await tester.pumpWidget(
        createTestApp(
          overrides: [
            gameControllerProvider.overrideWith(() => fakeController),
          ],
          child: const GamePage(),
        ),
      );
      await tester.pumpAndSettle();

      final tile7Semantics = find.semantics.byLabel(
        'Ficha 7, fila 3, columna 1, movible',
      );
      expect(tile7Semantics, findsOne);

      tester.semantics.tap(tile7Semantics);
      await tester.pump();

      expect(fakeController.tappedIndices, contains(6));
      handle.dispose();
    });

    testWidgets('tile semantics labels follow exact QA contract', (
      tester,
    ) async {
      // In 3x3 board:
      // Row 0: 1, 2, 3
      // Row 1: 4, 5, 6
      // Row 2: 7, 0, 8
      // Tile 1 is at row 0, col 0 -> fila 1, columna 1. It is not adjacent to 0 at row 2, col 1.
      // Wait: canMove in 15-puzzle: Tile shares row or column with empty cell.
      // Empty cell is at row 2, col 1.
      // Tile 1 is at row 0, col 0. Neither row nor col matches -> NOT movable!
      // Tile 7 is at row 2, col 0 -> shares row 2 with 0 -> movible!
      final fakeController = FakeGameController();

      await tester.pumpWidget(
        createTestApp(
          overrides: [
            gameControllerProvider.overrideWith(() => fakeController),
          ],
          child: const GamePage(),
        ),
      );
      await tester.pumpAndSettle();

      // Check semantics for tile 1 (not movable): "Ficha 1, fila 1, columna 1"
      expect(
        find.bySemanticsLabel('Ficha 1, fila 1, columna 1'),
        findsOneWidget,
      );

      // Check semantics for tile 7 (movable): "Ficha 7, fila 3, columna 1, movible"
      expect(
        find.bySemanticsLabel('Ficha 7, fila 3, columna 1, movible'),
        findsOneWidget,
      );
    });

    testWidgets(
      'HUD displays correct individual semantics for tiempo, movimientos, nivel (QA-001)',
      (tester) async {
        final handle = tester.ensureSemantics();
        final fakeController = FakeGameController();

        await tester.pumpWidget(
          createTestApp(
            overrides: [
              gameControllerProvider.overrideWith(() => fakeController),
            ],
            child: const GamePage(),
          ),
        );
        await tester.pumpAndSettle();

        // Easy limit is 5 mins (300s). Elapsed is 42s -> Remaining is 258s = 04:18
        final timeFinder = find.bySemanticsLabel('Tiempo 04:18');
        final movesFinder = find.bySemanticsLabel('Movimientos 5');
        final levelFinder = find.bySemanticsLabel('Nivel Fácil');

        expect(timeFinder, findsOneWidget);
        expect(movesFinder, findsOneWidget);
        expect(levelFinder, findsOneWidget);

        // Verify each metric is its own distinct semantics node (QA-001)
        final timeNode = tester.getSemantics(timeFinder);
        final movesNode = tester.getSemantics(movesFinder);
        final levelNode = tester.getSemantics(levelFinder);

        expect(timeNode.label, equals('Tiempo 04:18'));
        expect(movesNode.label, equals('Movimientos 5'));
        expect(levelNode.label, equals('Nivel Fácil'));

        expect(timeNode.id, isNot(equals(movesNode.id)));
        expect(movesNode.id, isNot(equals(levelNode.id)));
        expect(timeNode.id, isNot(equals(levelNode.id)));

        handle.dispose();
      },
    );

    testWidgets('pause overlay appears and Reanudar resumes the game', (
      tester,
    ) async {
      final fakeController = FakeGameController();

      await tester.pumpWidget(
        createTestApp(
          overrides: [
            gameControllerProvider.overrideWith(() => fakeController),
          ],
          child: const GamePage(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Pausa button
      final pauseButton = find.widgetWithText(FilledButton, 'Pausa');
      expect(pauseButton, findsOneWidget);
      await tester.tap(pauseButton);
      await tester.pumpAndSettle();

      expect(fakeController.pauseCalled, isTrue);

      // Pause overlay is visible with "Reanudar"
      final resumeButton = find.widgetWithText(FilledButton, 'Reanudar');
      expect(resumeButton, findsOneWidget);

      await tester.tap(resumeButton);
      await tester.pumpAndSettle();

      expect(fakeController.resumeCalled, isTrue);
    });

    testWidgets('exit dialog opens on Salir button and cancels with Volver', (
      tester,
    ) async {
      final fakeController = FakeGameController();

      await tester.pumpWidget(
        createTestApp(
          overrides: [
            gameControllerProvider.overrideWith(() => fakeController),
          ],
          child: const GamePage(),
        ),
      );
      await tester.pumpAndSettle();

      // Find Salir button in HUD
      final exitButton = find.widgetWithText(OutlinedButton, 'Salir');
      expect(exitButton, findsOneWidget);
      await tester.tap(exitButton);
      await tester.pumpAndSettle();

      // ExitConfirmationDialog is visible
      expect(find.byType(ExitConfirmationDialog), findsOneWidget);
      expect(find.text('¿Abandonar partida?'), findsOneWidget);

      // Tap Volver (cancel)
      final backButton = find.widgetWithText(OutlinedButton, 'Volver');
      expect(backButton, findsOneWidget);
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      expect(find.byType(ExitConfirmationDialog), findsNothing);
      expect(fakeController.abandonCalled, isFalse);
    });

    testWidgets('exit dialog confirms and abandons game on Salir', (
      tester,
    ) async {
      final fakeController = FakeGameController();

      await tester.pumpWidget(
        createTestApp(
          overrides: [
            gameControllerProvider.overrideWith(() => fakeController),
          ],
          child: const GamePage(),
        ),
      );
      await tester.pumpAndSettle();

      final exitButton = find.widgetWithText(OutlinedButton, 'Salir');
      await tester.tap(exitButton);
      await tester.pumpAndSettle();

      // Tap Salir inside dialog
      final confirmButton = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(FilledButton, 'Salir'),
      );
      expect(confirmButton, findsOneWidget);
      await tester.tap(confirmButton);
      await tester.pumpAndSettle();

      expect(fakeController.abandonCalled, isTrue);
    });
  });
}
