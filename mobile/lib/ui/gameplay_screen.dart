import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:vibration/vibration.dart';
import '../providers/game_provider.dart';
import '../core/services/sensor_service.dart';
import '../core/services/voice_service.dart';
import '../core/services/audio_service.dart';

class GameplayScreen extends StatefulWidget {
  const GameplayScreen({super.key});

  @override
  State<GameplayScreen> createState() => _GameplayScreenState();
}

class _GameplayScreenState extends State<GameplayScreen> {
  late SensorService _sensorService;
  late VoiceService _voiceService;
  late AudioService _audioService;
  Timer? _timer;
  
  Color _cardOverlayColor = Colors.transparent;
  String _voiceStatus = '';
  bool _isCoolingDown = false;

  @override
  void initState() {
    super.initState();
    _audioService = AudioService();
    _startTimer();
    
    _sensorService = SensorService(onTilt: (x, y, z) {
      if (_isCoolingDown) return;
      final orientation = MediaQuery.of(context).orientation;
      if (orientation != Orientation.landscape) return;
      if (y > 5.0) _handleAction(false);
      if (y < -5.0) _handleAction(true);
    });
    
    final game = Provider.of<GameProvider>(context, listen: false);
    if (game.tiltEnabled) _sensorService.start();
    
    _voiceService = VoiceService();
    if (game.voiceEnabled) {
      _voiceService.init().then((_) {
        _voiceService.startListening((command) {
          final cmd = command.toLowerCase();
          if (cmd.contains('correct')) _handleAction(true);
          else if (cmd.contains('skip')) _handleAction(false);
          else _showUnknownWordFeedback();
        });
      });
    }
  }

  void _handleAction(bool isCorrect) async {
    if (_isCoolingDown) return;
    setState(() {
      _isCoolingDown = true;
      _cardOverlayColor = isCorrect ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3);
    });
    
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: isCorrect ? 100 : 300);
    }
    
    if (isCorrect) _audioService.playCorrect();
    else _audioService.playSkip();

    Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _cardOverlayColor = Colors.transparent;
        _isCoolingDown = false;
      });
    });
  }

  void _showUnknownWordFeedback() {
    setState(() => _voiceStatus = '❓');
    Timer(const Duration(milliseconds: 800), () => setState(() => _voiceStatus = ''));
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _audioService.playTick();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _sensorService.stop();
    _voiceService.stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Quit Game?'),
            content: const Text('Are you sure you want to quit this round?'),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('No')),
              TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Yes')),
            ],
          ),
        );
        if (shouldExit == true) Navigator.of(context).pop();
      },
      child: Scaffold(
        body: Stack(
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF0E0E1C),
                  borderRadius: BorderRadius.circular(44),
                  border: Border.all(color: _cardOverlayColor, width: 4),
                ),
                child: Center(
                  child: Text(
                    'THE LION KING $_voiceStatus',
                    style: const TextStyle(fontSize: 50, fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ),
            if (_voiceStatus.isNotEmpty) 
              Positioned(top: 40, right: 40, child: Text(_voiceStatus, style: const TextStyle(fontSize: 40))),
          ],
        ),
      ),
    );
  }
}
