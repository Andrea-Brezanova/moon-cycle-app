import 'package:flutter/widgets.dart';

import '../../../content/domain/recipe.dart';

/// The picture for [recipe]: its bundled photo, or null (the tinted
/// placeholder) for a recipe that has none. Personal (`u-…`) and external
/// (`x-…`) recipes have no bundled photo; a stored picture reference is
/// attached here when image generation is connected.
ImageProvider? recipeImage(Recipe recipe) =>
    recipe.id.startsWith('u-') || recipe.id.startsWith('x-')
    ? null
    : AssetImage(recipe.imageAsset);
