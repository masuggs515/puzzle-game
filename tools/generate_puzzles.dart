// ignore_for_file: avoid_print
import 'dart:io';

import 'package:puzzle_game/puzzle_engine/constraints/constraint_library.dart';
import 'package:puzzle_game/puzzle_engine/generation/difficulty_profile.dart';
import 'package:puzzle_game/puzzle_engine/generation/pre_generator.dart';
import 'package:puzzle_game/puzzle_engine/models/puzzle.dart';
import 'package:puzzle_game/puzzle_engine/serialization/puzzle_serializer.dart';
import 'package:puzzle_game/puzzle_engine/solver/csp_solver.dart';
import 'package:puzzle_game/puzzle_engine/validation/puzzle_validator.dart';
import 'package:puzzle_game/puzzle_engine/word_list/word_list_loader.dart';

void main(List<String> args) async {
  // Parse arguments
  String output = 'assets/puzzles/levels_001_200.json';
  int count = 200;
  int seed = 42;
  bool dryRun = false;
  String wordListBasePath = 'assets/word_lists';

  for (int i = 0; i < args.length; i++) {
    switch (args[i]) {
      case '--output':
        output = args[++i];
      case '--count':
        count = int.parse(args[++i]);
      case '--seed':
        seed = int.parse(args[++i]);
      case '--dry-run':
        dryRun = true;
      case '--word-list-path':
        wordListBasePath = args[++i];
    }
  }

  print('Puzzle Generator');
  print('  Output:    $output');
  print('  Count:     $count');
  print('  Seed:      $seed');
  print('  Dry run:   $dryRun');
  print('  Word path: $wordListBasePath');
  print('');

  // Load word lists (also preloads category lists)
  print('Loading word lists...');
  final wordListLoader = WordListLoader.fromFiles(basePath: wordListBasePath);
  print('  Answer words:     ${wordListLoader.answerWords.length}');
  print('  All valid words:  ${wordListLoader.allValidWords.length}');
  print('');

  // Build constraint library
  print('Building constraint library...');
  final constraintLibrary = ConstraintLibrary.build(
    validWords: wordListLoader.allValidWords,
  );
  print('  Constraints loaded: ${constraintLibrary.ids.length}');
  print('');

  // Build solver
  final solver = CspSolver(
    answerWords: wordListLoader.answerWords,
    constraintLibrary: constraintLibrary,
    seed: seed,
  );

  final validator = PuzzleValidator(
    answerWordSet: wordListLoader.answerWords.toSet(),
    allValidWords: wordListLoader.allValidWords,
  );

  final generator = PreGenerator(
    solver: solver,
    validator: validator,
    constraintLibrary: constraintLibrary,
  );

  final serializer = PuzzleSerializer(library: constraintLibrary);

  // Generate puzzles
  print('Generating $count puzzles...');
  final puzzles = <Puzzle>[];
  int failures = 0;
  final stopwatch = Stopwatch()..start();

  for (int level = 1; level <= count; level++) {
    final levelSeed = seed + level * 7919; // Different seed per level
    final difficulty = DifficultyProfile.forLevel(level);

    Puzzle? puzzle;
    int retries = 0;
    while (puzzle == null && retries < 5) {
      puzzle = generator.generate(difficulty, seed: levelSeed + retries);
      retries++;
    }

    if (puzzle == null) {
      print('  FAILED level $level (exhausted retries)');
      failures++;
      continue;
    }

    // Assign level number
    puzzle = Puzzle(
      seed: puzzle.seed,
      levelNumber: level,
      levelType: puzzle.levelType,
      isBoss: puzzle.isBoss,
      wordSlots: puzzle.wordSlots,
      intersections: puzzle.intersections,
      letterPool: puzzle.letterPool,
      constraintTiers: puzzle.constraintTiers,
      metadata: puzzle.metadata,
    );

    // Validate
    final result = validator.validate(puzzle);
    if (!result.isValid) {
      print('  INVALID level $level: ${result.issues.join(', ')}');
      failures++;
      continue;
    }

    puzzles.add(puzzle);

    if (level % 10 == 0) {
      print('  Generated $level/$count puzzles...');
    }
  }

  stopwatch.stop();
  final elapsed = stopwatch.elapsedMilliseconds;
  final perPuzzle = puzzles.isNotEmpty ? elapsed ~/ puzzles.length : 0;

  print('');
  print('Generation complete:');
  print('  Puzzles generated: ${puzzles.length}');
  print('  Failures:          $failures');
  print('  Total time:        ${elapsed}ms');
  print('  Time per puzzle:   ${perPuzzle}ms');
  print('');

  if (dryRun) {
    print('Dry run — not writing output file.');
    exit(failures > 0 ? 1 : 0);
  }

  // Write output
  print('Writing output to $output...');
  final outputFile = File(output);
  outputFile.parent.createSync(recursive: true);
  outputFile.writeAsStringSync(serializer.serializeLevelFile(puzzles));
  print('Done. Wrote ${puzzles.length} puzzles to $output');

  exit(failures > 0 ? 1 : 0);
}
