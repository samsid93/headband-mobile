import 'package:flutter/material.dart';
import 'core/theme.dart';
import 'ui/screens/home_screen.dart';
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
