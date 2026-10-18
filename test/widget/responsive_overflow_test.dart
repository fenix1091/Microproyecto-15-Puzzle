import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sliding_puzzle/app/theme/app_theme.dart';
import 'package:sliding_puzzle/features/game/application/game_controller.dart';
import 'package:sliding_puzzle/features/game/presentation/pages/game_page.dart';
import 'package:sliding_puzzle/features/menu/presentation/menu_page.dart';

import 'helpers/widget_test_helpers.dart';

void main() {
  group('Responsive & Overflow Tests (360x640 mobile and 1440x900 desktop)', () {
    const mobileSize = Size(360, 640);
    const desktopSize = Size(1440, 900);

    for (final (label, size) in [
      ('360x640 mobile', mobileSize),
      ('1440x900 desktop', desktopSize),
    ]) {
      for (final (themeLabel, themeData) in [
        ('Light', AppTheme.lightTheme),
        ('Dark', AppTheme.darkTheme),
      ]) {
        testWidgets('MenuPage renders without overflow on $label ($themeLabel)', (
          tester,
        ) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(
            createTestApp(
              child: Theme(
                data: themeData,
                child: const MenuPage(),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(find.byType(MenuPage), findsOneWidget);
        });

        testWidgets('GamePage renders without overflow on $label ($themeLabel)', (
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
              child: Theme(
                data: themeData,
                child: const GamePage(),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(find.byType(GamePage), findsOneWidget);
        });
      }
    }
  });
}
