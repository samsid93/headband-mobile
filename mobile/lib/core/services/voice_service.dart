import 'package:speech_to_text/speech_to_text.dart';

class VoiceService {
  final SpeechToText _speech = SpeechToText();
  bool _isAvailable = false;

  Future<bool> init() async {
    _isAvailable = await _speech.initialize();
    return _isAvailable;
  }

  void startListening(Function(String) onResult) {
    if (_isAvailable) {
      _speech.listen(onResult: (result) {
        if (result.finalResult) {
          onResult(result.recognizedWords);
        }
      });
    }
  }

  void stopListening() {
    _speech.stop();
  }
}
