import 'package:audioplayers/audioplayers.dart';

class AudioService {
  final AudioPlayer _player = AudioPlayer();

  Future<void> playSfx(String assetPath) async {
    await _player.play(AssetSource(assetPath));
  }

  // Helper methods for game events
  Future<void> playTap() async => await playSfx('sounds/tap.wav');
  Future<void> playCorrect() async => await playSfx('sounds/correct.wav');
  Future<void> playSkip() async => await playSfx('sounds/skip.wav');
  Future<void> playCountdown() async => await playSfx('sounds/countdown.wav');
  Future<void> playGo() async => await playSfx('sounds/go.wav');
  Future<void> playTick() async => await playSfx('sounds/tick.wav');
}
