import 'package:speech_to_text/speech_to_text.dart';
import 'dart:async';

class VoiceService {
  final SpeechToText _speech = SpeechToText();
  bool _isAvailable = false;
  bool _isListening = false;
  Function(String)? _onResult;

  Future<bool> init() async {
    _isAvailable = await _speech.initialize(
      onError: (val) => print('Speech Error: $val'),
      onStatus: (val) {
        if (val == 'done' || val == 'notListening') {
          _isListening = false;
          // Restart listening if we still want to be active
          if (_onResult != null) _startInternal();
        }
      },
    );
    return _isAvailable;
  }

  void startListening(Function(String) onResult) {
    _onResult = onResult;
    if (_isAvailable && !_isListening) {
      _startInternal();
    }
  }

  void _startInternal() {
    _isListening = true;
    _speech.listen(
      onResult: (result) {
        if (result.finalResult) {
          _onResult?.call(result.recognizedWords);
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 5),
      cancelOnError: false,
      partialResults: true,
    );
  }

  void stopListening() {
    _onResult = null;
    _isListening = false;
    _speech.stop();
  }
}
