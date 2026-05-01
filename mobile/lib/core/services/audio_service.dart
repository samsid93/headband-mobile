import 'package:audioplayers/audioplayers.dart';

class AudioService {
  final AudioPlayer _player = AudioPlayer();

  // Sounds (In a real app, these would be local assets)
  static const String tap = 'sounds/tap.mp3';
  static const String correct = 'sounds/correct.mp3';
  static const String skip = 'sounds/skip.mp3';
  static const String countdown = 'sounds/countdown.mp3';
  static const String go = 'sounds/go.mp3';
  static const String timeup = 'sounds/timeup.mp3';

  Future<void> play(String assetPath) async {
    await _player.stop();
    await _player.play(AssetSource(assetPath));
  }

  void dispose() {
    _player.dispose();
  }
}
