/// Sound + haptic feedback. Implementations must respect the user's
/// sound/vibration settings and never throw (feedback is optional).
abstract interface class FeedbackService {
  /// Loads sounds; called from the splash screen.
  Future<void> preload();

  void configure({required bool sound, required bool vibration});

  void tileMoved();
  void invalidMove();
  void gameWon();
  void gameLost();
}

class NoopFeedbackService implements FeedbackService {
  const NoopFeedbackService();

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
