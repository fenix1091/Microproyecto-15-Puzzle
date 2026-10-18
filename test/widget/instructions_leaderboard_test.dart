import 'package:flutter_test/flutter_test.dart';
import 'package:sliding_puzzle/features/game/domain/entities/difficulty_level.dart';
import 'package:sliding_puzzle/features/game/domain/entities/player_stats.dart';
import 'package:sliding_puzzle/features/instructions/presentation/instructions_page.dart';
import 'package:sliding_puzzle/features/leaderboard/application/leaderboard_providers.dart';
import 'package:sliding_puzzle/features/leaderboard/domain/entities/leaderboard_entry.dart';
import 'package:sliding_puzzle/features/leaderboard/presentation/leaderboard_page.dart';

import 'helpers/widget_test_helpers.dart';

void main() {
  group('InstructionsPage Widget Tests', () {
    testWidgets('renders rules, levels table, and back button labelled Volver', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestApp(
          child: const InstructionsPage(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('¿Cómo jugar?'), findsOneWidget);
      expect(find.text('Niveles de dificultad'), findsOneWidget);
      expect(find.text('Dificultad adaptativa'), findsOneWidget);
      expect(find.text('Fácil'), findsOneWidget);
      expect(find.text('Maestro'), findsOneWidget);

      expect(find.bySemanticsLabel('Volver'), findsOneWidget);
    });
  });

  group('LeaderboardPage Widget Tests', () {
    testWidgets('renders stats header and tabs for each level', (
      tester,
    ) async {
      const stats = PlayerStats(
        gamesPlayed: 10,
        wins: 8,
        averageTime: Duration(minutes: 1, seconds: 30),
        averageMoves: 25.0,
        winStreak: 3,
        lossStreak: 0,
        bestWinStreak: 5,
      );

      final easyEntries = [
        LeaderboardEntry(
          rank: 1,
          level: DifficultyLevel.easy,
          boardSize: 3,
          duration: const Duration(seconds: 45),
          moves: 14,
          playedAt: DateTime(2026, 10, 17),
        ),
      ];

      await tester.pumpWidget(
        createTestApp(
          overrides: [
            playerStatsProvider.overrideWith((ref) async => stats),
            leaderboardProvider(DifficultyLevel.easy).overrideWith(
              (ref) async => easyEntries,
            ),
            for (final lvl in DifficultyLevel.values.where(
              (l) => l != DifficultyLevel.easy,
            ))
              leaderboardProvider(lvl).overrideWith((ref) async => const []),
          ],
          child: const LeaderboardPage(),
        ),
      );
      await tester.pumpAndSettle();

      // Stats header
      expect(find.text('Partidas'), findsOneWidget);
      expect(find.text('10'), findsOneWidget);
      expect(find.text('Victorias'), findsOneWidget);
      expect(find.text('8 (80%)'), findsOneWidget);

      // Level tab and entry
      expect(find.text('#1'), findsOneWidget);
      expect(find.text('00:45'), findsOneWidget);
      expect(find.text('14 movimientos • 17/10/2026'), findsOneWidget);

      // Back button
      expect(find.bySemanticsLabel('Volver'), findsOneWidget);
    });
  });
}
