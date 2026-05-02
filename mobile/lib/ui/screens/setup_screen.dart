import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme.dart';
import '../../providers/game_provider.dart';
import '../../data/models/game_models.dart';
import '../../data/mock_data.dart';
import 'team_setup_screen.dart';
import 'rotate_screen.dart';

class SetupScreen extends StatelessWidget {
  const SetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final game = Provider.of<GameProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Stack(
        children: [
          // Visual Background Grid
          CustomPaint(
            painter: _SetupGridPainter(),
            child: Container(),
          ),
          
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.text),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'GAME SETUP',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 1),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        
                        // Mode Selection
                        const _SectionHeader(title: 'Game Mode', icon: Icons.sports_esports_rounded),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _VibrantModeBtn(
                              label: 'CLASSIC',
                              isActive: game.mode == 'classic',
                              onTap: () => game.mode = 'classic',
                              icon: Icons.person_rounded,
                            ),
                            const SizedBox(width: 12),
                            _VibrantModeBtn(
                              label: 'TEAMS',
                              isActive: game.mode == 'team',
                              onTap: () => game.mode = 'team',
                              icon: Icons.groups_rounded,
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Deck Selection
                        const _SectionHeader(title: 'Select Deck', icon: Icons.grid_view_rounded),
                        const SizedBox(height: 12),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.1,
                          ),
                          itemCount: DECKS.length,
                          itemBuilder: (context, index) {
                            final deck = DECKS[index];
                            final isSelected = game.selectedDeckId == deck.id;
                            
                            return _VibrantDeckCard(
                              deck: deck,
                              isSelected: isSelected,
                              onTap: () => game.selectedDeckId = deck.id,
                            );
                          },
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Timer Selection
                        const _SectionHeader(title: 'Round Duration', icon: Icons.timer_rounded),
                        const SizedBox(height: 12),
                        _VibrantTimerStepper(
                          value: game.roundDuration,
                          onChanged: (val) => game.roundDuration = val,
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Advanced Toggles
                        const _SectionHeader(title: 'Advanced Controls', icon: Icons.settings_input_component_rounded),
                        const SizedBox(height: 12),
                        _VibrantSettingsCard(game: game),
                        
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      // Fixed: Bottom button protected by SafeArea and Padding to prevent overlap with OS controls
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 64),
              backgroundColor: AppTheme.primary,
              shadowColor: AppTheme.primary.withOpacity(0.5),
              elevation: 10,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            onPressed: () {
              if (game.mode == 'team') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const TeamSetupScreen()));
              } else {
                game.startRotationGate();
                Navigator.push(context, MaterialPageRoute(builder: (_) => const RotateScreen()));
              }
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('PROCEED', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1)),
                SizedBox(width: 10),
                Icon(Icons.arrow_forward_rounded, size: 24),
              ],
            ),
          ).animate().shimmer(delay: 1.seconds, duration: 2.seconds),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.primary),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: const TextStyle(color: AppTheme.mut, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5),
        ),
      ],
    );
  }
}

class _VibrantModeBtn extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final IconData icon;
  const _VibrantModeBtn({required this.label, required this.isActive, required this.onTap, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: 300.ms,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isActive ? AppTheme.primary.withOpacity(0.2) : AppTheme.s2,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isActive ? AppTheme.primary : Colors.white.withOpacity(0.05),
              width: 2,
            ),
            boxShadow: isActive ? [BoxShadow(color: AppTheme.primary.withOpacity(0.2), blurRadius: 15)] : [],
          ),
          child: Column(
            children: [
              Icon(icon, color: isActive ? AppTheme.primary : AppTheme.mut, size: 28),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  color: isActive ? AppTheme.text : AppTheme.mut,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VibrantDeckCard extends StatelessWidget {
  final Deck deck;
  final bool isSelected;
  final VoidCallback onTap;
  const _VibrantDeckCard({required this.deck, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: 300.ms,
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.secondary.withOpacity(0.15) : AppTheme.s2,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.secondary : Colors.white.withOpacity(0.05),
            width: 2,
          ),
          boxShadow: isSelected ? [BoxShadow(color: AppTheme.secondary.withOpacity(0.2), blurRadius: 20)] : [],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(deck.icon, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 8),
            Text(
              deck.name,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: isSelected ? AppTheme.text : AppTheme.text.withOpacity(0.7),
              ),
            ),
            Text(
              '${deck.words.length} WORDS',
              style: TextStyle(fontSize: 10, color: AppTheme.mut, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class _VibrantTimerStepper extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  const _VibrantTimerStepper({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.s2,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          _StepBtn(icon: Icons.remove_circle_outline_rounded, onTap: value > 10 ? () => onChanged(value - 5) : null),
          Expanded(
            child: Column(
              children: [
                Text(
                  '$value',
                  style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: AppTheme.acc, height: 1),
                ),
                const Text('SECONDS', style: TextStyle(fontSize: 10, color: AppTheme.mut, fontWeight: FontWeight.bold, letterSpacing: 1)),
              ],
            ),
          ),
          _StepBtn(icon: Icons.add_circle_outline_rounded, onTap: value < 600 ? () => onChanged(value + 5) : null),
        ],
      ),
    );
  }
}

class _StepBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _StepBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, size: 36, color: onTap == null ? AppTheme.mut.withOpacity(0.3) : AppTheme.primary),
    );
  }
}

class _VibrantSettingsCard extends StatelessWidget {
  final GameProvider game;
  const _VibrantSettingsCard({required this.game});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.s2,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          _VibrantToggle(
            label: 'Tilt controls',
            icon: Icons.phone_android_rounded,
            color: AppTheme.blue,
            value: game.tiltEnabled,
            onChanged: (v) => game.tiltEnabled = v,
          ),
          const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Divider(color: Colors.white10)),
          _VibrantToggle(
            label: 'Voice commands',
            icon: Icons.mic_rounded,
            color: AppTheme.pur,
            value: game.voiceEnabled,
            onChanged: (v) => game.voiceEnabled = v,
          ),
          const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Divider(color: Colors.white10)),
          _VibrantToggle(
            label: 'Skips deduct points',
            icon: Icons.remove_circle_rounded,
            color: AppTheme.skp,
            value: game.skipDeduct,
            onChanged: (v) => game.skipDeduct = v,
          ),
        ],
      ),
    );
  }
}

class _VibrantToggle extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _VibrantToggle({required this.label, required this.icon, required this.color, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
        Switch(
          value: value, 
          onChanged: onChanged, 
          activeColor: color,
          trackColor: MaterialStateProperty.all(color.withOpacity(0.2)),
        ),
      ],
    );
  }
}

class _SetupGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppTheme.primary.withOpacity(0.03)..strokeWidth = 1.0;
    for (double i = 0; i < size.width; i += 40) canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    for (double i = 0; i < size.height; i += 40) canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
