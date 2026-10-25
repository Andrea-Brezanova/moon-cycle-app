import 'package:flutter/material.dart';

import '../../../core/design/widgets/dimmed_photo.dart';
import '../application/collections_providers.dart';

/// The photograph for each category, from the app's existing images (the same
/// ones Home and Eat use). Decorative: always hidden from screen readers.
String collectionPhoto(CollectionCategory c) => switch (c) {
  CollectionCategory.recipes =>
    'assets/images/recipes/red-cabbage-apricot-chickpea-salad.jpg',
  CollectionCategory.workouts => 'assets/images/home/home_move_yoga_mat.jpg',
  CollectionCategory.spa => 'assets/images/home/home_relax_tea.jpg',
};

/// A category photograph, cropped to fill its box and dimmed a little in dark
/// mode like every photo in the app.
class CollectionPhoto extends StatelessWidget {
  const CollectionPhoto(this.category, {super.key, this.alignment});

  final CollectionCategory category;
  final Alignment? alignment;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: DimmedPhoto(
      dim: Theme.of(context).brightness == Brightness.dark,
      child: Image.asset(
        collectionPhoto(category),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        alignment: alignment ?? Alignment.center,
      ),
    ),
  );
}
