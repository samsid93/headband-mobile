import 'package:flutter/material.dart';
import '../../core/theme.dart';
import 'setup_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Orbs (simplified version of the JS canvas bg)
          const _AnimatedBackground(),
          
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [AppTheme.acc, AppTheme.acc2, AppTheme.pnk],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(bounds),
                    child: Text(
                      'HeadBand!',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: Colors.white, // Masked
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'The forehead guessing party game',
                    style: TextStyle(color: AppTheme.mut, fontSize: 15),
                  ),
                  const SizedBox(height: 48),
                  
                  // Play Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SetupScreen()),
                        );
                      },
                      child: const Text('▶ Play Now'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Leaderboard Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 17),
                        side: const BorderSide(color: Colors.white.withOpacity(0.15)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      onPressed: () {
                        // Navigate to Leaderboard
                      },
                      child: const Text(
                        '🏆 Leaderboard',
                        style: TextStyle(color: AppTheme.txt, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedBackground extends StatelessWidget {
  const _AnimatedBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.bg,
      child: Stack(
        children: [
          _Orb(color: AppTheme.acc.withOpacity(0.1), top: 100, left: -50),
          _Orb(color: AppTheme.pur.withOpacity(0.1), bottom: 100, right: -50),
          _Orb(color: AppTheme.pnk.withOpacity(0.05), top: 300, right: 100),
        ],
      ),
    );
  }
}

class _Orb extends StatelessWidget {
  final Color color;
  final double? top, bottom, left, right;
  const _Orb({required this.color, this.top, this.bottom, this.left, this.right});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top, bottom: bottom, left: left, right: right,
      child: Container(
        width: 300,
        height: 300,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, Colors.transparent],
          ),
        ),
      ),
    );
  }
}
