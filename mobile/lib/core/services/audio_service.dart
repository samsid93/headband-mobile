import 'package:audioplayers/audioplayers.dart';

class AudioService {
  // Use separate players for concurrent sounds to prevent blocking/lag
  final AudioPlayer _uiPlayer = AudioPlayer();      // For beeps, skips, taps
  final AudioPlayer _ambientPlayer = AudioPlayer(); // For ticking clock, countdowns

  Future<void> _play(AudioPlayer player, String asset) async {
    try {
      await player.stop(); // Interrupt previous sound on this channel
      await player.play(AssetSource(asset));
    } catch (e) {
      print('Audio Error: $e');
    }
  }

  // Action sounds (Channel 1)
  Future<void> playTap() async => await _play(_uiPlayer, 'sounds/tap.wav');
  Future<void> playCorrect() async => await _play(_uiPlayer, 'sounds/correct.wav');
  Future<void> playSkip() async => await _play(_uiPlayer, 'sounds/skip.wav');
  Future<void> playGo() async => await _play(_uiPlayer, 'sounds/go.wav');

  // Ambient sounds (Channel 2)
  Future<void> playCountdown() async => await _play(_ambientPlayer, 'sounds/countdown.wav');
  Future<void> playTick() async => await _play(_ambientPlayer, 'sounds/tick.wav');

  void dispose() {
    _uiPlayer.dispose();
    _ambientPlayer.dispose();
  }
}
