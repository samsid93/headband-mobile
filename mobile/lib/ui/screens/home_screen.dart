import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme.dart';
import 'setup_screen.dart';
import 'leaderboard_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Stack(
        children: [
          const _BackgroundGrid(),
          
          Center(
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [AppTheme.acc.withOpacity(0.12), Colors.transparent],
                ),
              ),
            ),
          ).animate(onPlay: (controller) => controller.repeat(reverse: true))
           .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2), duration: 3.seconds, curve: Curves.easeInOut),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  
                  Text(
                    'HeadBand!',
                    style: TextStyle(
                      fontSize: 68,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Georgia',
                      foreground: Paint()
                        ..shader = const LinearGradient(
                          colors: [AppTheme.acc, Color(0xFFFF7A3D), Color(0xFFFF6EBC)],
                        ).createShader(const Rect.fromLTWH(0.0, 0.0, 300.0, 70.0)),
                      shadows: [
                        Shadow(color: AppTheme.acc.withOpacity(0.5), blurRadius: 30),
                      ],
                    ),
                  ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
                  
                  const Text(
                    'The forehead guessing party game',
                    style: TextStyle(color: AppTheme.mut, fontSize: 15, letterSpacing: 0.5),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const _Badge(text: '📱 Tilt', color: Colors.blue),
                      const SizedBox(width: 8),
                      const _Badge(text: '🎙️ Voice', color: Colors.purple),
                      const SizedBox(width: 8),
                      _Badge(text: '🎮 Decks', color: AppTheme.cor),
                    ],
                  ).animate().fadeIn(delay: 400.ms),

                  const Spacer(),
                  
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 60),
                      backgroundColor: AppTheme.acc,
                      foregroundColor: Colors.black,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SetupScreen()),
                      );
                    },
                    child: const Text('▶ PLAY NOW', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                  ).animate().slideY(begin: 1, duration: 500.ms, curve: Curves.easeOut),
                  
                  const SizedBox(height: 12),
                  
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 60),
                      side: BorderSide(color: Colors.white.withOpacity(0.15)),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LeaderboardScreen()),
                      );
                    },
                    child: const Text('🏆 LEADERBOARD'),
                  ).animate().slideY(begin: 1.5, duration: 600.ms, curve: Curves.easeOut),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  const _Badge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }
}

class _BackgroundGrid extends StatelessWidget {
  const _BackgroundGrid();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GridPainter(),
      child: Container(),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.016)
      ..strokeWidth = 0.5;

    const spacing = 56.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
