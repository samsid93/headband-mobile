import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme.dart';
import '../../providers/game_provider.dart';
import 'ready_screen.dart';

class RotateScreen extends StatelessWidget {
  const RotateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final game = Provider.of<GameProvider>(context);

    // Auto-transition to Ready screen when landscape is detected
    if (game.state == GameState.ready) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ReadyScreen()),
        );
      });
    }

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.screen_rotation, size: 80, color: AppTheme.acc)
                  .animate(onPlay: (c) => c.repeat())
                  .rotate(begin: 0, end: 0.25, duration: 2.seconds),
              const SizedBox(height: 40),
              const Text(
                '📱 ROTATE TO LANDSCAPE',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 20),
              const Text(
                'Hold phone sideways against your forehead for the best experience.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.mut, fontSize: 16, height: 1.5),
              ),
              const Spacer(),
              
              // Animated tutorial panels (Correct/Skip)
              Row(
                children: [
                   _buildTutorialCard('✓ CORRECT', 'Tilt top toward floor', AppTheme.cor),
                   const SizedBox(width: 12),
                   _buildTutorialCard('✗ SKIP', 'Tilt top toward sky', AppTheme.skp),
                ],
              ),
              
              const Spacer(),
              const Text(
                'Waiting for rotation...',
                style: TextStyle(color: AppTheme.acc, fontWeight: FontWeight.bold),
              ).animate(onPlay: (c) => c.repeat()).fadeIn().fadeOut(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTutorialCard(String title, String desc, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 14)),
            const SizedBox(height: 8),
            Text(desc, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.mut, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
