import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/game_provider.dart';

class GameplayScreen extends StatefulWidget {
  const GameplayScreen({super.key});

  @override
  State<GameplayScreen> createState() => _GameplayScreenState();
}

class _GameplayScreenState extends State<GameplayScreen> {
  @override
  void initState() {
    super.initState();
    // Lock to landscape Left/Right for gameplay
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    
    // Start game logic
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<GameProvider>(context, listen: false).startRound();
    });
  }

  @override
  void dispose() {
    // Unlock orientation when leaving gameplay
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = Provider.of<GameProvider>(context);

    if (game.state == GameState.countdown) {
      return const _CountdownView();
    }

    if (game.state == GameState.score) {
      // We could use a separate screen or a view here
      return const _ScoreView();
    }

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Row(
        children: [
          // Left Side: Skip
          _SideButton(
            label: 'SKIP',
            icon: '✗',
            color: AppTheme.skp,
            score: game.scoreSkipped,
            onPressed: game.handleSkip,
          ),
          
          // Centre: Word Card
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Timer
                _TimerRing(
                  seconds: game.secondsRemaining,
                  total: game.roundDuration,
                ),
                const SizedBox(height: 20),
                
                // Word Card
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.s1.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(44),
                      border: Border.all(color: Colors.white10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          game.selectedDeck.name.toUpperCase(),
                          style: const TextStyle(fontSize: 10, color: AppTheme.mut, letterSpacing: 1.2),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          game.currentWord.word,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'Georgia',
                          ),
                        ),
                        if (game.currentWord.hint.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Text(
                              game.currentWord.hint,
                              style: const TextStyle(fontSize: 12, color: AppTheme.mut, fontStyle: FontStyle.italic),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Right Side: Correct
          _SideButton(
            label: 'CORRECT',
            icon: '✓',
            color: AppTheme.cor,
            score: game.scoreCorrect,
            onPressed: game.handleCorrect,
            isRight: true,
          ),
        ],
      ),
    );
  }
}

class _SideButton extends StatelessWidget {
  final String label, icon;
  final Color color;
  final int score;
  final VoidCallback onPressed;
  final bool isRight;

  const _SideButton({
    required this.label, required this.icon, required this.color,
    required this.score, required this.onPressed, this.isRight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      color: Colors.black26,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              children: [
                Text(
                  '$score',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: color),
                ),
                Text(
                  label == 'SKIP' ? 'SKIPPED' : 'CORRECT',
                  style: const TextStyle(fontSize: 9, color: AppTheme.mut),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onPressed,
            child: Container(
              height: 120,
              width: 80,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(icon, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white)),
                  Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimerRing extends StatelessWidget {
  final int seconds, total;
  const _TimerRing({required this.seconds, required this.total});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 80,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: seconds / total,
            strokeWidth: 6,
            color: AppTheme.acc,
            backgroundColor: Colors.white10,
          ),
          Text(
            '$seconds',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _CountdownView extends StatelessWidget {
  const _CountdownView();
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppTheme.bg,
      body: Center(
        child: Text(
          'Get Ready...',
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

class _ScoreView extends StatelessWidget {
  const _ScoreView();
  @override
  Widget build(BuildContext context) {
    final game = Provider.of<GameProvider>(context);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 60)),
            const Text('Round Over!', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
            const SizedBox(height: 20),
            Text('Score: ${game.scoreCorrect}', style: const TextStyle(fontSize: 76, fontWeight: FontWeight.w900, color: AppTheme.acc)),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('🏠 Back to Home'),
            ),
          ],
        ),
      ),
    );
  }
}
