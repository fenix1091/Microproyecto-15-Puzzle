import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sliding_puzzle/app/app.dart';
import 'package:sliding_puzzle/app/di/providers.dart';
import 'package:sliding_puzzle/core/utils/random_source.dart';
import 'package:sliding_puzzle/features/game/domain/entities/board.dart';
import 'package:sliding_puzzle/features/game/domain/entities/difficulty_config.dart';
import 'package:sliding_puzzle/features/game/domain/services/shuffler.dart';
import 'package:sliding_puzzle/features/leaderboard/application/leaderboard_providers.dart';
import 'package:sliding_puzzle/features/settings/application/settings_controller.dart';

/// Leaves the board one move from solved: the last tile sits left of its
/// home cell, so tapping the bottom-right corner wins.
class _OneMoveShuffler extends Shuffler {
  _OneMoveShuffler() : super(DartRandomSource(1));

  @override
  Board shuffle(DifficultyConfig config) {
    final n = config.boardSize;
    final tiles = Board.solved(n).tiles.toList();
    final last = tiles.length - 1;
    tiles[last] = tiles[last - 1];
    tiles[last - 1] = 0;
    return Board(size: n, tiles: tiles);
  }
}

/// `pumpAndSettle` never settles on screens with looping animations.
Future<void> pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 20),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) return;
  }
  throw TestFailure('Not found within $timeout: $finder');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('splash → menu → win a game → record saved', (tester) async {
    final container = ProviderContainer(
      overrides: [shufflerProvider.overrideWithValue(_OneMoveShuffler())],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const SlidingPuzzleApp(),
      ),
    );

    await pumpUntilFound(tester, find.text('Jugar'));
    // Fresh browser profile: no history, so the adaptive engine keeps the
    // stored level.
    final settings = container.read(settingsControllerProvider).requireValue;
    final played = settings.adaptiveDifficulty
        ? settings.currentLevel
        : settings.manualLevel;
    final size = DifficultyConfig.base(played).boardSize;

    await tester.tap(find.text('Jugar'));
    final winningTile = find.bySemanticsLabel(
      RegExp('^Ficha ${size * size - 1}, fila $size, columna $size'),
    );
    await pumpUntilFound(tester, winningTile);
    await tester.tap(winningTile);

    await pumpUntilFound(tester, find.text('Jugar de nuevo'));

    final top = await container.read(leaderboardProvider(played).future);
    expect(top, isNotEmpty);
  });
}
