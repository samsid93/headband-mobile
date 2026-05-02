import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/game_provider.dart';
import '../../core/theme.dart';
import 'gameplay_screen.dart';

class ReadyScreen extends StatelessWidget {
  const ReadyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final game = Provider.of<GameProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🎮', style: TextStyle(fontSize: 72)),
              const Text('Ready?', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
              const SizedBox(height: 10),
              const Text('Hold phone to forehead — others see the word!', style: TextStyle(color: AppTheme.mut)),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  game.startRound();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const GameplayScreen()),
                  );
                },
                child: Text(game.mode == 'team' ? "Start — ${game.teamNames[game.currentTeamIndex]}'s Turn!" : 'START ROUND!'),
              ),
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('CANCEL'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
