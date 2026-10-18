import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../core/services/feedback_service.dart';

/// Sounds via `audioplayers` (assets in `assets/sounds/`) + `HapticFeedback`.
/// Respects `configure()`, never throws, and on web plays only after user gesture.
class AudioFeedbackService implements FeedbackService {
  AudioFeedbackService({AudioPlayer? player}) {
    _player = player;
  }

  AudioPlayer? _player;
  bool _sound = true;
  bool _vibration = true;
  bool _hasUserGesture = !kIsWeb;

  AudioPlayer get _audioPlayer => _player ??= AudioPlayer();

  /// Call this when any user gesture occurs on web (e.g. pointer/tap event)
  void recordUserGesture() {
    _hasUserGesture = true;
  }

  @override
  Future<void> preload() async {
    try {
      if (!kIsWeb) {
        await AudioCache.instance.loadAll([
          'sounds/move.wav',
          'sounds/invalid.wav',
          'sounds/win.wav',
          'sounds/lose.wav',
        ]);
      }
    } catch (_) {
      // Feedback service must never throw.
    }
  }

  @override
  void configure({required bool sound, required bool vibration}) {
    _sound = sound;
    _vibration = vibration;
  }

  void _playSound(String assetPath) {
    if (!_sound) return;
    if (kIsWeb && !_hasUserGesture) return;
    try {
      _audioPlayer
          .stop()
          .then((_) {
            _audioPlayer.play(
              AssetSource(assetPath),
              mode: PlayerMode.lowLatency,
            );
          })
          .catchError((_) {});
    } catch (_) {
      // Never throw.
    }
  }

  @override
  void tileMoved() {
    _hasUserGesture = true;
    if (_vibration) {
      try {
        HapticFeedback.lightImpact();
      } catch (_) {}
    }
    _playSound('sounds/move.wav');
  }

  @override
  void invalidMove() {
    _hasUserGesture = true;
    if (_vibration) {
      try {
        HapticFeedback.heavyImpact();
      } catch (_) {}
    }
    _playSound('sounds/invalid.wav');
  }

  @override
  void gameWon() {
    _hasUserGesture = true;
    if (_vibration) {
      try {
        HapticFeedback.vibrate();
      } catch (_) {}
    }
    _playSound('sounds/win.wav');
  }

  @override
  void gameLost() {
    if (_vibration) {
      try {
        HapticFeedback.mediumImpact();
      } catch (_) {}
    }
    _playSound('sounds/lose.wav');
  }
}
