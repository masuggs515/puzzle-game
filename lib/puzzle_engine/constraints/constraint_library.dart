import 'package:puzzle_game/puzzle_engine/constraints/constraint.dart';
import 'package:puzzle_game/puzzle_engine/constraints/tier1_category.dart';
import 'package:puzzle_game/puzzle_engine/constraints/tier2_letter_rules.dart';
import 'package:puzzle_game/puzzle_engine/constraints/tier3_wordplay.dart';
import 'package:puzzle_game/puzzle_engine/constraints/tier4_container.dart';
import 'package:puzzle_game/puzzle_engine/constraints/tier5_combined.dart';

class ConstraintLibrary {
  final Map<String, Constraint> _byId;
  final Map<int, List<Constraint>> _byTier;

  ConstraintLibrary._({
    required Map<String, Constraint> byId,
    required Map<int, List<Constraint>> byTier,
  })  : _byId = byId,
        _byTier = byTier;

  /// Build the full constraint library.
  /// [validWords] is needed for container/wordplay constraints that check
  /// against the dictionary.
  factory ConstraintLibrary.build({Set<String> validWords = const {}}) {
    final all = <Constraint>[];

    // Tier 1 — category constraints
    all.addAll(tier1Constraints);

    // Tier 2 — structural constraints
    all.addAll(tier2Constraints);

    // Tier 3 — wordplay
    all.addAll(tier3ConstraintsBase);
    all.add(ReversalIsValidWordConstraint(validWords: validWords));
    all.addAll(buildAnagramConstraints());

    // Tier 4 — container / positional
    all.add(RemoveFirstLetterIsValidConstraint(validWords: validWords));
    all.add(RemoveLastLetterIsValidConstraint(validWords: validWords));
    all.add(ContainsHiddenWordConstraint(validWords: validWords));
    all.add(AddOneLetterIsWaterBodyConstraint());

    // Common positional constraints (letters a-z)
    for (final letter in 'abcdefghijklmnoprstw'.split('')) {
      all.add(StartsWithLetterConstraint(letter));
      all.add(EndsWithLetterConstraint(letter));
      all.add(ContainsLetterConstraint(letter));
    }

    // Tier 5 — combined
    all.addAll(buildTier5Constraints(all));

    // Compound word constraint (tier 5)
    all.add(IsCompoundWordConstraint(validWords: validWords));

    final byId = <String, Constraint>{};
    final byTier = <int, List<Constraint>>{};

    for (final c in all) {
      byId[c.id] = c;
      byTier.putIfAbsent(c.tier, () => []).add(c);
    }

    return ConstraintLibrary._(byId: byId, byTier: byTier);
  }

  /// Get all constraints for a given tier.
  List<Constraint> forTier(int tier) => List.unmodifiable(_byTier[tier] ?? []);

  /// Get a constraint by its ID. Returns null if not found.
  Constraint? getById(String id) => _byId[id];

  /// All constraint IDs.
  Iterable<String> get ids => _byId.keys;

  /// All constraints.
  Iterable<Constraint> get all => _byId.values;
}
