import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sliding_puzzle/app/theme/app_theme.dart';
import 'package:sliding_puzzle/features/game/application/game_controller.dart';
import 'package:sliding_puzzle/features/game/application/game_state.dart';
import 'package:sliding_puzzle/features/game/domain/entities/board.dart';
import 'package:sliding_puzzle/features/game/domain/entities/difficulty_config.dart';
import 'package:sliding_puzzle/features/game/domain/entities/difficulty_level.dart';
import 'package:sliding_puzzle/features/game/domain/entities/game_session.dart';
import 'package:sliding_puzzle/features/game/presentation/pages/game_page.dart';
import 'package:sliding_puzzle/features/menu/presentation/menu_page.dart';

import 'helpers/widget_test_helpers.dart';

void main() {
  group('MED-004 Responsive & Overflow Matrix Tests', () {
    const standardViewports = [
      ('320x568 mobile portrait', Size(320, 568)),
      ('360x640 mobile portrait', Size(360, 640)),
      ('568x320 mobile landscape', Size(568, 320)),
      ('640x360 mobile landscape', Size(640, 360)),
      ('844x390 mobile landscape', Size(844, 390)),
      ('1440x900 desktop', Size(1440, 900)),
      ('2560x1440 desktop large', Size(2560, 1440)),
    ];

    for (final (label, size) in standardViewports) {
      for (final (themeLabel, themeData) in [
        ('Light', AppTheme.lightTheme),
        ('Dark', AppTheme.darkTheme),
      ]) {
        testWidgets(
          'MenuPage renders without overflow on $label ($themeLabel)',
          (tester) async {
            tester.view.physicalSize = size;
            tester.view.devicePixelRatio = 1.0;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);

            await tester.pumpWidget(
              createTestApp(
                child: Theme(data: themeData, child: const MenuPage()),
              ),
            );
            await tester.pumpAndSettle();

            expect(tester.takeException(), isNull);
            expect(find.byType(MenuPage), findsOneWidget);
          },
        );

        testWidgets(
          'GamePage (3x3) renders without overflow on $label ($themeLabel)',
          (tester) async {
            tester.view.physicalSize = size;
            tester.view.devicePixelRatio = 1.0;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);

            final fakeController = FakeGameController();

            await tester.pumpWidget(
              createTestApp(
                overrides: [
                  gameControllerProvider.overrideWith(() => fakeController),
                ],
                child: Theme(data: themeData, child: const GamePage()),
              ),
            );
            await tester.pumpAndSettle();

            expect(tester.takeException(), isNull);
            expect(find.byType(GamePage), findsOneWidget);
          },
        );
      }
    }

    // High text scale (TextScaler.linear(2.0))
    const textScaleViewports = [
      ('320x568 mobile portrait (2.0 text scale)', Size(320, 568)),
      ('360x640 mobile portrait (2.0 text scale)', Size(360, 640)),
    ];

    for (final (label, size) in textScaleViewports) {
      testWidgets('GamePage renders without overflow on $label', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final fakeController = FakeGameController();

        await tester.pumpWidget(
          createTestApp(
            overrides: [
              gameControllerProvider.overrideWith(() => fakeController),
            ],
            child: const MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(2.0)),
              child: GamePage(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(GamePage), findsOneWidget);
      });
    }

    // 6x6 Board across mobile and desktop
    testWidgets(
      'GamePage (6x6 board) renders without overflow on mobile portrait, landscape, desktop',
      (tester) async {
        final board6x6 = Board.solved(6);
        final gameState6x6 = GameState(
          session: GameSession(
            initialBoard: board6x6,
            board: board6x6,
            config: DifficultyConfig.base(DifficultyLevel.expert),
            moves: 42,
            elapsed: const Duration(minutes: 3, seconds: 15),
            status: GameStatus.playing,
          ),
        );

        for (final size in [
          const Size(360, 640),
          const Size(640, 360),
          const Size(1440, 900),
        ]) {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          final fakeController = FakeGameController(initialState: gameState6x6);

          await tester.pumpWidget(
            createTestApp(
              overrides: [
                gameControllerProvider.overrideWith(() => fakeController),
              ],
              child: const GamePage(),
            ),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(find.byType(GamePage), findsOneWidget);
        }
      },
    );
  });
}
