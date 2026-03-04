import 'package:puzzle_game/puzzle_engine/constraints/constraint.dart';

class ConstraintAssignment {
  final int tier;
  final String constraintId;
  final String displayText;
  final Constraint validator;
  final Map<String, dynamic>? params;

  ConstraintAssignment({
    required this.tier,
    required this.constraintId,
    required this.displayText,
    required this.validator,
    this.params,
  });
}
