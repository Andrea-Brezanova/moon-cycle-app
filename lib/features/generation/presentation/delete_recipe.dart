import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/personal_recipe_repository.dart';
import '../domain/personal_recipe.dart';

/// Asks before deleting a recipe the user wrote, and deletes it only on
/// "Delete". Returns whether it was deleted. Built-in recipes are never passed
/// here; a hearted one is removed from Saved instead.
Future<bool> confirmDeleteRecipe(
  BuildContext context,
  WidgetRef ref,
  PersonalRecipe recipe,
) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete this recipe?'),
      content: Text(
        '“${recipe.recipe.title}” will be removed from your recipes.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Keep it'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  if (ok != true) return false;
  await ref
      .read(personalRecipeRepositoryProvider)
      .delete(recipe.ownerId, recipe.id);
  return true;
}
