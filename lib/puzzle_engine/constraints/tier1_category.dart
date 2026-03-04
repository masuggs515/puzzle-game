import 'package:puzzle_game/puzzle_engine/constraints/constraint.dart';
import 'package:puzzle_game/puzzle_engine/word_list/word_list_loader.dart';

/// A constraint that checks membership in a semantic category.
class CategoryConstraint extends Constraint {
  final String categoryName;

  const CategoryConstraint({
    required super.id,
    required super.displayText,
    required this.categoryName,
  }) : super(tier: 1);

  @override
  bool validate(String word) {
    final categoryWords = CategoryListLoader.get(categoryName);
    return categoryWords.contains(word.toLowerCase());
  }
}

/// All Tier 1 category constraints.
final List<CategoryConstraint> tier1Constraints = [
  const CategoryConstraint(
    id: 'is_animal',
    displayText: 'A type of animal',
    categoryName: 'animals',
  ),
  const CategoryConstraint(
    id: 'is_color',
    displayText: 'A color',
    categoryName: 'colors',
  ),
  const CategoryConstraint(
    id: 'is_food',
    displayText: 'A type of food',
    categoryName: 'foods',
  ),
  const CategoryConstraint(
    id: 'is_country',
    displayText: 'A country',
    categoryName: 'countries',
  ),
  const CategoryConstraint(
    id: 'is_vegetable',
    displayText: 'A type of vegetable',
    categoryName: 'vegetables',
  ),
  const CategoryConstraint(
    id: 'is_sport',
    displayText: 'A sport or activity',
    categoryName: 'sports',
  ),
  const CategoryConstraint(
    id: 'is_body_part',
    displayText: 'A body part',
    categoryName: 'body_parts',
  ),
  const CategoryConstraint(
    id: 'is_weather',
    displayText: 'A weather word',
    categoryName: 'weather',
  ),
  const CategoryConstraint(
    id: 'is_vehicle',
    displayText: 'A vehicle',
    categoryName: 'vehicles',
  ),
  const CategoryConstraint(
    id: 'is_clothing',
    displayText: 'An item of clothing',
    categoryName: 'clothing',
  ),
  const CategoryConstraint(
    id: 'is_fruit',
    displayText: 'A type of fruit',
    categoryName: 'fruits',
  ),
  const CategoryConstraint(
    id: 'is_water_body',
    displayText: 'A body of water',
    categoryName: 'water_bodies',
  ),
  const CategoryConstraint(
    id: 'is_kitchen_item',
    displayText: 'A kitchen item',
    categoryName: 'kitchen_items',
  ),
];
