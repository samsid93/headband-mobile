import 'package:flutter/material.dart';

class GameProvider extends ChangeNotifier {
  String mode = 'classic';
  String deck = 'movies';
  int timer = 60;
  bool skipDeduct = false;
  bool voiceEnabled = false;
  bool tiltEnabled = true;

  List<String> unlockedDecks = [];

  void setMode(String m) {
    mode = m;
    notifyListeners();
  }

  void setDeck(String d) {
    deck = d;
    notifyListeners();
  }

  void setTimer(int t) {
    timer = t;
    notifyListeners();
  }

  void toggleTilt(bool v) {
    tiltEnabled = v;
    notifyListeners();
  }

  void toggleVoice(bool v) {
    voiceEnabled = v;
    notifyListeners();
  }

  void toggleSkipDeduct(bool v) {
    skipDeduct = v;
    notifyListeners();
  }

  void unlockDeck(String id) {
    unlockedDecks.add(id);
    notifyListeners();
  }
}
