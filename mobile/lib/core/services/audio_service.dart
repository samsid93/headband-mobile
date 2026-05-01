import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class AudioService {
  final AudioPlayer _player = AudioPlayer();

  // Mapping of logical sound IDs to asset paths
  static const Map<String, String> _soundMap = {
    'tap': 'sounds/tap.mp3',
    'correct': 'sounds/correct.mp3',
    'skip': 'sounds/skip.mp3',
    'countdown': 'sounds/countdown.mp3',
    'go': 'sounds/go.mp3',
    'timeup': 'sounds/timeup.mp3',
  };

  Future<void> play(String soundId) async {
    try {
      final path = _soundMap[soundId];
      if (path != null) {
        // Stop current sound to play new one immediately
        await _player.stop();
        await _player.play(AssetSource(path));
      }
    } catch (e) {
      debugPrint('Audio error: $e');
    }
  }

  void dispose() {
    _player.dispose();
  }

  static const String tap = 'tap';
  static const String correct = 'correct';
  static const String skip = 'skip';
  static const String countdown = 'countdown';
  static const String go = 'go';
  static const String timeup = 'timeup';
}
