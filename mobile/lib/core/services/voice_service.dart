import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';

enum VoiceAction { correct, skip, unknown }

class VoiceService {
  final SpeechToText _speech = SpeechToText();
  bool _isAvailable = false;
  Function(VoiceAction, String)? _onAction;

  final List<String> correctKeywords = [
    'correct', 'yes', 'yeah', 'yep', 'got it', 'right', 'done', 'nice'
  ];
  
  final List<String> skipKeywords = [
    'skip', 'next', 'no', 'pass', 'miss', 'blank'
  ];

  Future<bool> init() async {
    _isAvailable = await _speech.initialize(
      onError: (e) => debugPrint('Speech error: $e'),
      onStatus: (s) => debugPrint('Speech status: $s'),
    );
    return _isAvailable;
  }

  void startListening(Function(VoiceAction, String) onAction) {
    _onAction = onAction;
    if (!_isAvailable) return;

    _speech.listen(
      onResult: (result) {
        if (result.finalResult) {
          final text = result.recognizedWords.toLowerCase();
          _processText(text);
        }
      },
      partialResults: false, // Wait for final result for better accuracy
    );
  }

  void _processText(String text) {
    if (_onAction == null) return;
    
    if (correctKeywords.any((k) => text.contains(k))) {
      _onAction!(VoiceAction.correct, text);
    } else if (skipKeywords.any((k) => text.contains(k))) {
      _onAction!(VoiceAction.skip, text);
    } else {
      _onAction!(VoiceAction.unknown, text);
    }
  }

  void stopListening() {
    _speech.stop();
  }
}
