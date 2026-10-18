import '../../core/services/feedback_service.dart';

/// Sounds via `audioplayers` (assets in `assets/sounds/`) + `HapticFeedback`.
/// TODO(frontend): implement; on web, play only after a user gesture.
class AudioFeedbackService implements FeedbackService {
  @override
  Future<void> preload() async {}

  @override
  void configure({required bool sound, required bool vibration}) {}

  @override
  void tileMoved() {}

  @override
  void invalidMove() {}

  @override
  void gameWon() {}

  @override
  void gameLost() {}
}
