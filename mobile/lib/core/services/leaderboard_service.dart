import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LeaderboardEntry {
  final String deck;
  final int score;
  final String date;

  LeaderboardEntry({required this.deck, required this.score, required this.date});

  Map<String, dynamic> toJson() => {
    'deck': deck,
    'score': score,
    'date': date,
  };

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) => LeaderboardEntry(
    deck: json['deck'] as String,
    score: json['score'] as int,
    date: json['date'] as String,
  );
}

class LeaderboardService {
  static const String _key = 'hb_leaderboard';

  Future<void> saveEntry(LeaderboardEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> current = prefs.getStringList(_key) ?? [];
    
    current.insert(0, jsonEncode(entry.toJson()));
    if (current.length > 25) current.removeLast();
    
    await prefs.setStringList(_key, current);
  }

  Future<List<LeaderboardEntry>> getEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> raw = prefs.getStringList(_key) ?? [];
    
    return raw.map((item) => LeaderboardEntry.fromJson(jsonDecode(item))).toList();
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
