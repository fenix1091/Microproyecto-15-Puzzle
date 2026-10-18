import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sliding_puzzle/features/game/domain/entities/difficulty_decision.dart';
import 'package:sliding_puzzle/features/game/domain/entities/difficulty_level.dart';
import 'package:sliding_puzzle/features/leaderboard/application/leaderboard_providers.dart';
import 'package:sliding_puzzle/features/menu/presentation/menu_page.dart';
import 'package:sliding_puzzle/features/settings/domain/entities/user_settings.dart';

import 'helpers/widget_test_helpers.dart';

void main() {
  group('MenuPage Widget Tests', () {
    testWidgets('displays all 4 required buttons with exact labels', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestApp(
          child: const MenuPage(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.widgetWithText(FilledButton, 'Jugar'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Marcadores'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Configuración'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Instrucciones'), findsOneWidget);
    });

    testWidgets('shows adaptive level and trend promotion', (tester) async {
      const decision = DifficultyDecision(
        level: DifficultyLevel.easy,
        trend: DifficultyTrend.promoted,
      );

      await tester.pumpWidget(
        createTestApp(
          settings: const UserSettings(
            adaptiveDifficulty: true,
            currentLevel: DifficultyLevel.easy,
          ),
          overrides: [
            nextDifficultyProvider(DifficultyLevel.easy).overrideWith(
              (ref) async => decision,
            ),
          ],
          child: const MenuPage(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Nivel actual'), findsOneWidget);
      expect(find.text('Adaptativo'), findsOneWidget);
      expect(find.text('Fácil'), findsOneWidget);
      expect(find.text('↑ En ascenso'), findsOneWidget);
    });

    testWidgets('shows manual mode and manual level', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          settings: const UserSettings(
            adaptiveDifficulty: false,
            manualLevel: DifficultyLevel.hard,
          ),
          child: const MenuPage(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Manual'), findsOneWidget);
      expect(find.text('Difícil'), findsOneWidget);
    });
  });
}
