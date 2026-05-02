import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme.dart';
import '../../providers/game_provider.dart';
import 'ready_screen.dart';

class RotateScreen extends StatefulWidget {
  const RotateScreen({super.key});

  @override
  State<RotateScreen> createState() => _RotateScreenState();
}

class _RotateScreenState extends State<RotateScreen> {
  bool _hasNavigated = false;

  @override
  Widget build(BuildContext context) {
    final game = Provider.of<GameProvider>(context);

    if (game.state == GameState.ready && !_hasNavigated) {
      _hasNavigated = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ReadyScreen()),
        );
      });
    }

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.primary.withOpacity(0.05), AppTheme.bg],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                
                // Realistic Rotating Phone Animation
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.primary.withOpacity(0.1),
                      ),
                    ).animate(onPlay: (c) => c.repeat()).scale(duration: 2.seconds, begin: const Offset(1, 1), end: const Offset(1.3, 1.3)).fadeOut(),
                    
                    const Icon(Icons.screen_rotation_rounded, size: 80, color: AppTheme.acc)
                        .animate(onPlay: (c) => c.repeat())
                        .rotate(begin: 0, end: 0.25, duration: 2.seconds, curve: Curves.easeInOutExpo),
                  ],
                ),
                
                const SizedBox(height: 40),
                const Text(
                  'ROTATE TO LANDSCAPE',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1),
                ).animate().shimmer(duration: 2.seconds, color: AppTheme.acc),
                
                const SizedBox(height: 20),
                const Text(
                  'Hold your phone against your forehead sideways to begin.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.mut, fontSize: 17, height: 1.5),
                ),
                
                const Spacer(),
                
                // Precise Directional Tutorial
                Row(
                  children: [
                     _buildVibrantTutorialCard('✓ CORRECT', 'Tilt top toward floor', AppTheme.cor, true),
                     const SizedBox(width: 15),
                     _buildVibrantTutorialCard('✗ SKIP', 'Tilt top toward sky', AppTheme.skp, false),
                  ],
                ),
                
                const Spacer(),
                const Text(
                  'WAITING FOR ROTATION...',
                  style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 12),
                ).animate(onPlay: (c) => c.repeat()).fadeIn(duration: 1.seconds).fadeOut(delay: 1.seconds),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVibrantTutorialCard(String title, String desc, Color color, bool isCorrect) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withOpacity(0.3), width: 2),
          boxShadow: [BoxShadow(color: color.withOpacity(0.05), blurRadius: 15)],
        ),
        child: Column(
          children: [
            // Directional Arrow Animation
            Icon(isCorrect ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded, color: color, size: 28)
                .animate(onPlay: (c) => c.repeat())
                .moveY(begin: isCorrect ? -5 : 5, end: isCorrect ? 5 : -5, duration: 1.seconds),
            const SizedBox(height: 12),
            Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 16)),
            const SizedBox(height: 6),
            Text(desc, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.mut, fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
