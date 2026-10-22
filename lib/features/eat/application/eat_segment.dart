import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';

/// Which browsing page of Eat: Foods or Recipes.
enum EatSegment { foods, recipes }

/// Opens the Foods or Recipes page of Eat. The Eat hub stays underneath, so
/// Back returns to it.
void goEat(BuildContext context, EatSegment segment) => context.go(
  segment == EatSegment.foods ? Routes.eatFoods : Routes.eatRecipes,
);
