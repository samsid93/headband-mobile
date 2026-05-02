import 'package:flutter/material.dart';
import 'core/theme.dart';
import 'ui/screens/home_screen.dart';
import 'providers/game_provider.dart';
import 'package:provider/provider.dart';
import 'core/services/permission_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Early permission request for smooth UX
  await PermissionService.requestGamePermissions();

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
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const HomeScreen(),
    );
  }
}
