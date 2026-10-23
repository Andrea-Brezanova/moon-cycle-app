import 'package:flutter/widgets.dart';

import '../../foods/presentation/foods_page.dart';
import '../../recipes/presentation/recipes_page.dart';
import '../application/eat_segment.dart';

/// The Foods or Recipes screen, opened from the Eat hub. Each draws its own
/// header (back to Eat, title, search).
class EatBrowsePage extends StatelessWidget {
  const EatBrowsePage({super.key, required this.segment});

  final EatSegment segment;

  @override
  Widget build(BuildContext context) => switch (segment) {
    EatSegment.foods => const FoodsPage(),
    EatSegment.recipes => const RecipesPage(),
  };
}
