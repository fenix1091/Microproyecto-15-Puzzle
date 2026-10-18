import 'package:flutter/foundation.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/di/providers.dart';
import 'core/config/app_env.dart';
import 'shared/services/audio_feedback_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb && AppEnv.qa) {
    // Flutter web paints to a canvas; this exposes the semantics tree as
    // DOM nodes so Playwright can find widgets by role and label.
    SemanticsBinding.instance.ensureSemantics();
  }
  runApp(
    ProviderScope(
      overrides: [
        feedbackServiceProvider.overrideWithValue(AudioFeedbackService()),
      ],
      child: const SlidingPuzzleApp(),
    ),
  );
}
