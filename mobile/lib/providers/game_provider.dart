import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';
import '../data/models/game_models.dart';
import '../data/mock_data.dart';
import '../core/services/audio_service.dart';
import '../core/services/sensor_service.dart';
import '../core/services/voice_service.dart';
import '../core/services/leaderboard_service.dart';

enum GameState { idle, setup, rotate, ready, countdown, playing, score }

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
  String? _lastAction;
  String _heardText = '';
  double _rawY = 0;
  bool _isCoolingDown = false;
  Timer? _gameTimer;

  GameProvider() {
    _sensor = SensorService(onData: _handleSensorData);
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
  String get heardText => _heardText;
  double get rawY => _rawY;
  Map<int, String> get teamNames => _teamNames;

  // Setters
  set mode(String val) { _mode = val; notifyListeners(); }
  set selectedDeckId(String val) { _selectedDeckId = val; notifyListeners(); }
  set roundDuration(int val) { _roundDuration = val; notifyListeners(); }
  set skipDeduct(bool val) { _skipDeduct = val; notifyListeners(); }
  set voiceEnabled(bool val) { _voiceEnabled = val; notifyListeners(); }
  set tiltEnabled(bool val) { _tiltEnabled = val; notifyListeners(); }
  set state(GameState s) { _state = s; notifyListeners(); }

  void setTeamName(int index, String name) {
    _teamNames[index] = name;
    notifyListeners();
  }

  void startRotationGate() {
    _state = GameState.rotate;
    _sensor.start();
    notifyListeners();
  }

  void startRound() {
    _state = GameState.countdown;
    _countdownValue = 3;
    _scoreCorrect = 0;
    _scoreSkipped = 0;
    _secondsRemaining = _roundDuration;
    _remainingWords = List.from(selectedDeck.words)..shuffle();
    _nextWord();
    _audio.playCountdown();
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
    // Longer cooldown to prevent rapid-fire triggers
    Timer(const Duration(milliseconds: 1100), () {
      _lastAction = null;
      _isCoolingDown = false;
      notifyListeners();
    });
  }

  void _handleSensorData(double x, double y, double z) {
    // Rotation Gate Logic
    if (_state == GameState.rotate) {
      if (x.abs() > 7.5 && y.abs() < 4.0) {
        _state = GameState.ready;
        notifyListeners();
      }
      return;
    }

    // Only process tilt if currently playing and NOT cooling down
    if (_state != GameState.playing || _isCoolingDown || !_tiltEnabled) {
      _rawY = 0; // Reset indicator
      notifyListeners();
      return;
    }

    // CRITICAL: Strict Landscape Guard
    // In forehead position (landscape), gravity is on X axis (short side).
    // If gravity moves to Y axis (long side), user is holding it in portrait.
    if (y.abs() > 8.0) {
      _rawY = 0;
      notifyListeners();
      return; 
    }

    // Actual gameplay tilt (uses side-tilt Y axis when in landscape)
    _rawY = y;

    // Threshold check
    if (y >= 5.5) {
      handleSkip();
    } else if (y <= -5.5) {
      handleCorrect();
    } else {
      notifyListeners();
    }
  }

  void _initVoice() async {
    bool available = await _voice.init();
    if (available) {
      _voice.startListening((text) {
        final lower = text.toLowerCase();
        if (lower.contains('correct') || lower.contains('yes')) {
          handleCorrect();
        } else if (lower.contains('skip') || lower.contains('next')) {
          handleSkip();
        } else {
          _lastAction = 'unknown';
          _heardText = text;
          notifyListeners();
          Timer(const Duration(seconds: 2), () {
            _lastAction = null;
            _heardText = '';
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
    
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    
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
    _sensor.stop();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
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
