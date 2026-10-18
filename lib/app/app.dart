import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router.dart';

/// Root widget. TODO(frontend): light/dark themes from `theme/`, themeMode
/// from `settingsControllerProvider`, localized title.
class SlidingPuzzleApp extends ConsumerWidget {
  const SlidingPuzzleApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Sliding Puzzle',
      debugShowCheckedModeBanner: false,
      routerConfig: ref.watch(routerProvider),
    );
  }
}
