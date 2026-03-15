# Puzzle Generation Agent Spec
**Project:** Intercept
**Agent Role:** Puzzle generation specialist — owns the word list pipeline, constraint library, CSP algorithm, puzzle validator, pre-generation tooling, and runtime generation module.  
**Document Version:** 0.1  
**Last Updated:** February 2026


---

## Agent Convention — TODO MAS

Any time you need human input, a decision, a credential, a review, or anything uncertain — leave a comment formatted exactly as:

```
// TODO MAS: [clear description of what is needed and why]
```

Use `//` in Dart/Flutter, `--` in SQL, `> TODO MAS:` in markdown. Never stall silently — leave a TODO MAS and keep working on everything else. At the end of your session, print a consolidated list of every TODO MAS you left so Adam can action them in one pass.

---

## Agent Context

You are a Dart/algorithms expert building the puzzle generation engine for a mobile word/logic puzzle game. This engine is a standalone Dart module — it has no Flutter dependencies and no UI concerns. It is consumed by two systems:

1. **Offline pre-generation tool** — a Dart CLI script run on the developer's machine that generates levels 1–200 and outputs a JSON file bundled with the app.
2. **Runtime generation module** — called on-device (or server-side) to generate theVault puzzles as the player progresses beyond hand-crafted content.

Your deliverables are:
- Word list pipeline (filtering, two-tier structure)
- Constraint library (all 5 tiers, implemented as Dart functions)
- Intersection structure builder
- CSP solver (AC-3 + backtracking)
- Puzzle validator
- Puzzle serializer (to/from JSON)
- Pre-generation CLI tool
- Runtime generation entry point
- Full test suite

You do not touch Flutter, Flame, Supabase, or Mixpanel. You consume the GDD as your source of truth.

---

## Project Structure

```
lib/
  puzzle_engine/
    word_list/
      word_list_loader.dart         # loads and filters word lists
      word_list_filter.dart         # filtering logic
      word_list_model.dart          # WordEntry, WordTier enums
    constraints/
      constraint.dart               # base Constraint interface
      constraint_library.dart       # all constraints organized by tier
      tier1_category.dart           # Tier 1 constraint implementations
      tier2_letter_rules.dart       # Tier 2 constraint implementations
      tier3_wordplay.dart           # Tier 3 constraint implementations
      tier4_container.dart          # Tier 4 constraint implementations
      tier5_combined.dart           # Tier 5 constraint implementations
    solver/
      csp_solver.dart               # AC-3 + backtracking implementation
      intersection_structure.dart   # puzzle skeleton builder
      puzzle_builder.dart           # orchestrates solver + constraints
    models/
      puzzle.dart                   # Puzzle, WordSlot, Intersection models
      constraint_assignment.dart    # maps constraints to word slots
    validation/
      puzzle_validator.dart         # validates solvability, fairness
      profanity_filter.dart         # filters invalid solutions
    serialization/
      puzzle_serializer.dart        # Puzzle → JSON, JSON → Puzzle
    generation/
      pre_generator.dart            # CLI tool for offline generation
      runtime_generator.dart        # on-device vault generation
tools/
  generate_puzzles.dart             # CLI entry point: dart run tools/generate_puzzles.dart
assets/
  word_lists/
    answer_words.txt                # ~15,000 curated answer words
    valid_guess_words.txt           # ~50,000 valid player guess words
    category_lists/
      animals.txt
      fruits.txt
      vegetables.txt
      colors.txt
      foods.txt
      kitchen_items.txt
      weather.txt
      clothing.txt
      body_parts.txt
      water_bodies.txt
      countries.txt
      sports.txt
  puzzles/
    levels_001_200.json             # pre-generated output, bundled with app
test/
  puzzle_engine/
    word_list_test.dart
    constraint_test.dart
    csp_solver_test.dart
    puzzle_validator_test.dart
    serialization_test.dart
    generation_test.dart
```

---

## Word List Pipeline

### Sources
1. **SCOWL (Spell Checker Oriented Word Lists)** — primary source
   - Download from: http://wordlist.aspell.net/
   - Use size 60 (medium-common words) as the baseline for answer words
   - Use size 80 (larger vocabulary) for valid guess words
2. **Google 20k most common English words** — secondary frequency reference
   - Cross-reference with SCOWL to prioritize high-frequency words in the answer list
   - Source: https://github.com/first20hours/google-10000-english

### Two-Tier Word System

```dart
enum WordTier {
  answer,     // ~15,000 words — used as puzzle answers
  validGuess, // ~50,000 words — accepted if player submits them
}

class WordEntry {
  final String word;
  final WordTier tier;
  final int length;
  final Set<String> categories; // which category lists this word belongs to
  
  const WordEntry({
    required this.word,
    required this.tier,
    required this.length,
    required this.categories,
  });
}
```

### Filtering Rules (applied to answer words)

```dart
class WordListFilter {
  static bool isValidAnswerWord(String word) {
    // Length: 3–8 characters only
    if (word.length < 3 || word.length > 8) return false;
    
    // Letters only — no hyphens, apostrophes, spaces
    if (!RegExp(r'^[a-zA-Z]+$').hasMatch(word)) return false;
    
    // No proper nouns (all-lowercase in SCOWL indicates common word)
    if (word[0] == word[0].toUpperCase() && word != word.toUpperCase()) return false;
    
    // No profanity — check against profanity blocklist
    if (ProfanityFilter.isBlocked(word)) return false;
    
    // US spelling preferred — filter British-only variants from answer list
    // (keep in valid guess list)
    if (BritishSpellingFilter.isBritishOnly(word)) return false;
    
    return true;
  }
  
  static bool isValidGuessWord(String word) {
    // More permissive — allow British spellings, longer words up to 12 chars
    if (word.length < 3 || word.length > 12) return false;
    if (!RegExp(r'^[a-zA-Z]+$').hasMatch(word)) return false;
    if (ProfanityFilter.isBlocked(word)) return false;
    return true;
  }
}
```

### Category Lists

Each category is a plain text file in `assets/word_lists/category_lists/`. One word per line, lowercase.

**Required categories for Tier 1 constraints:**
- `animals.txt` — dog, cat, lion, tiger, whale, eagle, snake, frog, bear, wolf...
- `fruits.txt` — apple, mango, grape, peach, lemon, plum, lime, fig...
- `vegetables.txt` — carrot, onion, potato, celery, leek, beet, kale...
- `colors.txt` — red, blue, green, yellow, purple, orange, pink, brown, gray...
- `foods.txt` — broad food category (superset of fruits + vegetables)
- `kitchen_items.txt` — pan, bowl, fork, knife, spoon, ladle, grater...
- `weather.txt` — rain, snow, hail, sleet, frost, storm, cloud, fog...
- `clothing.txt` — shirt, pants, dress, coat, hat, scarf, glove, boot...
- `body_parts.txt` — arm, leg, knee, elbow, wrist, chin, neck, heel...
- `water_bodies.txt` — lake, river, ocean, creek, pond, brook, bay, cove...
- `countries.txt` — filtered list of commonly known countries, lowercase
- `sports.txt` — golf, tennis, soccer, rugby, polo, chess, darts...

**Category loading:**
```dart
class CategoryListLoader {
  static final Map<String, Set<String>> _cache = {};
  
  static Set<String> load(String categoryName) {
    if (_cache.containsKey(categoryName)) return _cache[categoryName]!;
    
    final content = File('assets/word_lists/category_lists/$categoryName.txt')
        .readAsStringSync();
    final words = content
        .split('\n')
        .map((w) => w.trim().toLowerCase())
        .where((w) => w.isNotEmpty)
        .toSet();
    
    _cache[categoryName] = words;
    return words;
  }
}
```

---

## Data Models

### Core Models

```dart
// A single word slot in a puzzle
class WordSlot {
  final int id;                           // unique within puzzle
  final ConstraintAssignment constraint;  // what rule this word must satisfy
  final int? requiredLength;              // null = any length
  String? assignedWord;                   // null until solved
  
  const WordSlot({
    required this.id,
    required this.constraint,
    this.requiredLength,
    this.assignedWord,
  });
}

// A single intersection between two word slots
class Intersection {
  final int slotAId;         // WordSlot A
  final int slotBId;         // WordSlot B
  final int positionInA;     // index of shared letter in word A
  final int positionInB;     // index of shared letter in word B
  
  const Intersection({
    required this.slotAId,
    required this.slotBId,
    required this.positionInA,
    required this.positionInB,
  });
}

// Complete puzzle definition
class Puzzle {
  final String seed;
  final int? levelNumber;              // null for vault puzzles
  final LevelType levelType;
  final bool isBoss;
  final List<WordSlot> wordSlots;
  final List<Intersection> intersections;
  final List<String> letterPool;       // available letters for this puzzle
  final List<int> constraintTiers;     // which tiers appear in this puzzle
  final Map<String, dynamic> metadata; // generation stats, timing, etc.
  
  int get wordCount => wordSlots.length;
  int get intersectionCount => intersections.length;
  bool get isSolved => wordSlots.every((s) => s.assignedWord != null);
}

// Maps a constraint to a word slot
class ConstraintAssignment {
  final int tier;
  final String constraintId;           // e.g. 'is_animal', 'same_first_last'
  final String displayText;            // shown to player: "A type of animal"
  final Constraint validator;          // the actual validation function
  final Map<String, dynamic>? params;  // optional params (e.g. anagram target)
}
```

---

## Constraint Library

### Base Interface

```dart
abstract class Constraint {
  final String id;
  final int tier;
  final String displayText;
  
  const Constraint({
    required this.id,
    required this.tier,
    required this.displayText,
  });
  
  // Core validation — takes a word, returns true if it satisfies this constraint
  bool validate(String word);
  
  // Optional: filter a word list to only valid words for this constraint
  // Default implementation calls validate() on each word — override for performance
  List<String> filterWordList(List<String> words) {
    return words.where(validate).toList();
  }
}
```

---

### Tier 1 — Category Constraints

```dart
class CategoryConstraint extends Constraint {
  final String categoryName;
  late final Set<String> _categoryWords;
  
  CategoryConstraint({
    required String id,
    required String displayText,
    required this.categoryName,
  }) : super(id: id, tier: 1, displayText: displayText) {
    _categoryWords = CategoryListLoader.load(categoryName);
  }
  
  @override
  bool validate(String word) => _categoryWords.contains(word.toLowerCase());
  
  @override
  List<String> filterWordList(List<String> words) {
    return words.where((w) => _categoryWords.contains(w.toLowerCase())).toList();
  }
}

// All Tier 1 constraint instances
final tier1Constraints = [
  CategoryConstraint(id: 'is_animal',       displayText: 'A type of animal',          categoryName: 'animals'),
  CategoryConstraint(id: 'is_fruit',        displayText: 'A type of fruit',            categoryName: 'fruits'),
  CategoryConstraint(id: 'is_vegetable',    displayText: 'A type of vegetable',        categoryName: 'vegetables'),
  CategoryConstraint(id: 'is_color',        displayText: 'A color',                    categoryName: 'colors'),
  CategoryConstraint(id: 'is_food',         displayText: 'Something you can eat',      categoryName: 'foods'),
  CategoryConstraint(id: 'is_kitchen_item', displayText: 'Something found in a kitchen', categoryName: 'kitchen_items'),
  CategoryConstraint(id: 'is_weather',      displayText: 'A type of weather',          categoryName: 'weather'),
  CategoryConstraint(id: 'is_clothing',     displayText: 'Something you wear',         categoryName: 'clothing'),
  CategoryConstraint(id: 'is_body_part',    displayText: 'A part of the body',         categoryName: 'body_parts'),
  CategoryConstraint(id: 'is_water_body',   displayText: 'A body of water',            categoryName: 'water_bodies'),
  CategoryConstraint(id: 'is_sport',        displayText: 'A type of sport',            categoryName: 'sports'),
];
```

---

### Tier 2 — Letter Rule Constraints

```dart
class SameFirstLastConstraint extends Constraint {
  const SameFirstLastConstraint() : super(
    id: 'same_first_last',
    tier: 2,
    displayText: 'Starts and ends with the same letter',
  );
  
  @override
  bool validate(String word) {
    if (word.length < 2) return false;
    return word[0].toLowerCase() == word[word.length - 1].toLowerCase();
  }
}

class ContainsColorConstraint extends Constraint {
  static const _colors = {'red', 'blue', 'green', 'gold', 'rose', 'tan', 'gray', 'grey', 'lime', 'navy', 'teal', 'aqua', 'pink'};
  
  const ContainsColorConstraint() : super(
    id: 'contains_color',
    tier: 2,
    displayText: 'Contains a hidden color',
  );
  
  @override
  bool validate(String word) {
    final lower = word.toLowerCase();
    return _colors.any((color) => lower.contains(color));
  }
}

class NoRepeatedLettersConstraint extends Constraint {
  const NoRepeatedLettersConstraint() : super(
    id: 'no_repeated_letters',
    tier: 2,
    displayText: 'Has no repeated letters',
  );
  
  @override
  bool validate(String word) {
    final letters = word.toLowerCase().split('');
    return letters.toSet().length == letters.length;
  }
}

class HasDoubleLetterConstraint extends Constraint {
  const HasDoubleLetterConstraint() : super(
    id: 'has_double_letter',
    tier: 2,
    displayText: 'Contains a double letter',
  );
  
  @override
  bool validate(String word) {
    for (int i = 0; i < word.length - 1; i++) {
      if (word[i].toLowerCase() == word[i + 1].toLowerCase()) return true;
    }
    return false;
  }
}

class ExactLengthConstraint extends Constraint {
  final int length;
  
  ExactLengthConstraint(this.length) : super(
    id: 'exact_length_$length',
    tier: 2,
    displayText: 'Exactly $length letters long',
  );
  
  @override
  bool validate(String word) => word.length == length;
}

class ContainsVowelClusterConstraint extends Constraint {
  const ContainsVowelClusterConstraint() : super(
    id: 'contains_vowel_cluster',
    tier: 2,
    displayText: 'Contains two vowels in a row',
  );
  
  @override
  bool validate(String word) {
    return RegExp(r'[aeiou]{2,}', caseSensitive: false).hasMatch(word);
  }
}

final tier2Constraints = [
  const SameFirstLastConstraint(),
  const ContainsColorConstraint(),
  const NoRepeatedLettersConstraint(),
  const HasDoubleLetterConstraint(),
  ExactLengthConstraint(4),
  ExactLengthConstraint(5),
  ExactLengthConstraint(6),
  const ContainsVowelClusterConstraint(),
];
```

---

### Tier 3 — Wordplay Constraints

```dart
class PalindromeConstraint extends Constraint {
  const PalindromeConstraint() : super(
    id: 'palindrome',
    tier: 3,
    displayText: 'Reads the same forwards and backwards',
  );
  
  @override
  bool validate(String word) {
    final lower = word.toLowerCase();
    return lower == lower.split('').reversed.join();
  }
}

class ReversalIsValidWordConstraint extends Constraint {
  final Set<String> _validWords;
  
  ReversalIsValidWordConstraint(this._validWords) : super(
    id: 'reversal_is_valid_word',
    tier: 3,
    displayText: 'Spelled backwards is also a real word',
  );
  
  @override
  bool validate(String word) {
    final reversed = word.toLowerCase().split('').reversed.join();
    return reversed != word.toLowerCase() && _validWords.contains(reversed);
  }
}

class HomophoneOfNumberConstraint extends Constraint {
  // Homophones of numbers: won(one), too/to(two), for/fore(four), ate(eight)
  static const _numberHomophones = {'won', 'too', 'to', 'for', 'fore', 'ate', 'sex', 'nein'};
  
  const HomophoneOfNumberConstraint() : super(
    id: 'homophone_of_number',
    tier: 3,
    displayText: 'Sounds like a number',
  );
  
  @override
  bool validate(String word) => _numberHomophones.contains(word.toLowerCase());
}

class AnagramConstraint extends Constraint {
  final String targetWord;
  final String _sortedTarget;
  
  AnagramConstraint(this.targetWord) 
    : _sortedTarget = _sortLetters(targetWord),
      super(
        id: 'anagram_of_${targetWord.toLowerCase()}',
        tier: 3,
        displayText: 'An anagram of ${targetWord.toUpperCase()}',
      );
  
  static String _sortLetters(String word) {
    final letters = word.toLowerCase().split('')..sort();
    return letters.join();
  }
  
  @override
  bool validate(String word) {
    if (word.length != targetWord.length) return false;
    if (word.toLowerCase() == targetWord.toLowerCase()) return false; // must be different word
    return _sortLetters(word) == _sortedTarget;
  }
}

// Generate anagram constraints for common puzzle-worthy words
List<AnagramConstraint> buildAnagramConstraints(List<String> answerWords) {
  // Only create anagram constraints for words with 3+ valid anagrams
  // to ensure puzzle solvability
  final anagramGroups = <String, List<String>>{};
  
  for (final word in answerWords) {
    final key = (word.toLowerCase().split('')..sort()).join();
    anagramGroups.putIfAbsent(key, () => []).add(word);
  }
  
  return anagramGroups.entries
      .where((e) => e.value.length >= 3)
      .expand((e) => e.value.map((w) => AnagramConstraint(w)))
      .toList();
}

final tier3ConstraintsBase = [
  const PalindromeConstraint(),
  const HomophoneOfNumberConstraint(),
  // ReversalIsValidWord and Anagram constraints built dynamically with word list
];
```

---

### Tier 4 — Container / Deletion Constraints

```dart
class RemoveFirstLetterIsValidConstraint extends Constraint {
  final Set<String> _validWords;
  
  RemoveFirstLetterIsValidConstraint(this._validWords) : super(
    id: 'remove_first_letter_valid',
    tier: 4,
    displayText: 'Remove the first letter to get a real word',
  );
  
  @override
  bool validate(String word) {
    if (word.length < 2) return false;
    return _validWords.contains(word.substring(1).toLowerCase());
  }
}

class RemoveLastLetterIsValidConstraint extends Constraint {
  final Set<String> _validWords;
  
  RemoveLastLetterIsValidConstraint(this._validWords) : super(
    id: 'remove_last_letter_valid',
    tier: 4,
    displayText: 'Remove the last letter to get a real word',
  );
  
  @override
  bool validate(String word) {
    if (word.length < 2) return false;
    return _validWords.contains(word.substring(0, word.length - 1).toLowerCase());
  }
}

class ContainsHiddenWordConstraint extends Constraint {
  final String hiddenWord;
  
  ContainsHiddenWordConstraint(this.hiddenWord) : super(
    id: 'contains_hidden_${hiddenWord.toLowerCase()}',
    tier: 4,
    displayText: 'Contains the hidden word "${hiddenWord.toUpperCase()}"',
  );
  
  @override
  bool validate(String word) {
    return word.toLowerCase().contains(hiddenWord.toLowerCase()) &&
           word.toLowerCase() != hiddenWord.toLowerCase();
  }
}

class AddOneLetterIsWaterBodyConstraint extends Constraint {
  static const _waterBodies = {'lake', 'river', 'ocean', 'creek', 'brook', 'pond', 'bay', 'cove', 'inlet', 'fjord'};
  
  const AddOneLetterIsWaterBodyConstraint() : super(
    id: 'add_letter_makes_water',
    tier: 4,
    displayText: 'Add one letter anywhere to make a body of water',
  );
  
  @override
  bool validate(String word) {
    final lower = word.toLowerCase();
    for (final waterWord in _waterBodies) {
      if ((waterWord.length - lower.length) != 1) continue;
      // Check if lower can become waterWord by inserting one letter
      for (int i = 0; i <= lower.length; i++) {
        final candidate = lower.substring(0, i) + '?' + lower.substring(i);
        final pattern = candidate.replaceAll('?', '.');
        if (RegExp('^$pattern\$').hasMatch(waterWord)) return true;
      }
    }
    return false;
  }
}
```

---

### Tier 5 — Combined Constraints

```dart
class CombinedConstraint extends Constraint {
  final Constraint constraintA;
  final Constraint constraintB;
  
  CombinedConstraint({
    required this.constraintA,
    required this.constraintB,
  }) : super(
    id: '${constraintA.id}__AND__${constraintB.id}',
    tier: 5,
    displayText: '${constraintA.displayText} AND ${constraintB.displayText}',
  );
  
  @override
  bool validate(String word) {
    return constraintA.validate(word) && constraintB.validate(word);
  }
}

// Factory: build valid Tier 5 constraints only where enough valid words exist
List<CombinedConstraint> buildTier5Constraints({
  required List<Constraint> tier1,
  required List<Constraint> tier2,
  required List<Constraint> tier3,
  required List<String> answerWords,
  int minimumValidWords = 5,
}) {
  final candidates = [...tier1, ...tier2, ...tier3];
  final results = <CombinedConstraint>[];
  
  for (int i = 0; i < candidates.length; i++) {
    for (int j = i + 1; j < candidates.length; j++) {
      final combined = CombinedConstraint(
        constraintA: candidates[i],
        constraintB: candidates[j],
      );
      
      // Only include if enough valid answer words satisfy both constraints
      final validWords = combined.filterWordList(answerWords);
      if (validWords.length >= minimumValidWords) {
        results.add(combined);
      }
    }
  }
  
  return results;
}
```

---

### Constraint Library Registry

```dart
class ConstraintLibrary {
  late final List<Constraint> tier1;
  late final List<Constraint> tier2;
  late final List<Constraint> tier3;
  late final List<Constraint> tier4;
  late final List<Constraint> tier5;
  
  late final Map<String, Constraint> _byId;
  
  ConstraintLibrary.build({required List<String> answerWords, required Set<String> allValidWords}) {
    tier1 = tier1Constraints;
    tier2 = tier2Constraints;
    tier3 = [
      ...tier3ConstraintsBase,
      ReversalIsValidWordConstraint(allValidWords),
      ...buildAnagramConstraints(answerWords),
    ];
    tier4 = [
      RemoveFirstLetterIsValidConstraint(allValidWords),
      RemoveLastLetterIsValidConstraint(allValidWords),
      // ContainsHiddenWord constraints built per-puzzle based on available words
      const AddOneLetterIsWaterBodyConstraint(),
    ];
    tier5 = buildTier5Constraints(
      tier1: tier1,
      tier2: tier2,
      tier3: tier3,
      answerWords: answerWords,
    );
    
    _byId = {
      for (final c in [...tier1, ...tier2, ...tier3, ...tier4, ...tier5])
        c.id: c
    };
  }
  
  List<Constraint> forTier(int tier) => switch (tier) {
    1 => tier1,
    2 => tier2,
    3 => tier3,
    4 => tier4,
    5 => tier5,
    _ => throw ArgumentError('Invalid tier: $tier'),
  };
  
  Constraint? getById(String id) => _byId[id];
}
```

---

## CSP Solver — AC-3 + Backtracking

### Algorithm Overview

The most popular constraint propagation method is the AC-3 algorithm, which enforces arc consistency. Combined with backtracking, this is the standard approach for word puzzle generation.

Maintaining Arc Consistency (MAC) is the recommended approach — applying AC-3 after each variable assignment during backtracking search. This detects conflicts between future variables earlier, pruning the search tree before failures occur.

### Implementation

```dart
class CspSolver {
  final List<String> answerWords;
  final ConstraintLibrary constraintLibrary;
  final Random _random;
  
  CspSolver({
    required this.answerWords,
    required this.constraintLibrary,
    int? seed,
  }) : _random = seed != null ? Random(seed) : Random();
  
  /// Solve a puzzle skeleton — assign words to all slots satisfying all constraints
  /// Returns null if no solution exists within maxAttempts
  Puzzle? solve(PuzzleSkeleton skeleton, {int maxAttempts = 10000}) {
    final domains = _buildInitialDomains(skeleton);
    
    // Apply initial arc consistency (AC-3) before search begins
    if (!_enforceArcConsistency(domains, skeleton.intersections)) {
      return null; // Already inconsistent — no solution possible
    }
    
    // Check if AC-3 alone solved it
    if (domains.values.every((d) => d.length == 1)) {
      return _buildPuzzle(skeleton, domains.map((k, v) => MapEntry(k, v.first)));
    }
    
    // Backtracking search with MAC
    final assignment = <int, String>{};
    final result = _backtrack(assignment, domains, skeleton, maxAttempts, [0]);
    
    if (result == null) return null;
    return _buildPuzzle(skeleton, result);
  }
  
  /// Build initial domains for each word slot
  /// Apply unary constraints (each slot's own constraint) first
  Map<int, List<String>> _buildInitialDomains(PuzzleSkeleton skeleton) {
    final domains = <int, List<String>>{};
    
    for (final slot in skeleton.slots) {
      // Filter answer words by this slot's constraint
      var domain = slot.constraint.validator.filterWordList(answerWords);
      
      // Also apply length constraint if specified
      if (slot.requiredLength != null) {
        domain = domain.where((w) => w.length == slot.requiredLength).toList();
      }
      
      // Shuffle for variety between generation runs
      domain.shuffle(_random);
      
      domains[slot.id] = domain;
    }
    
    return domains;
  }
  
  /// AC-3 algorithm — enforces arc consistency across all intersections
  /// Returns false if a domain becomes empty (no solution possible)
  bool _enforceArcConsistency(
    Map<int, List<String>> domains,
    List<Intersection> intersections,
  ) {
    // Build worklist of all arcs (bidirectional)
    final worklist = Queue<(int, int, int, int)>();
    for (final ix in intersections) {
      worklist.add((ix.slotAId, ix.slotBId, ix.positionInA, ix.positionInB));
      worklist.add((ix.slotBId, ix.slotAId, ix.positionInB, ix.positionInA));
    }
    
    while (worklist.isNotEmpty) {
      final (xi, xj, posI, posJ) = worklist.removeFirst();
      
      if (_revise(domains, xi, xj, posI, posJ)) {
        if (domains[xi]!.isEmpty) return false; // Domain wiped out
        
        // Re-add arcs pointing to xi (its domain changed)
        for (final ix in intersections) {
          if (ix.slotBId == xi && ix.slotAId != xj) {
            worklist.add((ix.slotAId, xi, ix.positionInA, ix.positionInB));
          }
          if (ix.slotAId == xi && ix.slotBId != xj) {
            worklist.add((ix.slotBId, xi, ix.positionInB, ix.positionInA));
          }
        }
      }
    }
    
    return true;
  }
  
  /// Revise domain of xi based on constraint with xj at given intersection positions
  /// Returns true if any values were removed from xi's domain
  bool _revise(
    Map<int, List<String>> domains,
    int xi, int xj,
    int posI, int posJ,
  ) {
    final domainXj = domains[xj]!;
    final before = domains[xi]!.length;
    
    domains[xi] = domains[xi]!.where((wordI) {
      if (posI >= wordI.length) return false;
      final letterI = wordI[posI].toLowerCase();
      
      // Check if any word in xj's domain shares this letter at posJ
      return domainXj.any((wordJ) =>
        posJ < wordJ.length && wordJ[posJ].toLowerCase() == letterI
      );
    }).toList();
    
    return domains[xi]!.length < before;
  }
  
  /// Backtracking search with MAC (Maintaining Arc Consistency)
  Map<int, String>? _backtrack(
    Map<int, String> assignment,
    Map<int, List<String>> domains,
    PuzzleSkeleton skeleton,
    int maxAttempts,
    List<int> attemptCounter,
  ) {
    if (attemptCounter[0]++ > maxAttempts) return null;
    
    // All slots assigned — solution found
    if (assignment.length == skeleton.slots.length) return Map.of(assignment);
    
    // Select next unassigned slot (Most Constrained Variable heuristic)
    final slotId = _selectUnassignedSlot(assignment, domains, skeleton);
    
    for (final word in List.of(domains[slotId]!)) {
      if (_isConsistentWithAssignment(word, slotId, assignment, skeleton)) {
        assignment[slotId] = word;
        
        // Deep copy domains for MAC
        final domainsCopy = domains.map((k, v) => MapEntry(k, List.of(v)));
        domainsCopy[slotId] = [word]; // Fix this slot's domain to chosen word
        
        // Apply MAC — enforce arc consistency after this assignment
        if (_enforceArcConsistency(domainsCopy, skeleton.intersections)) {
          final result = _backtrack(assignment, domainsCopy, skeleton, maxAttempts, attemptCounter);
          if (result != null) return result;
        }
        
        assignment.remove(slotId);
      }
    }
    
    return null; // No valid assignment found — backtrack
  }
  
  /// Most Constrained Variable (MCV) heuristic — pick slot with smallest domain
  /// Ties broken by degree (most intersections)
  int _selectUnassignedSlot(
    Map<int, String> assignment,
    Map<int, List<String>> domains,
    PuzzleSkeleton skeleton,
  ) {
    return skeleton.slots
        .where((s) => !assignment.containsKey(s.id))
        .reduce((a, b) {
          final domainSizeA = domains[a.id]!.length;
          final domainSizeB = domains[b.id]!.length;
          if (domainSizeA != domainSizeB) {
            return domainSizeA < domainSizeB ? a : b;
          }
          // Tiebreak by degree (number of intersections)
          final degreeA = skeleton.intersections.where((i) => i.slotAId == a.id || i.slotBId == a.id).length;
          final degreeB = skeleton.intersections.where((i) => i.slotAId == b.id || i.slotBId == b.id).length;
          return degreeA > degreeB ? a : b;
        })
        .id;
  }
  
  /// Check if assigning this word to slotId is consistent with current assignment
  bool _isConsistentWithAssignment(
    String word,
    int slotId,
    Map<int, String> assignment,
    PuzzleSkeleton skeleton,
  ) {
    for (final intersection in skeleton.intersections) {
      int myPos, otherSlotId, otherPos;
      
      if (intersection.slotAId == slotId) {
        myPos = intersection.positionInA;
        otherSlotId = intersection.slotBId;
        otherPos = intersection.positionInB;
      } else if (intersection.slotBId == slotId) {
        myPos = intersection.positionInB;
        otherSlotId = intersection.slotAId;
        otherPos = intersection.positionInA;
      } else {
        continue;
      }
      
      if (!assignment.containsKey(otherSlotId)) continue;
      
      final otherWord = assignment[otherSlotId]!;
      if (myPos >= word.length || otherPos >= otherWord.length) return false;
      if (word[myPos].toLowerCase() != otherWord[otherPos].toLowerCase()) return false;
    }
    
    return true;
  }
  
  Puzzle _buildPuzzle(PuzzleSkeleton skeleton, Map<int, String> assignment) {
    // Build solved puzzle from skeleton + assignment
    // (implementation details)
  }
}
```

---

## Puzzle Validator

```dart
class PuzzleValidator {
  final CspSolver solver;
  final ProfanityFilter profanityFilter;
  
  PuzzleValidator({required this.solver, required this.profanityFilter});
  
  ValidationResult validate(Puzzle puzzle) {
    final issues = <String>[];
    
    // Check 1: Puzzle has at least one valid solution
    final solution = solver.solve(puzzle.toSkeleton());
    if (solution == null) {
      issues.add('No valid solution exists');
    }
    
    // Check 2: Solution space not trivially small (minimum 3 valid answers per slot)
    for (final slot in puzzle.wordSlots) {
      final validWords = slot.constraint.validator.filterWordList(solver.answerWords);
      if (validWords.length < 3) {
        issues.add('Slot ${slot.id} has fewer than 3 valid answer words');
      }
    }
    
    // Check 3: No profanity in any valid solution path
    if (solution != null) {
      for (final word in solution.wordSlots.map((s) => s.assignedWord!)) {
        if (profanityFilter.isBlocked(word)) {
          issues.add('Profanity detected in solution: $word');
        }
      }
    }
    
    // Check 4: Letter pool contains all required letters for the solution
    // (for early levels with guided letter pool)
    
    // Check 5: Puzzle is not trivially obvious (solution space not too small)
    // Only flag if solution space is extremely restricted
    
    return ValidationResult(
      isValid: issues.isEmpty,
      issues: issues,
    );
  }
}
```

---

## Puzzle Serialization

```dart
class PuzzleSerializer {
  static Map<String, dynamic> toJson(Puzzle puzzle) {
    return {
      'seed': puzzle.seed,
      'level_number': puzzle.levelNumber,
      'level_type': puzzle.levelType.name,
      'is_boss': puzzle.isBoss,
      'word_count': puzzle.wordCount,
      'intersection_count': puzzle.intersectionCount,
      'constraint_tiers': puzzle.constraintTiers,
      'word_slots': puzzle.wordSlots.map((slot) => {
        'id': slot.id,
        'constraint_id': slot.constraint.constraintId,
        'constraint_tier': slot.constraint.tier,
        'constraint_display': slot.constraint.displayText,
        'required_length': slot.requiredLength,
        'constraint_params': slot.constraint.params,
      }).toList(),
      'intersections': puzzle.intersections.map((ix) => {
        'slot_a': ix.slotAId,
        'slot_b': ix.slotBId,
        'position_in_a': ix.positionInA,
        'position_in_b': ix.positionInB,
      }).toList(),
      'letter_pool': puzzle.letterPool,
      'metadata': puzzle.metadata,
    };
  }
  
  static Puzzle fromJson(Map<String, dynamic> json, ConstraintLibrary library) {
    // Deserialize puzzle — look up constraints by ID from library
    // (implementation details)
  }
}
```

---

## Pre-Generation CLI Tool

```dart
// tools/generate_puzzles.dart
// Run: dart run tools/generate_puzzles.dart --output assets/puzzles/levels_001_200.json

import 'dart:io';
import 'dart:convert';

void main(List<String> args) async {
  print('Loading word lists...');
  final wordListLoader = WordListLoader();
  await wordListLoader.load();
  
  print('Building constraint library...');
  final constraintLibrary = ConstraintLibrary.build(
    answerWords: wordListLoader.answerWords,
    allValidWords: wordListLoader.allValidWords,
  );
  
  final solver = CspSolver(answerWords: wordListLoader.answerWords, constraintLibrary: constraintLibrary);
  final validator = PuzzleValidator(solver: solver, profanityFilter: ProfanityFilter());
  final generator = PreGenerator(solver: solver, validator: validator, constraintLibrary: constraintLibrary);
  
  print('Generating 200 levels...');
  final puzzles = <Map<String, dynamic>>[];
  int generated = 0;
  int rejected = 0;
  
  for (int level = 1; level <= 200; level++) {
    final difficulty = DifficultyProfile.forLevel(level);
    Puzzle? puzzle;
    int attempts = 0;
    
    while (puzzle == null && attempts < 50) {
      attempts++;
      final candidate = generator.generate(difficulty, seed: level * 1000 + attempts);
      final validation = validator.validate(candidate);
      
      if (validation.isValid) {
        puzzle = candidate;
      } else {
        rejected++;
        print('  Level $level attempt $attempts rejected: ${validation.issues}');
      }
    }
    
    if (puzzle == null) {
      print('  WARNING: Could not generate valid puzzle for level $level after 50 attempts');
      continue;
    }
    
    puzzles.add(PuzzleSerializer.toJson(puzzle));
    generated++;
    
    if (level % 10 == 0) print('  Generated $level/200 levels ($rejected rejected)');
  }
  
  // Write output
  final outputPath = args.contains('--output') 
      ? args[args.indexOf('--output') + 1]
      : 'assets/puzzles/levels_001_200.json';
  
  final output = File(outputPath);
  await output.writeAsString(JsonEncoder.withIndent('  ').convert({
    'generated_at': DateTime.now().toIso8601String(),
    'total_levels': generated,
    'total_rejected': rejected,
    'puzzles': puzzles,
  }));
  
  print('Done. Generated $generated puzzles, rejected $rejected candidates.');
  print('Output: $outputPath');
}
```

---

## Difficulty Profile

```dart
class DifficultyProfile {
  final int intersectionCount;
  final List<int> allowedConstraintTiers;
  final bool isBoss;
  final LevelType levelType;
  
  const DifficultyProfile({
    required this.intersectionCount,
    required this.allowedConstraintTiers,
    required this.isBoss,
    required this.levelType,
  });
  
  // Map level numbers to difficulty profiles
  static DifficultyProfile forLevel(int level) {
    final isBoss = _isBossLevel(level);
    
    return switch (level) {
      // Tutorial: 2 words, 1 intersection, Tier 1 only
      <= 5 => DifficultyProfile(
          intersectionCount: 1,
          allowedConstraintTiers: [1],
          isBoss: false,
          levelType: LevelType.sprint,
        ),
      // Early: introduce 2 intersections, still Tier 1
      <= 20 => DifficultyProfile(
          intersectionCount: isBoss ? 2 : 1,
          allowedConstraintTiers: [1],
          isBoss: isBoss,
          levelType: isBoss ? LevelType.puzzle : LevelType.sprint,
        ),
      // Tier 2 introduced
      <= 40 => DifficultyProfile(
          intersectionCount: isBoss ? 3 : 2,
          allowedConstraintTiers: [1, 2],
          isBoss: isBoss,
          levelType: isBoss ? LevelType.puzzle : _alternatingType(level),
        ),
      // Tier 3 introduced
      <= 70 => DifficultyProfile(
          intersectionCount: isBoss ? 4 : 2,
          allowedConstraintTiers: [1, 2, 3],
          isBoss: isBoss,
          levelType: isBoss ? LevelType.puzzle : _alternatingType(level),
        ),
      // Tier 4 introduced
      <= 100 => DifficultyProfile(
          intersectionCount: isBoss ? 4 : 3,
          allowedConstraintTiers: [2, 3, 4],
          isBoss: isBoss,
          levelType: isBoss ? LevelType.puzzle : _alternatingType(level),
        ),
      // Full difficulty — all tiers
      _ => DifficultyProfile(
          intersectionCount: isBoss ? 5 : 3,
          allowedConstraintTiers: [2, 3, 4, 5],
          isBoss: isBoss,
          levelType: isBoss ? LevelType.puzzle : _alternatingType(level),
        ),
    };
  }
  
  // bossLevel every 8–12 levels (random within range, seeded for reproducibility)
  static bool _isBossLevel(int level) {
    if (level < 6) return false;
    final rng = Random(level);
    final interval = 6 + rng.nextInt(10); // 6–15
    return level % interval == 0;
  }
  
  static LevelType _alternatingType(int level) {
    // Every 4th level is a Puzzle type, rest are Sprint
    return level % 4 == 0 ? LevelType.puzzle : LevelType.sprint;
  }
}
```

---

## Runtime Generator (theVault)

```dart
class RuntimeGenerator {
  final CspSolver solver;
  final PuzzleValidator validator;
  final ConstraintLibrary constraintLibrary;
  
  RuntimeGenerator({
    required this.solver,
    required this.validator,
    required this.constraintLibrary,
  });
  
  /// Generate a vault puzzle deterministically from user ID + vault level number
  /// Same inputs always produce same puzzle — reproducible without storing
  Puzzle generate({required String userId, required int vaultLevel}) {
    // Derive seed from userId + vaultLevel for reproducibility
    final seedString = '$userId:vault:$vaultLevel';
    final seed = seedString.hashCode.abs();
    
    // Vault uses full difficulty — all constraint tiers, 3–5 intersections
    final difficulty = DifficultyProfile(
      intersectionCount: 3 + (vaultLevel % 3), // cycles 3, 4, 5
      allowedConstraintTiers: [2, 3, 4, 5],
      isBoss: vaultLevel % 10 == 0, // vault bossLevel every 10 vault levels
      levelType: vaultLevel % 4 == 0 ? LevelType.puzzle : LevelType.sprint,
    );
    
    int attempts = 0;
    while (attempts < 100) {
      final puzzle = _generateAttempt(difficulty, seed + attempts);
      final validation = validator.validate(puzzle);
      if (validation.isValid) return puzzle;
      attempts++;
    }
    
    // Fallback: generate simpler puzzle if 100 attempts fail
    return _generateFallback(seed);
  }
}
```

---

## Test Suite Requirements

Every component requires comprehensive tests before the agent considers work complete.

```
test/puzzle_engine/
  word_list_test.dart
    ✓ Filter removes words shorter than 3 letters
    ✓ Filter removes words longer than 8 letters  
    ✓ Filter removes profanity
    ✓ Answer word list contains expected common words
    ✓ Category lists load correctly
    ✓ Category words are in answer list
  
  constraint_test.dart
    ✓ Each Tier 1 constraint validates known-good words
    ✓ Each Tier 1 constraint rejects known-bad words
    ✓ SameFirstLast: LEVEL passes, APPLE fails
    ✓ Palindrome: RACECAR passes, HELLO fails
    ✓ AnagramConstraint: STEAL passes for LEAST, STONE fails
    ✓ ReversalIsValid: STOP passes, HELLO fails
    ✓ CombinedConstraint: validates both constraints
    ✓ All constraints have non-empty filterWordList results on answer list
  
  csp_solver_test.dart
    ✓ Solves simple 2-word 1-intersection puzzle
    ✓ Solves 3-word 2-intersection puzzle
    ✓ Returns null for unsolvable skeleton
    ✓ Same seed produces same solution
    ✓ Different seeds produce different solutions
    ✓ AC-3 prunes domains correctly
    ✓ MCV heuristic selects most constrained slot
    ✓ Max attempts limit respected
  
  puzzle_validator_test.dart
    ✓ Valid puzzle passes validation
    ✓ Puzzle with no solution fails validation
    ✓ Puzzle with < 3 valid answer words per slot fails
    ✓ Puzzle with profanity in solution fails
  
  serialization_test.dart
    ✓ Puzzle serializes to valid JSON
    ✓ Puzzle deserializes correctly from JSON
    ✓ Round-trip: serialize then deserialize produces identical puzzle
  
  generation_test.dart
    ✓ Pre-generator produces 200 valid puzzles
    ✓ All boss levels are at correct intervals
    ✓ Difficulty increases monotonically through levels
    ✓ Runtime generator produces same puzzle for same userId + vaultLevel
    ✓ Runtime generator produces different puzzles for different vault levels
```

---

## Performance Requirements

- Pre-generation of 200 levels must complete in under 5 minutes on a standard dev machine
- Single puzzle generation must complete in under 2 seconds on-device (runtime/vault)
- Word list loading and filtering must complete in under 500ms on app startup
- Constraint validation for a single word must complete in under 1ms

---

## Deliverable Checklist

Before this agent's work is considered complete:

- [ ] All word list files created and filtered
- [ ] All 5 constraint tiers implemented and tested
- [ ] Tier 5 combined constraints generated and validated
- [ ] CspSolver implemented with AC-3 + MAC + MCV heuristic
- [ ] PuzzleValidator covers all 5 validation checks
- [ ] PuzzleSerializer round-trips correctly
- [ ] DifficultyProfile covers all level ranges
- [ ] Pre-generation CLI tool runs and produces `levels_001_200.json`
- [ ] RuntimeGenerator produces reproducible vault puzzles
- [ ] Full test suite passes with 100% pass rate
- [ ] Performance requirements met
- [ ] Output JSON validated against Supabase `puzzles` table schema

---

*This spec is the single source of truth for the Puzzle Generation agent. Do not make architectural decisions not covered here — raise them in the GDD first.*
