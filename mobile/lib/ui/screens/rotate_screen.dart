import 'package:flutter/material.dart';
import '../../core/theme.dart';

class RotateTutorialScreen extends StatelessWidget {
  const RotateTutorialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: Text(
                '📱 ROTATE TO LANDSCAPE',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
            ),
            const Expanded(
              child: Center(
                child: Text('Please hold the phone sideways.', style: TextStyle(color: AppTheme.mut)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('SKIP — USE BUTTONS'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
