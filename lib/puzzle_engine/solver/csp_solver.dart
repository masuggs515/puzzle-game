import 'dart:collection';
import 'dart:math';

import 'package:puzzle_game/puzzle_engine/constraints/constraint_library.dart';
import 'package:puzzle_game/puzzle_engine/models/puzzle.dart';

/// AC-3 + backtracking CSP solver for puzzle word assignment.
class CspSolver {
  final List<String> answerWords;
  final ConstraintLibrary constraintLibrary;
  final int _seed;
  final int maxAttempts;

  CspSolver({
    required this.answerWords,
    required this.constraintLibrary,
    int? seed,
    this.maxAttempts = 50000,
  }) : _seed = seed ?? 0;

  /// Attempt to solve the given [skeleton].
  /// Returns a [Puzzle] with all words assigned, or null if unsolvable.
  Puzzle? solve(PuzzleSkeleton skeleton) {
    // Step 1: Build initial domains for each slot
    final domains = <int, List<String>>{};
    for (final slot in skeleton.slots) {
      var domain = slot.constraint.validator.filterWordList(answerWords);
      if (slot.requiredLength != null) {
        domain = domain.where((w) => w.length == slot.requiredLength).toList();
      }
      // Shuffle deterministically using seed
      domain = _shuffleWithSeed(domain, _seed ^ slot.id);
      domains[slot.id] = domain;
    }

    // Step 2: AC-3 arc consistency
    if (!_applyAC3(skeleton, domains)) {
      return null; // Domains became empty — unsolvable
    }

    // Step 3: Backtracking search
    final counter = [0]; // mutable attempt counter shared across all recursion
    final assignment = <int, String>{};
    final result = _backtrack(skeleton, domains, assignment, counter);
    if (result == null) return null;

    return _buildPuzzle(skeleton, result);
  }

  /// Apply AC-3 arc consistency to prune domains.
  bool _applyAC3(PuzzleSkeleton skeleton, Map<int, List<String>> domains) {
    // Build queue of all arcs (both directions for each intersection)
    final queue = Queue<(int slotA, int posA, int slotB, int posB)>();

    for (final intersection in skeleton.intersections) {
      queue.add((
        intersection.slotAId,
        intersection.positionInA,
        intersection.slotBId,
        intersection.positionInB,
      ));
      queue.add((
        intersection.slotBId,
        intersection.positionInB,
        intersection.slotAId,
        intersection.positionInA,
      ));
    }

    while (queue.isNotEmpty) {
      final (slotA, posA, slotB, posB) = queue.removeFirst();
      if (_revise(domains, slotA, posA, slotB, posB)) {
        if (domains[slotA]!.isEmpty) return false;
        // Re-add all arcs pointing to slotA (except from slotB)
        for (final intersection in skeleton.intersections) {
          if (intersection.slotAId == slotA && intersection.slotBId != slotB) {
            queue.add((
              intersection.slotBId,
              intersection.positionInB,
              intersection.slotAId,
              intersection.positionInA,
            ));
          }
          if (intersection.slotBId == slotA && intersection.slotAId != slotB) {
            queue.add((
              intersection.slotAId,
              intersection.positionInA,
              intersection.slotBId,
              intersection.positionInB,
            ));
          }
        }
      }
    }
    return true;
  }

  /// Revise domain of slotA based on constraint with slotB.
  /// Returns true if any values were removed.
  bool _revise(
    Map<int, List<String>> domains,
    int slotA,
    int posA,
    int slotB,
    int posB,
  ) {
    final domainA = domains[slotA]!;
    final domainB = domains[slotB]!;
    final newDomainA = <String>[];

    for (final wordA in domainA) {
      if (posA >= wordA.length) continue;
      final charA = wordA[posA].toLowerCase();
      // Check if there exists at least one word in B that is compatible
      final compatible = domainB.any((wordB) {
        if (posB >= wordB.length) return false;
        return wordB[posB].toLowerCase() == charA;
      });
      if (compatible) newDomainA.add(wordA);
    }

    if (newDomainA.length == domainA.length) return false;
    domains[slotA] = newDomainA;
    return true;
  }

  /// Backtracking search. Returns assignment map or null.
  Map<int, String>? _backtrack(
    PuzzleSkeleton skeleton,
    Map<int, List<String>> domains,
    Map<int, String> assignment,
    List<int> counter, // mutable attempt counter shared across recursion
  ) {
    if (assignment.length == skeleton.slots.length) {
      return Map.of(assignment);
    }

    if (counter[0]++ > maxAttempts) return null;

    // Select unassigned variable with smallest domain (MRV heuristic)
    final unassigned = skeleton.slots
        .where((s) => !assignment.containsKey(s.id))
        .toList();

    unassigned.sort((a, b) {
      final da = domains[a.id]?.length ?? 0;
      final db = domains[b.id]?.length ?? 0;
      return da.compareTo(db);
    });

    final selected = unassigned.first;
    final domain = List<String>.of(domains[selected.id] ?? []);

    for (final word in domain) {
      if (_isConsistentWithAssignment(
          selected.id, word, assignment, skeleton)) {
        assignment[selected.id] = word;

        // Forward checking — prune domains of unassigned neighbours
        final savedDomains = <int, List<String>>{};
        bool domainCollapse = false;

        for (final intersection in skeleton.intersections) {
          int? neighbourId;
          int? posInNeighbour;
          int? posInSelected;

          if (intersection.slotAId == selected.id) {
            neighbourId = intersection.slotBId;
            posInNeighbour = intersection.positionInB;
            posInSelected = intersection.positionInA;
          } else if (intersection.slotBId == selected.id) {
            neighbourId = intersection.slotAId;
            posInNeighbour = intersection.positionInA;
            posInSelected = intersection.positionInB;
          }

          if (neighbourId == null || assignment.containsKey(neighbourId)) {
            continue;
          }

          final charAtPos = posInSelected! < word.length
              ? word[posInSelected].toLowerCase()
              : null;
          if (charAtPos == null) continue;

          savedDomains[neighbourId] = List<String>.of(domains[neighbourId]!);
          domains[neighbourId] = domains[neighbourId]!
              .where((w) =>
                  posInNeighbour! < w.length &&
                  w[posInNeighbour].toLowerCase() == charAtPos)
              .toList();

          if (domains[neighbourId]!.isEmpty) {
            domainCollapse = true;
            break;
          }
        }

        if (!domainCollapse) {
          final result = _backtrack(
            skeleton,
            domains,
            assignment,
            counter,
          );
          if (result != null) return result;
        }

        // Restore domains
        for (final entry in savedDomains.entries) {
          domains[entry.key] = entry.value;
        }
        assignment.remove(selected.id);
      }
    }

    return null;
  }

  /// Check if [word] assigned to [slotId] is consistent with current assignment.
  bool _isConsistentWithAssignment(
    int slotId,
    String word,
    Map<int, String> assignment,
    PuzzleSkeleton skeleton,
  ) {
    // Check all intersections involving this slot
    for (final intersection in skeleton.intersections) {
      int? otherSlotId;
      int? posInThis;
      int? posInOther;

      if (intersection.slotAId == slotId) {
        otherSlotId = intersection.slotBId;
        posInThis = intersection.positionInA;
        posInOther = intersection.positionInB;
      } else if (intersection.slotBId == slotId) {
        otherSlotId = intersection.slotAId;
        posInThis = intersection.positionInB;
        posInOther = intersection.positionInA;
      }

      if (otherSlotId == null || !assignment.containsKey(otherSlotId)) {
        continue;
      }

      final otherWord = assignment[otherSlotId]!;
      if (posInThis! >= word.length || posInOther! >= otherWord.length) {
        return false;
      }
      if (word[posInThis].toLowerCase() != otherWord[posInOther].toLowerCase()) {
        return false;
      }
    }

    // No duplicate words
    if (assignment.values.contains(word.toLowerCase())) return false;

    return true;
  }

  /// Shuffle a list deterministically with the given seed.
  List<T> _shuffleWithSeed<T>(List<T> list, int seed) {
    final rng = Random(seed);
    final result = List<T>.of(list);
    for (int i = result.length - 1; i > 0; i--) {
      final j = rng.nextInt(i + 1);
      final temp = result[i];
      result[i] = result[j];
      result[j] = temp;
    }
    return result;
  }

  /// Build a [Puzzle] from the skeleton and the word assignment.
  Puzzle _buildPuzzle(PuzzleSkeleton skeleton, Map<int, String> assignment) {
    final wordSlots = skeleton.slots.map((spec) => WordSlot(
          id: spec.id,
          constraint: spec.constraint,
          requiredLength: spec.requiredLength,
          assignedWord: assignment[spec.id],
        )).toList();

    // Build letter pool from all unique letters in solution
    final allLetters = assignment.values
        .expand((w) => w.toLowerCase().split(''))
        .toSet()
        .toList()
      ..sort();

    final tiers =
        wordSlots.map((s) => s.constraint.tier).toSet().toList()..sort();

    return Puzzle(
      seed: assignment.values.join('-'),
      levelNumber: null,
      levelType: LevelType.sprint,
      isBoss: false,
      wordSlots: wordSlots,
      intersections: skeleton.intersections,
      letterPool: allLetters,
      constraintTiers: tiers,
      metadata: {'generated': DateTime.now().toIso8601String()},
    );
  }
}
