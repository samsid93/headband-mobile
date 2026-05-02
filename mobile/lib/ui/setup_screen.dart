import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../providers/game_provider.dart';

class SetupScreen extends StatelessWidget {
  const SetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: Consumer<GameProvider>(
        builder: (context, game, child) {
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text('Game Setup', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
              const SizedBox(height: 20),
              
              // Mode Selector
              _buildSectionTitle('Game Mode'),
              Row(
                children: [
                  _buildModeButton(context, 'Classic', 'classic', game),
                  const SizedBox(width: 8),
                  _buildModeButton(context, 'Team', 'team', game),
                ],
              ),
              const SizedBox(height: 20),
              
              // Timer Section
              _buildSectionTitle('Round Timer'),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surface2,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppTheme.border2),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: () => game.setTimer(game.timer - 5),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text('${game.timer}', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: AppTheme.accent)),
                          const Text('SECONDS', style: TextStyle(fontSize: 10, color: AppTheme.muted, letterSpacing: 0.8)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () => game.setTimer(game.timer + 5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [30, 45, 60, 90, 120, 180].map((t) => ActionChip(
                  label: Text(t >= 120 ? '${t ~/ 60} min' : '${t}s'),
                  onPressed: () => game.setTimer(t),
                )).toList(),
              ),

              
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  // Navigate to Team setup or Ready screen based on mode
                },
                child: const Text('Continue →'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title.toUpperCase(), style: const TextStyle(fontSize: 11, color: AppTheme.muted, letterSpacing: 1)),
    );
  }

  Widget _buildModeButton(BuildContext context, String label, String value, GameProvider game) {
    bool isSelected = game.mode == value;
    return Expanded(
      child: InkWell(
        onTap: () => game.setMode(value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.accent : AppTheme.surface2,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isSelected ? AppTheme.accent : AppTheme.border),
          ),
          child: Text(label, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.black : AppTheme.muted)),
        ),
      ),
    );
  }

  Widget _buildSwitchRow(String title, bool value, Function(bool) onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.surface2, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          Switch(value: value, onChanged: onChanged, activeColor: AppTheme.accent),
        ],
      ),
    );
  }
}
