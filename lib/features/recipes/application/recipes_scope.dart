import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/browse_scope.dart';

/// "This phase" or "All recipes" on Recipes. Session state; the phase itself
/// is the shared viewing phase.
final recipesScopeProvider = NotifierProvider<RecipesScope, BrowseScope>(
  RecipesScope.new,
);

class RecipesScope extends Notifier<BrowseScope> {
  @override
  BrowseScope build() => BrowseScope.phase;

  void set(BrowseScope scope) => state = scope;
  void showAll() => state = BrowseScope.all;
}
