import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/game_provider.dart';
import 'rotate_screen.dart';

class TeamSetupScreen extends StatefulWidget {
  const TeamSetupScreen({super.key});

  @override
  State<TeamSetupScreen> createState() => _TeamSetupScreenState();
}

class _TeamSetupScreenState extends State<TeamSetupScreen> {
  final _t1Controller = TextEditingController();
  final _t2Controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    final game = Provider.of<GameProvider>(context, listen: false);
    _t1Controller.text = game.teamNames[0] ?? 'Team 1';
    _t2Controller.text = game.teamNames[1] ?? 'Team 2';
  }

  @override
  Widget build(BuildContext context) {
    final game = Provider.of<GameProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('👥 Team Setup'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _TeamInput(title: 'Team 1', controller: _t1Controller),
            const SizedBox(height: 20),
            _TeamInput(title: 'Team 2', controller: _t2Controller),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
        child: ElevatedButton(
          onPressed: () {
            game.setTeamName(0, _t1Controller.text);
            game.setTeamName(1, _t2Controller.text);
            game.startRotationGate();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RotateScreen()),
            );
          },
          child: const Text('CONTINUE →'),
        ),
      ),
    );
  }
}

class _TeamInput extends StatelessWidget {
  final String title;
  final TextEditingController controller;
  const _TeamInput({required this.title, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.acc)),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppTheme.s2,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}
