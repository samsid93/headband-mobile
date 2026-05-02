import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme.dart';

class RotateTutorialScreen extends StatelessWidget {
  const RotateTutorialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Text('📱 Rotate to Landscape', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
              const SizedBox(height: 10),
              const Text(
                'Hold phone sideways against your forehead for the best experience. Required for tilt controls and voice commands:',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppTheme.muted, height: 1.6),
              ),
              const SizedBox(height: 20),
              
              // Animated Panels
              Row(
                children: [
                  _buildTutorialPanel(
                    icon: '⬇️',
                    title: '✗ SKIP',
                    desc: 'Tilt charging port side toward the floor',
                    color: AppTheme.skip,
                    animation: true,
                  ),
                  const SizedBox(width: 8),
                  _buildTutorialPanel(
                    icon: '⬆️',
                    title: '✓ CORRECT',
                    desc: 'Tilt charging port side toward the sky',
                    color: AppTheme.correct,
                    animation: true,
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.border),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh, size: 16, color: AppTheme.muted),
                    SizedBox(width: 8),
                    Text('Rotate your phone to landscape', style: TextStyle(fontSize: 12, color: AppTheme.muted)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTutorialPanel({required String icon, required String title, required String desc, required Color color, bool animation = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 10),
            // Mock phone animation
            Container(
              width: 100,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.accent.withOpacity(0.7)),
              ),
            ).animate(onPlay: (controller) => controller.repeat()).rotate(duration: 2200.ms, begin: -0.1, end: 0.1),
            const SizedBox(height: 10),
            Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 6),
            Text(desc, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: AppTheme.muted, height: 1.5)),
          ],
        ),
      ),
    );
  }
}
