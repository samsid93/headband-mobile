import 'dart:async';
import 'package:flutter/foundation.dart';
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

  // Settings
  String selectedDeckId = 'movies';
  int roundDuration = 60;
  bool skipDeduct = false;
  bool voiceEnabled = false;
  bool tiltEnabled = true;
  String mode = 'classic'; // 'classic' or 'team'

  // Game State
  GameState state = GameState.home;
  List<WordCard> currentWords = [];
  int wordIndex = 0;
  int secondsRemaining = 60;
  int scoreCorrect = 0;
  int scoreSkipped = 0;
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
    notifyListeners();
  }

  void startRound() {
    currentWords = List.from(selectedDeck.words)..shuffle();
    wordIndex = 0;
    scoreCorrect = 0;
    scoreSkipped = 0;
    secondsRemaining = roundDuration;
    
    setGameState(GameState.countdown);
    _startCountdown();
  }

  void _startCountdown() {
    int count = 3;
    Timer.periodic(const Duration(seconds: 1), (t) {
      if (count == 0) {
        t.cancel();
        _beginGameplay();
      } else {
        _audio.play(AudioService.countdown);
        count--;
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
      });
    }

    if (voiceEnabled) {
      _voice.startListening((action, text) {
        if (action == VoiceAction.correct) handleCorrect();
        if (action == VoiceAction.skip) handleSkip();
      });
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (secondsRemaining == 0) {
        endRound();
      } else {
        secondsRemaining--;
        if (secondsRemaining <= 10) _audio.play(AudioService.countdown);
        notifyListeners();
      }
    });
  }

  void handleCorrect() {
    scoreCorrect++;
    _audio.play(AudioService.correct);
    _nextWord();
  }

  void handleSkip() {
    scoreSkipped++;
    _audio.play(AudioService.skip);
    _nextWord();
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
