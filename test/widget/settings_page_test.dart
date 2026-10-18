import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sliding_puzzle/features/settings/application/settings_controller.dart';
import 'package:sliding_puzzle/features/settings/domain/entities/user_settings.dart';
import 'package:sliding_puzzle/features/settings/presentation/settings_page.dart';

import 'helpers/widget_test_helpers.dart';

void main() {
  group('SettingsPage Widget Tests', () {
    testWidgets('toggling sound calls change() on settings controller', (
      tester,
    ) async {
      final fakeSettings = FakeSettingsController(
        initial: const UserSettings(soundEnabled: true),
      );

      await tester.pumpWidget(
        createTestApp(
          overrides: [
            settingsControllerProvider.overrideWith(() => fakeSettings),
          ],
          child: const SettingsPage(),
        ),
      );
      await tester.pumpAndSettle();

      final soundSwitch = find.widgetWithText(SwitchListTile, 'Sonido');
      expect(soundSwitch, findsOneWidget);

      await tester.tap(soundSwitch);
      await tester.pumpAndSettle();

      expect(fakeSettings.changeCalls.isNotEmpty, isTrue);
      final updated = fakeSettings.changeCalls.last(const UserSettings());
      expect(updated.soundEnabled, isFalse);
    });

    testWidgets('toggling vibration calls change() on settings controller', (
      tester,
    ) async {
      final fakeSettings = FakeSettingsController(
        initial: const UserSettings(vibrationEnabled: true),
      );

      await tester.pumpWidget(
        createTestApp(
          overrides: [
            settingsControllerProvider.overrideWith(() => fakeSettings),
          ],
          child: const SettingsPage(),
        ),
      );
      await tester.pumpAndSettle();

      final vibrationSwitch = find.widgetWithText(SwitchListTile, 'Vibración');
      expect(vibrationSwitch, findsOneWidget);

      await tester.tap(vibrationSwitch);
      await tester.pumpAndSettle();

      expect(fakeSettings.changeCalls.isNotEmpty, isTrue);
      final updated = fakeSettings.changeCalls.last(const UserSettings());
      expect(updated.vibrationEnabled, isFalse);
    });

    testWidgets(
      'toggling adaptive difficulty calls change() on settings controller',
      (tester) async {
        final fakeSettings = FakeSettingsController(
          initial: const UserSettings(adaptiveDifficulty: true),
        );

        await tester.pumpWidget(
          createTestApp(
            overrides: [
              settingsControllerProvider.overrideWith(() => fakeSettings),
            ],
            child: const SettingsPage(),
          ),
        );
        await tester.pumpAndSettle();

        final adaptiveSwitch = find.widgetWithText(
          SwitchListTile,
          'Dificultad adaptativa',
        );
        await tester.ensureVisible(adaptiveSwitch);
        await tester.tap(adaptiveSwitch);
        await tester.pumpAndSettle();

        expect(fakeSettings.changeCalls.isNotEmpty, isTrue);
        final updated = fakeSettings.changeCalls.last(const UserSettings());
        expect(updated.adaptiveDifficulty, isFalse);
      },
    );

    testWidgets(
      'toggling reduce motion calls change() on settings controller',
      (tester) async {
        final fakeSettings = FakeSettingsController(
          initial: const UserSettings(reduceMotion: false),
        );

        await tester.pumpWidget(
          createTestApp(
            overrides: [
              settingsControllerProvider.overrideWith(() => fakeSettings),
            ],
            child: const SettingsPage(),
          ),
        );
        await tester.pumpAndSettle();

        final motionSwitch = find.widgetWithText(
          SwitchListTile,
          'Reducir animaciones',
        );
        expect(motionSwitch, findsOneWidget);

        await tester.tap(motionSwitch);
        await tester.pumpAndSettle();

        expect(fakeSettings.changeCalls.isNotEmpty, isTrue);
        final updated = fakeSettings.changeCalls.last(const UserSettings());
        expect(updated.reduceMotion, isTrue);
      },
    );

    testWidgets('changing theme segment calls change() on settings controller', (
      tester,
    ) async {
      final fakeSettings = FakeSettingsController(
        initial: const UserSettings(themeMode: AppThemeMode.system),
      );

      await tester.pumpWidget(
        createTestApp(
          overrides: [
            settingsControllerProvider.overrideWith(() => fakeSettings),
          ],
          child: const SettingsPage(),
        ),
      );
      await tester.pumpAndSettle();

      final darkSegment = find.text('Oscuro');
      expect(darkSegment, findsOneWidget);

      await tester.tap(darkSegment);
      await tester.pumpAndSettle();

      expect(fakeSettings.changeCalls.isNotEmpty, isTrue);
      final updated = fakeSettings.changeCalls.last(const UserSettings());
      expect(updated.themeMode, equals(AppThemeMode.dark));
    });

    testWidgets('back button labelled Volver exists', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const SettingsPage(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('Volver'), findsOneWidget);
    });
  });
}
