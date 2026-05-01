import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/game_provider.dart';
import '../../data/mock_data.dart';
import 'gameplay_screen.dart';

class SetupScreen extends StatelessWidget {
  const SetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final game = Provider.of<GameProvider>(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('🎮 Game Setup'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _Label('Choose a Deck'),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.2,
              ),
              itemCount: DECKS.length,
              itemBuilder: (context, index) {
                final deck = DECKS[index];
                final isSelected = game.selectedDeckId == deck.id;
                
                return GestureDetector(
                  onTap: () => game.selectDeck(deck.id),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.s2,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? AppTheme.acc : Colors.white.withOpacity(0.1),
                        width: 2,
                      ),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(deck.icon, style: const TextStyle(fontSize: 26)),
                        const SizedBox(height: 4),
                        Text(
                          deck.name,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${deck.words.length} words',
                          style: const TextStyle(fontSize: 11, color: AppTheme.mut),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            
            const _Label('Round Timer'),
            const SizedBox(height: 12),
            _TimerStepper(
              value: game.roundDuration,
              onChanged: (val) => game.roundDuration = val,
            ),
            
            const SizedBox(height: 24),
            const _Label('Controls & Scoring'),
            const SizedBox(height: 12),
            _SettingsCard(game: game),
            
            const SizedBox(height: 100), // Spacer for bottom bar
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.transparent, AppTheme.bg],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const GameplayScreen()),
            );
          },
          child: const Text('Continue →'),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: const TextStyle(color: AppTheme.mut, fontSize: 11, letterSpacing: 1),
  );
}

class _TimerStepper extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  const _TimerStepper({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.s2,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: value > 10 ? () => onChanged(value - 5) : null,
            icon: const Icon(Icons.remove, size: 28),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  '$value',
                  style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: AppTheme.acc),
                ),
                const Text('SECONDS', style: TextStyle(fontSize: 10, color: AppTheme.mut)),
              ],
            ),
          ),
          IconButton(
            onPressed: value < 300 ? () => onChanged(value + 5) : null,
            icon: const Icon(Icons.add, size: 28),
          ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final GameProvider game;
  const _SettingsCard({required this.game});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.s2,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          _ToggleRow(
            label: 'Tilt controls',
            sub: 'Tilt phone for correct / skip',
            value: game.tiltEnabled,
            onChanged: (v) => game.tiltEnabled = v,
          ),
          const Divider(color: Colors.white.withOpacity(0.1)),
          _ToggleRow(
            label: 'Voice commands',
            sub: 'Say "Correct", "Yes", "Skip"',
            value: game.voiceEnabled,
            onChanged: (v) => game.voiceEnabled = v,
          ),
          const Divider(color: Colors.white.withOpacity(0.1)),
          _ToggleRow(
            label: 'Skips deduct points',
            sub: 'Each skip removes 1 point',
            value: game.skipDeduct,
            onChanged: (v) => game.skipDeduct = v,
          ),
        ],
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String label, sub;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ToggleRow({required this.label, required this.sub, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(sub, style: const TextStyle(fontSize: 11, color: AppTheme.mut)),
            ],
          ),
        ),
        Switch(value: value, onChanged: onChanged, activeColor: AppTheme.acc),
      ],
    );
  }
}
