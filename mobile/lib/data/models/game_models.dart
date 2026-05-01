class WordCard {
  final String word;
  final String hint;

  WordCard({required this.word, required this.hint});

  Map<String, dynamic> toJson() => {
    'w': word,
    'h': hint,
  };

  factory WordCard.fromJson(Map<String, dynamic> json) => WordCard(
    word: json['w'] as String,
    hint: json['h'] as String,
  );
}

class Deck {
  final String id;
  final String name;
  final String icon;
  final List<WordCard> words;
  final bool isPremium;
  final bool isLocked;

  Deck({
    required this.id,
    required this.name,
    required this.icon,
    required this.words,
    this.isPremium = false,
    this.isLocked = false,
  });
}
