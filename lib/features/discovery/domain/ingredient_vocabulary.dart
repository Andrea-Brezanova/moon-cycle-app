import '../../content/domain/food.dart';

/// How an external ingredient line was understood.
enum IngredientKind {
  /// The same food as a Moon Cycle food (a different name, spelling or variety
  /// of it). Counts as that food for matching.
  food,

  /// A plain pantry item with no allergen or animal source (salt, water, a
  /// single dried spice). Never counts as a chosen food and never blocks a
  /// recipe.
  pantrySafe,

  /// Not a Moon Cycle food, but its allergens and animal source are known for
  /// certain (chicken stock, soy sauce, butter-like dairy, wheat pasta). It can
  /// be checked against a diet or allergy, but never counts as a chosen food.
  derived,

  /// Named on purpose as unsafe to assume: it can hide an allergen or animal
  /// product (vegetable oil, wine, curry powder, sauces). Needs a human to rule
  /// on it; until then a recipe with it is not shown to a user with restrictions.
  ambiguous,

  /// Not recognised at all.
  unknown,
}

/// What is known for sure about a [IngredientKind.derived] ingredient.
final class Derived {
  const Derived({
    this.allergens = const {},
    this.animal = AnimalSource.none,
    this.aisle = 'pantry',
  });

  final Set<String> allergens;
  final AnimalSource animal;
  final String aisle;
}

/// A reviewed, dedicated vocabulary for external ingredient names. Everything
/// here is a deliberate decision; nothing is inferred from shared words.
///
/// Keys are already normalised (lower case, single spaces, no punctuation).
/// A test checks that every food id used here exists in the catalogue and that
/// no entry appears in two classes.
abstract final class IngredientVocabulary {
  /// Another name, spelling, form or variety of a Moon Cycle food, **with the
  /// same allergens and animal source**. Related-but-different items are not
  /// here (cashew butter, coconut milk, chicken stock).
  static const aliases = <String, String>{
    // Spellings and regional names.
    'black eyed peas': 'black-eyed-pea',
    'black eyed pea': 'black-eyed-pea',
    'egg plant': 'eggplant',
    'egg plants': 'eggplant',
    'courgette': 'zucchini',
    'courgettes': 'zucchini',
    'rocket': 'arugula',
    'coriander leaves': 'cilantro',
    'fresh coriander': 'cilantro',
    'spring onion': 'scallion',
    'spring onions': 'scallion',
    'green onion': 'scallion',
    'green onions': 'scallion',
    'chickpeas': 'chickpea',
    'natural yoghurt': 'plain-yogurt',
    'plain yoghurt': 'plain-yogurt',
    'sweetcorn': 'corn',
    'pak choi': 'bok-choy',
    'cashew nuts': 'cashew',
    'petit pois': 'green-pea',
    'savoy cabbage': 'cabbage',
    'sesame seed': 'sesame-seeds',
    'garbanzo beans': 'chickpea',
    'prawns': 'shrimp',
    'raw prawns': 'shrimp',
    'raw king prawns': 'shrimp',
    'raw tiger prawns': 'shrimp',
    'king prawns': 'shrimp',
    'tiger prawns': 'shrimp',
    'beetroot': 'beets',
    // Varieties of the same food.
    'potato': 'white-potato',
    'potatoes': 'white-potato',
    'new potatoes': 'white-potato',
    'red onion': 'onion',
    'red onions': 'onion',
    'white onion': 'onion',
    'yellow onion': 'onion',
    'brown onion': 'onion',
    'plum tomatoes': 'tomato',
    'plum tomato': 'tomato',
    'cherry tomatoes': 'tomato',
    'cherry tomato': 'tomato',
    'vine tomatoes': 'tomato',
    'tinned tomatoes': 'canned-tomatoes',
    'tinned tomatos': 'canned-tomatoes',
    'chopped tomatoes': 'canned-tomatoes',
    'canned tomatoes': 'canned-tomatoes',
    'red chilli': 'chili-pepper',
    'green chilli': 'chili-pepper',
    'red chili': 'chili-pepper',
    'green chili': 'chili-pepper',
    'chilli': 'chili-pepper',
    'chili': 'chili-pepper',
    'jalapeno': 'chili-pepper',
    'red pepper': 'red-bell-pepper',
    'green pepper': 'green-bell-pepper',
    'yellow pepper': 'yellow-bell-pepper',
    'red bell pepper': 'red-bell-pepper',
    'green bell pepper': 'green-bell-pepper',
    'yellow bell pepper': 'yellow-bell-pepper',
    'black olives': 'olives',
    'green olives': 'olives',
    'shiitake mushrooms': 'mushrooms',
    'cannellini beans': 'white-beans',
    'butter beans': 'lima-bean',
    'extra virgin olive oil': 'olive-oil',
    'garlic clove': 'garlic',
    'garlic cloves': 'garlic',
    'basil leaves': 'basil',
    'unsalted butter': 'butter',
    'salted butter': 'butter',
    'plain flour': 'wheat-flour',
    'all purpose flour': 'wheat-flour',
    'macaroni': 'pasta',
    'spaghetti': 'pasta',
    'penne': 'pasta',
    // Forms of the same food (same allergens and animal source).
    'lemon juice': 'lemon',
    'lime juice': 'lime',
    'ground pork': 'pork',
    'pork mince': 'pork',
    'minced pork': 'pork',
    'ground beef': 'beef',
    'beef mince': 'beef',
    'minced beef': 'beef',
    'sirloin steak': 'beef',
    'lamb mince': 'lamb',
    'minced lamb': 'lamb',
    'ground lamb': 'lamb',
  };

  /// Allergens that the reviewed dataset leaves off a food but that are known
  /// to be present. External lines for these foods carry them, so an avoider is
  /// still protected. The dataset itself is untouched; these are reported for
  /// review (see `docs/ingredient-mapping.md`).
  static const allergenOverrides = <String, Set<String>>{
    'wheat-flour': {'gluten'},
  };

  /// Plain pantry items that carry none of the allergens we track and no animal
  /// source. Deliberately short.
  static const pantrySafe = <String>{
    'water', 'cold water', 'warm water', 'hot water', 'ice',
    'salt', 'sea salt', 'kosher salt', 'flaky salt', 'table salt',
    'fine salt', 'fine sea salt',
    'pepper', 'black pepper', 'white pepper', 'ground black pepper',
    'sugar', 'brown sugar', 'caster sugar', 'icing sugar', 'granulated sugar',
    'baking soda',
    'bicarbonate of soda',
    'cornstarch',
    'corn flour',
    'cornflour',
    // Single dried herbs and spices (no mixes).
    'paprika', 'smoked paprika', 'cumin', 'ground cumin', 'cumin seeds',
    'cinnamon', 'ground cinnamon', 'nutmeg', 'allspice', 'cloves',
    'cayenne pepper', 'chilli powder', 'chili powder', 'chilli flakes',
    'chili flakes', 'red pepper flakes', 'turmeric', 'ground turmeric',
    'ground coriander', 'coriander seeds', 'cardamom', 'bay leaf', 'bay leaves',
    'thyme', 'dried thyme', 'oregano', 'dried oregano', 'rosemary', 'sage',
    'dill', 'saffron', 'vanilla extract',
    // Plain vinegars and oils that are not on the allergen list.
    'garlic powder', 'ground ginger', 'onion powder', 'balsamic vinegar',
    'sherry vinegar',
    'rice vinegar',
    'white wine vinegar',
    'red wine vinegar',
    'cider vinegar',
    'apple cider vinegar', 'white vinegar',
    'sunflower oil', 'rapeseed oil', 'canola oil', 'olive oil spray',
  };

  /// Known properties for ingredients that are not Moon Cycle foods.
  static const derived = <String, Derived>{
    'chicken stock': Derived(animal: AnimalSource.meat),
    'beef stock': Derived(animal: AnimalSource.meat),
    'lamb stock': Derived(animal: AnimalSource.meat),
    'pork stock': Derived(animal: AnimalSource.meat),
    'fish stock': Derived(animal: AnimalSource.seafood, allergens: {'fish'}),
    'vegetable stock': Derived(allergens: {'gluten'}), // cubes often contain it
    'stock': Derived(animal: AnimalSource.meat),
    // Broth is the same product as stock (seen in Recipe API: "chicken broth").
    'chicken broth': Derived(animal: AnimalSource.meat),
    'beef broth': Derived(animal: AnimalSource.meat),
    'lamb broth': Derived(animal: AnimalSource.meat),
    'pork broth': Derived(animal: AnimalSource.meat),
    'fish broth': Derived(animal: AnimalSource.seafood, allergens: {'fish'}),
    'vegetable broth': Derived(allergens: {'gluten'}),
    'soy sauce': Derived(allergens: {'soy', 'gluten'}),
    'light soy sauce': Derived(allergens: {'soy', 'gluten'}),
    'dark soy sauce': Derived(allergens: {'soy', 'gluten'}),
    'oyster sauce': Derived(
      animal: AnimalSource.seafood,
      allergens: {'shellfish', 'soy', 'gluten'},
    ),
    'fish sauce': Derived(animal: AnimalSource.seafood, allergens: {'fish'}),
    'chorizo': Derived(animal: AnimalSource.meat),
    'bacon': Derived(animal: AnimalSource.meat),
    'creme fraiche': Derived(animal: AnimalSource.dairy, allergens: {'dairy'}),
    'sour cream': Derived(animal: AnimalSource.dairy, allergens: {'dairy'}),
    'double cream': Derived(animal: AnimalSource.dairy, allergens: {'dairy'}),
    'single cream': Derived(animal: AnimalSource.dairy, allergens: {'dairy'}),
    'mascarpone': Derived(animal: AnimalSource.dairy, allergens: {'dairy'}),
    'gruyere': Derived(animal: AnimalSource.dairy, allergens: {'dairy'}),
    'stilton cheese': Derived(animal: AnimalSource.dairy, allergens: {'dairy'}),
    'cheddar cheese': Derived(animal: AnimalSource.dairy, allergens: {'dairy'}),
    'parmesan cheese': Derived(
      animal: AnimalSource.dairy,
      allergens: {'dairy'},
    ),
    'cheese': Derived(animal: AnimalSource.dairy, allergens: {'dairy'}),
    'semolina': Derived(allergens: {'gluten'}),
    'filo pastry': Derived(allergens: {'gluten'}),
    'puff pastry': Derived(allergens: {'gluten', 'dairy'}),
    'breadcrumbs': Derived(allergens: {'gluten'}),
    'couscous': Derived(allergens: {'gluten'}),
  };

  /// Named so that nobody assumes they are safe. A human must rule on each.
  static const ambiguous = <String>{
    'vegetable oil',
    'oil',
    'cooking oil',
    'groundnut oil',
    'peanut oil',
    'sesame oil',
    'toasted sesame oil',
    'white wine',
    'red wine',
    'wine',
    'dry sherry',
    'sherry',
    'beer',
    'brandy',
    'curry powder',
    'harissa',
    'harissa spice',
    'garam masala',
    'chinese five spice',
    'mixed spice',
    'mixed herbs',
    'italian seasoning',
    'tomato sauce',
    'tomato ketchup',
    'ketchup',
    'mustard',
    'worcestershire sauce',
    'duck sauce',
    'plum sauce',
    'hoisin sauce',
    'bbq sauce',
    'mayonnaise',
    'capers',
    'stir fry vegetables',
    'mixed vegetables',
    'seasoning',
    'baking powder',
    'yeast',
    'gelatine',
    'gelatin',
    'honey',
    'tahini',
  };
}
