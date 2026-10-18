import 'package:flutter/widgets.dart';

import '../../../content/domain/recipe.dart';
import '../../../discovery/domain/recipe_source.dart';

/// The picture for [recipe]: its bundled photo, the provider's photo for an
/// external recipe **when its terms allow showing it**, or null (the tinted
/// Moon Cycle placeholder). Personal (`u-…`) recipes have no bundled photo. An
/// external picture is only ever shown from the provider's own URL: it is never
/// downloaded or stored.
ImageProvider? recipeImage(Recipe recipe, {RecipeRights? rights}) {
  if (recipe.id.startsWith('x-')) {
    final url = recipe.imageUrl;
    return (rights?.mayShowImage ?? false) && url != null
        ? NetworkImage(url)
        : null;
  }
  return recipe.id.startsWith('u-') ? null : AssetImage(recipe.imageAsset);
}
