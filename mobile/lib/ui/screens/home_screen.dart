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
          
          Positioned(
            top: -100,
            right: -100,
            child: _GlowOrb(color: AppTheme.primary.withOpacity(0.15), size: 400),
          ).animate(onPlay: (c) => c.repeat(reverse: true)).moveY(begin: 0, end: 50, duration: 4.seconds),
          
          Positioned(
            bottom: -150,
            left: -100,
            child: _GlowOrb(color: AppTheme.secondary.withOpacity(0.12), size: 500),
          ).animate(onPlay: (c) => c.repeat(reverse: true)).moveX(begin: 0, end: 60, duration: 5.seconds),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),
                  
                  // Rebranded Title: "Charades Party"
                  // Using FittedBox to prevent word breaking/overflow
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Charades\nParty',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 78,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Georgia',
                        height: 0.85,
                        letterSpacing: -2,
                        foreground: Paint()
                          ..shader = const LinearGradient(
                            colors: [AppTheme.acc, AppTheme.secondary, AppTheme.primary],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ).createShader(const Rect.fromLTWH(0.0, 0.0, 400.0, 160.0)),
                        shadows: [
                          Shadow(color: AppTheme.primary.withOpacity(0.6), blurRadius: 40),
                          Shadow(color: AppTheme.secondary.withOpacity(0.4), blurRadius: 20),
                        ],
                      ),
                    ),
                  ).animate().scale(duration: 800.ms, curve: Curves.elasticOut),
                  
                  const SizedBox(height: 16),
                  const Text(
                    'THE ULTIMATE PARTY GUESSING GAME',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.mut, 
                      fontSize: 13, 
                      letterSpacing: 1.5, 
                      fontWeight: FontWeight.w900
                    ),
                  ).animate().fadeIn(delay: 600.ms),
                  
                  const SizedBox(height: 40),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _VibrantBadge(text: '📱 TILT', color: AppTheme.blue, icon: Icons.phone_android),
                      const SizedBox(width: 8),
                      _VibrantBadge(text: '🎙️ VOICE', color: AppTheme.purple, icon: Icons.mic),
                      const SizedBox(width: 8),
                      _VibrantBadge(text: '👥 TEAMS', color: AppTheme.secondary, icon: Icons.groups),
                    ],
                  ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.2, end: 0),

                  const Spacer(flex: 3),
                  
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 72),
                      backgroundColor: AppTheme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SetupScreen()),
                      );
                    },
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.play_arrow_rounded, size: 36),
                        SizedBox(width: 8),
                        Text('PLAY NOW', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 1)),
                      ],
                    ),
                  ).animate().shimmer(delay: 2.seconds, duration: 1.5.seconds),
                  
                  const SizedBox(height: 16),
                  
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 72),
                      side: const BorderSide(color: AppTheme.border2, width: 2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LeaderboardScreen()),
                      );
                    },
                    child: const Text('🏆 LEADERBOARD', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  ),
                  
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

class _VibrantBadge extends StatelessWidget {
  final String text;
  final Color color;
  final IconData icon;
  const _VibrantBadge({required this.text, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.4), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: color, letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final Color color;
  final double size;
  const _GlowOrb({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, Colors.transparent]),
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
      ..color = AppTheme.primary.withOpacity(0.04)
      ..strokeWidth = 1.0;
    const spacing = 50.0;
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
