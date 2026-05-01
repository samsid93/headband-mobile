import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import '../data/models/game_models.dart';
import '../data/mock_data.dart';
import '../core/services/audio_service.dart';
import '../core/services/sensor_service.dart';
import '../core/services/voice_service.dart';

enum GameState { home, setup, teams, ready, countdown, playing, score }

class GameProvider with ChangeNotifier {
  final AudioService _audio = AudioService();
  final SensorService _sensors = SensorService();
  final VoiceService _voice = VoiceService();

  // Settings with proper setters
  String _selectedDeckId = 'movies';
  String get selectedDeckId => _selectedDeckId;
  set selectedDeckId(String val) { _selectedDeckId = val; notifyListeners(); }

  int _roundDuration = 60;
  int get roundDuration => _roundDuration;
  set roundDuration(int val) { _roundDuration = val; notifyListeners(); }

  bool _skipDeduct = false;
  bool get skipDeduct => _skipDeduct;
  set skipDeduct(bool val) { _skipDeduct = val; notifyListeners(); }

  bool _voiceEnabled = false;
  bool get voiceEnabled => _voiceEnabled;
  set voiceEnabled(bool val) { _voiceEnabled = val; notifyListeners(); }

  bool _tiltEnabled = true;
  bool get tiltEnabled => _tiltEnabled;
  set tiltEnabled(bool val) { _tiltEnabled = val; notifyListeners(); }

  String _mode = 'classic';
  String get mode => _mode;
  set mode(String val) { _mode = val; notifyListeners(); }

  // Game State
  GameState state = GameState.home;
  List<WordCard> currentWords = [];
  int wordIndex = 0;
  int secondsRemaining = 60;
  int countdownValue = 3;
  int scoreCorrect = 0;
  int scoreSkipped = 0;
  String? lastAction; // 'correct', 'skip'
  double rawY = 0; // Current tilt value
  Timer? _timer;

  // Teams
  List<String> teamNames = ['Team 1', 'Team 2'];
  List<int> teamScores = [0, 0];
  int currentTeamIndex = 0;

  Deck get selectedDeck => DECKS.firstWhere((d) => d.id == selectedDeckId);
  WordCard get currentWord => currentWords[wordIndex];

  void setGameState(GameState newState) {
    state = newState;
    notifyListeners();
  }

  void selectDeck(String id) {
    selectedDeckId = id;
  }

  Future<void> startRound() async {
    currentWords = List.from(selectedDeck.words)..shuffle();
    wordIndex = 0;
    scoreCorrect = 0;
    scoreSkipped = 0;
    secondsRemaining = roundDuration;
    lastAction = null;
    
    // Voice setup
    if (voiceEnabled) {
      var status = await Permission.microphone.request();
      if (status.isGranted) {
        await _voice.init();
      } else {
        voiceEnabled = false;
      }
    }

    setGameState(GameState.countdown);
    _startCountdown();
  }

  void _startCountdown() {
    countdownValue = 3;
    notifyListeners();
    
    Timer.periodic(const Duration(seconds: 1), (t) {
      if (countdownValue == 0) {
        t.cancel();
        _beginGameplay();
      } else {
        _audio.play(AudioService.countdown);
        countdownValue--;
        notifyListeners();
      }
    });
  }

  void _beginGameplay() {
    setGameState(GameState.playing);
    _audio.play(AudioService.go);
    
    if (tiltEnabled) {
      _sensors.startListening((dir) {
        if (dir == TiltDirection.correct) handleCorrect();
        if (dir == TiltDirection.skip) handleSkip();
      }, onRawY: (y) {
        rawY = y;
        notifyListeners();
      });
    }

    if (voiceEnabled) {
      _voice.startListening((action, text) {
        if (action == VoiceAction.correct) {
          handleCorrect();
        } else if (action == VoiceAction.skip) {
          handleSkip();
        } else {
          // Unknown word — update lastAction to notify UI
          lastAction = 'unknown';
          notifyListeners();
          Future.delayed(const Duration(milliseconds: 1000), () {
            lastAction = null;
            notifyListeners();
          });
        }
      });
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (secondsRemaining == 0) {
        endRound();
      } else {
        secondsRemaining--;
        if (secondsRemaining <= 3 && secondsRemaining > 0) _audio.play(AudioService.countdown);
        if (secondsRemaining == 10) _audio.play(AudioService.countdown); // 10s warning
        notifyListeners();
      }
    });
  }

  void handleCorrect() {
    if (state != GameState.playing) return;
    scoreCorrect++;
    _audio.play(AudioService.correct);
    lastAction = 'correct';
    notifyListeners();
    
    Future.delayed(const Duration(milliseconds: 500), () {
      lastAction = null;
      _nextWord();
    });
  }

  void handleSkip() {
    if (state != GameState.playing) return;
    scoreSkipped++;
    _audio.play(AudioService.skip);
    lastAction = 'skip';
    notifyListeners();

    Future.delayed(const Duration(milliseconds: 500), () {
      lastAction = null;
      _nextWord();
    });
  }

  void _nextWord() {
    if (wordIndex < currentWords.length - 1) {
      wordIndex++;
      notifyListeners();
    } else {
      endRound();
    }
  }

  void endRound() {
    _timer?.cancel();
    _sensors.stopListening();
    _voice.stopListening();
    _audio.play(AudioService.timeup);

    int finalPoints = skipDeduct ? (scoreCorrect - scoreSkipped).clamp(0, 100) : scoreCorrect;
    if (mode == 'team') {
      teamScores[currentTeamIndex] += finalPoints;
    }

    setGameState(GameState.score);
  }

  void reset() {
    state = GameState.home;
    teamScores = [0, 0];
    currentTeamIndex = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audio.dispose();
    _sensors.stopListening();
    _voice.stopListening();
    super.dispose();
  }
}
