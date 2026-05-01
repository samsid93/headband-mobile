import 'package:flutter/material.dart';
import '../../core/theme.dart';

class TeamSetupScreen extends StatefulWidget {
  const TeamSetupScreen({super.key});

  @override
  State<TeamSetupScreen> createState() => _TeamSetupScreenState();
}

class _TeamSetupScreenState extends State<TeamSetupScreen> {
  final _t1Controller = TextEditingController();
  final _t2Controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(title: const Text('👥 Team Setup')),
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
      bottomNavigationBar: ElevatedButton(
        onPressed: () {
          // Save team names and proceed
          Navigator.pushNamed(context, '/ready');
        },
        child: const Text('START GAME →'),
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
          decoration: const InputDecoration(filled: true, fillColor: AppTheme.s2),
        ),
      ],
    );
  }
}
