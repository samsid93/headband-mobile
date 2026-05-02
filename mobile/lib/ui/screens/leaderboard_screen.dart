import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/services/leaderboard_service.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = LeaderboardService();

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('🏆 Leaderboard'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: FutureBuilder<List<LeaderboardEntry>>(
        future: service.getEntries(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          if (snapshot.data!.isEmpty) return const Center(child: Text('No entries yet!', style: TextStyle(color: AppTheme.mut)));

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final entry = snapshot.data![index];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.s2,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Text('#${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.acc)),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(entry.deck.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          Text(entry.date, style: const TextStyle(fontSize: 10, color: AppTheme.mut)),
                        ],
                      ),
                    ),
                    Text('${entry.score}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppTheme.acc)),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
