import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/game/data/repositories/hive_game_history_repository.dart';

/// Storage handles opened once at startup (awaited by the splash screen).
class AppDependencies {
  const AppDependencies({required this.historyBox, required this.prefs});

  final Box<Map<dynamic, dynamic>> historyBox;
  final SharedPreferences prefs;
}

Future<AppDependencies> bootstrapDependencies() async {
  await Hive.initFlutter();
  final historyBox = await Hive.openBox<Map<dynamic, dynamic>>(
    HiveGameHistoryRepository.boxName,
  );
  final prefs = await SharedPreferences.getInstance();
  return AppDependencies(historyBox: historyBox, prefs: prefs);
}
