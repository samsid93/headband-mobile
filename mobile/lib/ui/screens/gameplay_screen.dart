import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
    // Gameplay MUST be landscape
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    // Reset orientation on leave
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
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
      return const _ScoreView();
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Quit Game?'),
            backgroundColor: AppTheme.s2,
            content: const Text('Are you sure you want to quit this round?'),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('NO')),
              TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('YES', style: TextStyle(color: AppTheme.skp))),
            ],
          ),
        );
        if (shouldExit == true) {
          game.reset();
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.bg,
        body: Stack(
          children: [
            Row(
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
                      const SizedBox(height: 10),
                      
                      // Word Card
                      Expanded(
                        child: Stack(
                          children: [
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              decoration: BoxDecoration(
                                color: AppTheme.s1.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(44),
                                border: Border.all(
                                  color: game.lastAction == 'correct' 
                                      ? AppTheme.cor 
                                      : game.lastAction == 'skip' 
                                          ? AppTheme.skp 
                                          : Colors.white.withOpacity(0.1),
                                  width: game.lastAction != null ? 3 : 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: game.lastAction == 'correct' 
                                        ? AppTheme.cor.withOpacity(0.3) 
                                        : game.lastAction == 'skip' 
                                            ? AppTheme.skp.withOpacity(0.3) 
                                            : Colors.black.withOpacity(0.3),
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
                                  ).animate(target: game.lastAction != null ? 1 : 0)
                                   .shake(duration: 300.ms),
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
                            
                            // Tilt indicators - uses Y axis for parity
                            if (game.tiltEnabled) ...[
                              Positioned(
                                left: 35, top: 40, bottom: 40, width: 6,
                                child: _TiltIndicatorBar(value: (-game.rawY / 4.5).clamp(0.0, 1.0), color: AppTheme.cor),
                              ),
                              Positioned(
                                right: 35, top: 40, bottom: 40, width: 6,
                                child: _TiltIndicatorBar(value: (game.rawY / 4.5).clamp(0.0, 1.0), color: AppTheme.skp),
                              ),
                            ]
                          ],
                        ),
                      ),
                      
                      // Status pills
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (game.tiltEnabled) const _InfoPill(text: '📱 Tilt active', color: AppTheme.acc),
                            if (game.voiceEnabled) const SizedBox(width: 10),
                            if (game.voiceEnabled) const _InfoPill(text: '🎙️ Listening...', color: AppTheme.pur),
                          ],
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
            
            // Overlays
            if (game.lastAction == 'correct') const _ActionOverlay(text: 'CORRECT!', color: AppTheme.cor),
            if (game.lastAction == 'skip') const _ActionOverlay(text: 'SKIP', color: AppTheme.skp),
            if (game.lastAction == 'unknown') _ActionOverlay(text: '🎙️ "${game.heardText}"\n❓❓❓', color: AppTheme.pur),
          ],
        ),
      ),
    );
  }
}

class _TiltIndicatorBar extends StatelessWidget {
  final double value;
  final Color color;
  const _TiltIndicatorBar({required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(3)),
      alignment: Alignment.bottomCenter,
      child: FractionallySizedBox(
        heightFactor: value,
        child: Container(
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3), boxShadow: [BoxShadow(color: color.withOpacity(0.5), blurRadius: 4)]),
        ),
      ),
    );
  }
}

class _ActionOverlay extends StatelessWidget {
  final String text;
  final Color color;
  const _ActionOverlay({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color.withOpacity(0.2),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(40), boxShadow: [BoxShadow(color: color.withOpacity(0.5), blurRadius: 30)]),
          child: Text(
            text, 
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: Colors.white)
          ),
        ),
      ).animate().scale(duration: 200.ms, curve: Curves.easeOut).fadeOut(delay: 400.ms),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final String text;
  final Color color;
  const _InfoPill({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.3))),
      child: Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
    );
  }
}

class _SideButton extends StatelessWidget {
  final String label, icon;
  final Color color;
  final int score;
  final VoidCallback onPressed;
  final bool isRight;

  const _SideButton({required this.label, required this.icon, required this.color, required this.score, required this.onPressed, this.isRight = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      color: Colors.black.withOpacity(0.2),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              children: [
                Text('$score', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: color)),
                Text(label == 'SKIP' ? 'SKIPPED' : 'CORRECT', style: const TextStyle(fontSize: 9, color: AppTheme.mut, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          GestureDetector(
            onTap: onPressed,
            child: Container(
              height: 80, width: 80, margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 10)]),
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
    final double progress = seconds / total;
    final Color timerColor = progress > 0.5 ? AppTheme.acc : progress > 0.25 ? Colors.orange : AppTheme.skp;

    return SizedBox(
      width: 60, height: 60,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(value: progress, strokeWidth: 5, color: timerColor, backgroundColor: Colors.white.withOpacity(0.1)),
          Text('$seconds', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _CountdownView extends StatelessWidget {
  const _CountdownView();
  @override
  Widget build(BuildContext context) {
    final game = Provider.of<GameProvider>(context);
    final val = game.countdownValue;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(val == 0 ? 'GO!' : '$val', style: const TextStyle(fontSize: 120, fontWeight: FontWeight.w900, color: AppTheme.acc, fontFamily: 'Georgia'))
                .animate(key: ValueKey(val)).scale(duration: 200.ms, curve: Curves.bounceOut).fadeOut(delay: 700.ms),
            const SizedBox(height: 20),
            Text(val == 0 ? '🚀' : 'Get Ready...', style: const TextStyle(fontSize: 20, color: AppTheme.mut, letterSpacing: 2)),
          ],
        ),
      ),
    );
  }
}

class _ScoreView extends StatefulWidget {
  const _ScoreView();

  @override
  State<_ScoreView> createState() => _ScoreViewState();
}

class _ScoreViewState extends State<_ScoreView> {
  @override
  void initState() {
    super.initState();
    // Force portrait for results
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final game = Provider.of<GameProvider>(context);
    final pts = game.skipDeduct ? (game.scoreCorrect - game.scoreSkipped).clamp(0, 100) : game.scoreCorrect;
    
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🎉', style: TextStyle(fontSize: 60)).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
              const Text('Round Over!', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(color: AppTheme.s2, borderRadius: BorderRadius.circular(30), border: Border.all(color: AppTheme.acc.withOpacity(0.3)), boxShadow: [BoxShadow(color: AppTheme.acc.withOpacity(0.1), blurRadius: 20)]),
                child: Column(
                  children: [
                    Text('$pts', style: const TextStyle(fontSize: 80, fontWeight: FontWeight.w900, color: AppTheme.acc)),
                    const Text('POINTS SCORED', style: TextStyle(fontSize: 12, color: AppTheme.mut, letterSpacing: 2)),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _StatMini(label: 'CORRECT', val: game.scoreCorrect, color: AppTheme.cor),
                        const SizedBox(width: 30),
                        _StatMini(label: 'SKIPPED', val: game.scoreSkipped, color: AppTheme.skp),
                      ],
                    )
                  ],
                ),
              ).animate().slideY(begin: 0.2, duration: 400.ms),
              const SizedBox(height: 40),
              ElevatedButton(
                style: ElevatedButton.styleFrom(minimumSize: const Size(200, 56)),
                onPressed: () {
                  game.reset();
                  Navigator.pop(context);
                },
                child: const Text('🏠 BACK TO HOME'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatMini extends StatelessWidget {
  final String label;
  final int val;
  final Color color;
  const _StatMini({required this.label, required this.val, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('$val', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: color)),
        Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.mut)),
      ],
    );
  }
}
