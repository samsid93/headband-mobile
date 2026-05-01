import 'package:speech_to_text/speech_to_text.dart';

enum VoiceAction { correct, skip, unknown }

class VoiceService {
  final SpeechToText _speech = SpeechToText();
  bool _isAvailable = false;

  final List<String> correctKeywords = [
    'correct', 'yes', 'yeah', 'yep', 'got it', 'right', 'done', 'nice'
  ];
  
  final List<String> skipKeywords = [
    'skip', 'next', 'no', 'pass', 'miss', 'blank'
  ];

  Future<bool> init() async {
    _isAvailable = await _speech.initialize();
    return _isAvailable;
  }

  void startListening(Function(VoiceAction, String) onAction) {
    if (!_isAvailable) return;

    _speech.listen(
      onResult: (result) {
        final text = result.recognizedWords.toLowerCase();
        if (correctKeywords.any((k) => text.contains(k))) {
          onAction(VoiceAction.correct, text);
        } else if (skipKeywords.any((k) => text.contains(k))) {
          onAction(VoiceAction.skip, text);
        } else {
          onAction(VoiceAction.unknown, text);
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      cancelOnError: true,
      partialResults: true,
    );
  }

  void stopListening() {
    _speech.stop();
  }
}
