abstract class Constraint {
  final String id;
  final int tier;
  final String displayText;

  const Constraint({
    required this.id,
    required this.tier,
    required this.displayText,
  });

  bool validate(String word);

  List<String> filterWordList(List<String> words) =>
      words.where((w) => validate(w)).toList();
}
