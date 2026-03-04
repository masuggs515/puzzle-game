enum WordTier { answer, validGuess }

class WordEntry {
  final String word;
  final WordTier tier;
  final int length;
  final Set<String> categories;

  const WordEntry({
    required this.word,
    required this.tier,
    required this.length,
    required this.categories,
  });
}
