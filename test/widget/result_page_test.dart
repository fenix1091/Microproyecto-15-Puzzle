import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sliding_puzzle/features/game/domain/entities/difficulty_level.dart';
import 'package:sliding_puzzle/features/game/domain/entities/game_result.dart';
import 'package:sliding_puzzle/features/game/presentation/pages/result_page.dart';
import 'package:sliding_puzzle/features/leaderboard/application/leaderboard_providers.dart';
import 'package:sliding_puzzle/features/leaderboard/domain/entities/leaderboard_entry.dart';

import 'helpers/widget_test_helpers.dart';

void main() {
  group('ResultPage Widget Tests', () {
    testWidgets('renders win result with ¡Victoria!, efficiency, and buttons', (
      tester,
    ) async {
      final winResult = GameResult(
        level: DifficultyLevel.medium,
        boardSize: 4,
        moves: 30,
        duration: const Duration(minutes: 2, seconds: 15),
        outcome: GameOutcome.won,
        minSolutionDepth: 25,
        playedAt: DateTime(2026, 10, 17, 14, 30),
        isPersonalBest: false,
      );

      final personalBestEntry = LeaderboardEntry(
        rank: 1,
        level: DifficultyLevel.medium,
        boardSize: 4,
        duration: const Duration(minutes: 1, seconds: 45),
        moves: 28,
        playedAt: DateTime(2026, 10, 16),
      );

      await tester.pumpWidget(
        createTestApp(
          overrides: [
            personalBestProvider(DifficultyLevel.medium).overrideWith(
              (ref) async => personalBestEntry,
            ),
          ],
          child: ResultPage(result: winResult),
        ),
      );
      await tester.pumpAndSettle();

      // Title
      expect(find.text('¡Victoria!'), findsOneWidget);
      expect(find.text('Nivel Medio (4×4)'), findsOneWidget);

      // Moves and Time
      expect(find.text('02:15'), findsOneWidget);
      expect(find.text('30'), findsOneWidget);

      // Efficiency: 30 / 25 = 1.2x
      expect(find.text('1.2×'), findsOneWidget);

      // Best time from provider
      expect(find.text('01:45'), findsOneWidget);

      // Not a personal best -> no badge
      expect(find.text('¡Nuevo récord!'), findsNothing);

      // Buttons
      expect(find.widgetWithText(FilledButton, 'Jugar de nuevo'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Menú'), findsOneWidget);
    });

    testWidgets('renders personal best badge when isPersonalBest is true', (
      tester,
    ) async {
      final recordResult = GameResult(
        level: DifficultyLevel.easy,
        boardSize: 3,
        moves: 12,
        duration: const Duration(seconds: 45),
        outcome: GameOutcome.won,
        minSolutionDepth: 10,
        playedAt: DateTime(2026, 10, 17),
        isPersonalBest: true,
      );

      await tester.pumpWidget(
        createTestApp(
          overrides: [
            personalBestProvider(DifficultyLevel.easy).overrideWith(
              (ref) async => null,
            ),
          ],
          child: ResultPage(result: recordResult),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('¡Victoria!'), findsOneWidget);
      expect(find.text('¡Nuevo récord!'), findsOneWidget);
    });

    testWidgets('renders loss result with Derrota', (tester) async {
      final lossResult = GameResult(
        level: DifficultyLevel.hard,
        boardSize: 4,
        moves: 50,
        duration: const Duration(minutes: 4),
        outcome: GameOutcome.lost,
        minSolutionDepth: 40,
        playedAt: DateTime(2026, 10, 17),
        isPersonalBest: false,
      );

      await tester.pumpWidget(
        createTestApp(
          overrides: [
            personalBestProvider(DifficultyLevel.hard).overrideWith(
              (ref) async => null,
            ),
          ],
          child: ResultPage(result: lossResult),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Derrota'), findsOneWidget);
      expect(find.text('Nivel Difícil (4×4)'), findsOneWidget);
    });

    testWidgets('renders abandoned game with Partida abandonada', (
      tester,
    ) async {
      final abandonedResult = GameResult(
        level: DifficultyLevel.expert,
        boardSize: 5,
        moves: 15,
        duration: const Duration(minutes: 1),
        outcome: GameOutcome.abandoned,
        minSolutionDepth: 70,
        playedAt: DateTime(2026, 10, 17),
        isPersonalBest: false,
      );

      await tester.pumpWidget(
        createTestApp(
          overrides: [
            personalBestProvider(DifficultyLevel.expert).overrideWith(
              (ref) async => null,
            ),
          ],
          child: ResultPage(result: abandonedResult),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Partida abandonada'), findsOneWidget);
      expect(find.text('Nivel Experto (5×5)'), findsOneWidget);
    });
  });
}
