import 'package:flutter/material.dart';
import 'core/theme.dart';
import 'ui/setup_screen.dart';
import 'providers/game_provider.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => GameProvider(),
      child: const HeadBandApp(),
    ),
  );
}

class HeadBandApp extends StatelessWidget {
  const HeadBandApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HeadBand!',
      theme: AppTheme.theme,
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Glow
          Positioned(
            top: MediaQuery.of(context).size.height * 0.5 - 160,
            left: MediaQuery.of(context).size.width * 0.5 - 160,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Colors.yellow.withOpacity(0.18), Colors.transparent],
                ),
              ),
            ),
          ),
          
          // Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'HeadBand!',
                  style: TextStyle(
                    fontSize: 68,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -3,
                    fontFamily: 'Georgia',
                    color: AppTheme.accent,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'The forehead guessing party game',
                  style: TextStyle(color: AppTheme.muted, fontSize: 15),
                ),
                const SizedBox(height: 48),
                
                // Badges
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildBadge('📱 Tilt to play', AppTheme.blue),
                    const SizedBox(width: 8),
                    _buildBadge('🎙️ Voice', AppTheme.purple),
                  ],
                ),
                const SizedBox(height: 48),
                
                // Buttons
                _buildButton('Play Now', AppTheme.accent, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SetupScreen()),
                  );
                }),
                const SizedBox(height: 10),
                _buildButton('Leaderboard', Colors.transparent, () {}, outlined: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildButton(String text, Color color, VoidCallback onPressed, {bool outlined = false}) {
    return Container(
      width: 340,
      decoration: outlined ? BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border2),
      ) : BoxDecoration(
        gradient: const LinearGradient(colors: [AppTheme.accent, Color(0xFFFFA820)]),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(17),
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: outlined ? AppTheme.text : const Color(0xFF0A0808),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
