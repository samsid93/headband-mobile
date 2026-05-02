import 'dart:async';
import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';
import '../data/models/game_models.dart';
import '../data/mock_data.dart';
import '../core/services/audio_service.dart';
import '../core/services/sensor_service.dart';
import '../core/services/voice_service.dart';
import '../core/services/leaderboard_service.dart';

enum GameState { idle, countdown, playing, score }

class GameProvider extends ChangeNotifier {
  // Services
  final AudioService _audio = AudioService();
  late SensorService _sensor;
  late VoiceService _voice;

  // Settings
  String _mode = 'classic';
  String _selectedDeckId = 'movies';
  int _roundDuration = 60;
  bool _skipDeduct = false;
  bool _voiceEnabled = false;
  bool _tiltEnabled = true;
  List<String> _unlockedDeckIds = [];
  Map<int, String> _teamNames = {0: 'Team 1', 1: 'Team 2'};

  // Game State
  GameState _state = GameState.idle;
  int _countdownValue = 3;
  int _secondsRemaining = 60;
  int _scoreCorrect = 0;
  int _scoreSkipped = 0;
  int _currentTeamIndex = 0;
  List<WordCard> _remainingWords = [];
  WordCard? _currentWord;
  String? _lastAction; // 'correct', 'skip', 'unknown'
  double _rawY = 0;
  bool _isCoolingDown = false;
  Timer? _gameTimer;

  GameProvider() {
    _sensor = SensorService(onTilt: _handleTilt);
    _voice = VoiceService();
  }

  // Getters
  String get mode => _mode;
  String get selectedDeckId => _selectedDeckId;
  int get roundDuration => _roundDuration;
  bool get skipDeduct => _skipDeduct;
  bool get voiceEnabled => _voiceEnabled;
  bool get tiltEnabled => _tiltEnabled;
  GameState get state => _state;
  int get countdownValue => _countdownValue;
  int get secondsRemaining => _secondsRemaining;
  int get scoreCorrect => _scoreCorrect;
  int get scoreSkipped => _scoreSkipped;
  int get currentTeamIndex => _currentTeamIndex;
  WordCard get currentWord => _currentWord ?? WordCard(word: 'ERROR', hint: '');
  Deck get selectedDeck => DECKS.firstWhere((d) => d.id == _selectedDeckId);
  String? get lastAction => _lastAction;
  double get rawY => _rawY;
  Map<int, String> get teamNames => _teamNames;

  // Setters
  set mode(String val) { _mode = val; notifyListeners(); }
  set selectedDeckId(String val) { _selectedDeckId = val; notifyListeners(); }
  set roundDuration(int val) { _roundDuration = val; notifyListeners(); }
  set skipDeduct(bool val) { _skipDeduct = val; notifyListeners(); }
  set voiceEnabled(bool val) { _voiceEnabled = val; notifyListeners(); }
  set tiltEnabled(bool val) { _tiltEnabled = val; notifyListeners(); }

  void setTeamName(int index, String name) {
    _teamNames[index] = name;
    notifyListeners();
  }

  // Actions
  void startRound() {
    _state = GameState.countdown;
    _countdownValue = 3;
    _scoreCorrect = 0;
    _scoreSkipped = 0;
    _secondsRemaining = _roundDuration;
    _remainingWords = List.from(selectedDeck.words)..shuffle();
    _nextWord();
    notifyListeners();

    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdownValue > 1) {
        _countdownValue--;
        _audio.playCountdown();
        notifyListeners();
      } else if (_countdownValue == 1) {
        _countdownValue = 0;
        _audio.playGo();
        _state = GameState.playing;
        _startGameplayTimer();
        if (_tiltEnabled) _sensor.start();
        if (_voiceEnabled) _initVoice();
        timer.cancel();
        notifyListeners();
      }
    });
  }

  void _startGameplayTimer() {
    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        _secondsRemaining--;
        if (_secondsRemaining < 10) _audio.playTick();
        notifyListeners();
      } else {
        _endRound();
        timer.cancel();
      }
    });
  }

  void _nextWord() {
    if (_remainingWords.isEmpty) {
      _remainingWords = List.from(selectedDeck.words)..shuffle();
    }
    _currentWord = _remainingWords.removeAt(0);
  }

  void handleCorrect() async {
    if (_state != GameState.playing || _isCoolingDown) return;
    _scoreCorrect++;
    _triggerActionFeedback('correct');
    _audio.playCorrect();
    if (await Vibration.hasVibrator() ?? false) Vibration.vibrate(duration: 100);
    _nextWord();
    notifyListeners();
  }

  void handleSkip() async {
    if (_state != GameState.playing || _isCoolingDown) return;
    _scoreSkipped++;
    _triggerActionFeedback('skip');
    _audio.playSkip();
    if (await Vibration.hasVibrator() ?? false) Vibration.vibrate(duration: 300);
    _nextWord();
    notifyListeners();
  }

  void _triggerActionFeedback(String action) {
    _lastAction = action;
    _isCoolingDown = true;
    notifyListeners();
    Timer(const Duration(milliseconds: 600), () {
      _lastAction = null;
      _isCoolingDown = false;
      notifyListeners();
    });
  }

  void _handleTilt(double x, double y, double z) {
    _rawY = y;
    if (_state != GameState.playing || _isCoolingDown) {
      notifyListeners();
      return;
    }
    if (y > 5.0) handleSkip();
    else if (y < -5.0) handleCorrect();
    else notifyListeners();
  }

  void _initVoice() async {
    bool available = await _voice.init();
    if (available) {
      _voice.startListening((text) {
        final lower = text.toLowerCase();
        if (lower.contains('correct') || lower.contains('yes')) handleCorrect();
        else if (lower.contains('skip') || lower.contains('next')) handleSkip();
        else {
          _lastAction = 'unknown';
          notifyListeners();
          Timer(const Duration(seconds: 1), () {
            _lastAction = null;
            notifyListeners();
          });
        }
      });
    }
  }

  void _endRound() async {
    _state = GameState.score;
    _gameTimer?.cancel();
    _sensor.stop();
    _voice.stopListening();
    
    final service = LeaderboardService();
    await service.saveEntry(LeaderboardEntry(
      deck: selectedDeck.name,
      score: _skipDeduct ? (_scoreCorrect - _scoreSkipped).clamp(0, 100) : _scoreCorrect,
      date: DateTime.now().toString().split('.')[0],
    ));
    
    notifyListeners();
  }

  void reset() {
    _state = GameState.idle;
    if (_mode == 'team') _currentTeamIndex = 1 - _currentTeamIndex;
    notifyListeners();
  }

  void unlockDeck(String id) {
    _unlockedDeckIds.add(id);
    notifyListeners();
  }

  bool isDeckUnlocked(String id) {
    final deck = DECKS.firstWhere((d) => d.id == id);
    if (!deck.isPremium) return true;
    return _unlockedDeckIds.contains(id);
  }
}
