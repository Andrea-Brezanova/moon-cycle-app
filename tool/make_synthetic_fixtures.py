#!/usr/bin/env python3
"""Writes the SYNTHETIC test fixtures for the external recipe providers (test/fixtures/external/).

Everything here is invented for the tests. Titles, methods, descriptions and ingredient combinations are
made up; ingredient names are common food words; ids are fake (TheMealDB meals 9xxxx, UUIDs derived from a
fixed namespace). Nothing is copied from TheMealDB, Recipe API or any recipe site. The JSON shapes follow the
providers' public documentation so the adapters are exercised as before.

    python3 tool/make_synthetic_fixtures.py
Deterministic: running it again rewrites identical files."""
import json, random, uuid, os

OUT = 'test/fixtures/external'
NS = uuid.UUID('00000000-0000-4000-8000-00000000f1f1')
rnd = random.Random(20261030)


def uid(name):
    return str(uuid.uuid5(NS, name))


# ---------------- TheMealDB-shaped fixtures ----------------
FOOD = ['Carrots', 'Garlic', 'Olive Oil', 'Onions', 'Red Onions', 'Tomatoes', 'Black Eyed Peas', 'Chickpeas', 'Spinach', 'Kale',
        'Potatoes', 'Sweet Potatoes', 'Brown Rice', 'Quinoa', 'Eggs', 'Chicken Breast', 'Beef', 'Salmon', 'Lemon', 'Lime', 'Ginger',
        'Parsley', 'Mushrooms', 'Broccoli', 'Cauliflower', 'Cabbage', 'Butter', 'Milk', 'Yogurt', 'Cheddar', 'Oats', 'Green Lentils',
        'Red Lentils', 'Peas', 'Corn', 'Zucchini', 'Cucumber', 'Avocado', 'Apples', 'Bananas', 'Almonds', 'Walnuts', 'Tofu', 'Shrimp',
        'Cod', 'Honey', 'Maple Syrup', 'Sesame Seeds', 'Red Cabbage', 'Beetroot', 'Celery', 'Leek', 'Fennel', 'Mint', 'Basil', 'Dill',
        'Pumpkin', 'Pears', 'Oranges', 'Strawberries', 'Blueberries', 'Kidney Beans', 'Navy Beans', 'Pinto Beans']
PANTRY = ['Salt', 'Water', 'Black Pepper', 'Sugar']
DERIVED = ['Plain Flour', 'Soy Sauce', 'Chicken Stock', 'Vegetable Stock', 'Spaghetti', 'Breadcrumbs', 'Tortillas', 'Noodles']
OTHER = ['Smoked Paprika', 'Fish Sauce', 'Worcestershire Sauce', 'Cornstarch', 'Mixed Spice', 'Dried Oregano', 'Ground Cumin', 'Ground Cinnamon',
         'Turmeric', 'Chilli Powder', 'Baking Powder', 'Vanilla Extract', 'Cocoa Powder', 'Coconut Milk', 'Hot Sauce', 'Mustard', 'White Wine Vinegar',
         'Bay Leaf', 'Thyme', 'Saffron', 'Sumac', 'Za\'atar', 'Miso Paste']
MEASURES = ['1 tbsp', '2 tbsp', '1 tsp', '1/2 tsp', '200g', '400g', '1 cup', '2 cups', '3 cloves', '1 large', '2 medium', '1 small', 'to taste', 'for frying', '150ml', '1 bunch']
CATEGORIES = ['Side', 'Starter', 'Vegetarian', 'Seafood', 'Chicken', 'Dessert', 'Breakfast', 'Pasta', 'Beef', 'Vegan']
AREAS = ['Testland', 'Examplia', 'Sampleshire', 'Fixtureland']
METHOD = ('This is invented test text. Step 1: prepare the ingredients. Step 2: cook everything until done. '
          'Step 3: season and serve.')

KEYS = ['dateModified', 'idMeal', 'strArea', 'strCategory', 'strCountry', 'strCreativeCommonsConfirmed', 'strImageSource', 'strInstructions',
        'strMeal', 'strMealAlternate', 'strMealThumb', 'strSource', 'strTags', 'strYoutube']


def meal(mid, title, category, ingredients, area='Testland'):
    m = {k: None for k in KEYS}
    m.update(idMeal=mid, strMeal=title, strCategory=category, strArea=area, strCountry=area, strInstructions=METHOD,
             strMealThumb=f'https://www.themealdb.com/images/media/meals/synthetic-{mid}.jpg')
    for n in range(1, 21):
        if n <= len(ingredients):
            name, measure = ingredients[n - 1]
            m[f'strIngredient{n}'], m[f'strMeasure{n}'] = name, measure
        else:
            m[f'strIngredient{n}'], m[f'strMeasure{n}'] = '', ''
    return m


meals = {}
# Hand-built meals the tests name: a side with carrots and olive oil, fritters with plain flour, two others.
meals['90001'] = meal('90001', 'Synthetic Carrot Side', 'Side', [('Water', '1 cup'), ('Carrots', '2 lbs'), ('Olive Oil', '5 tablespoons'), ('Salt', '1 tsp'),
                      ('Black Pepper', '1/2 teaspoon'), ('Garlic', '3 cloves'), ('Lemon Juice', '1 tsp')])
meals['90002'] = meal('90002', 'Synthetic Pea Fritters', 'Seafood', [('Black Eyed Peas', '800g'), ('Garlic', '1 clove'), ('Red Onions', '1 small'),
                      ('Plain Flour', '2 tablespoons'), ('Salt', '1 tsp'), ('Vegetable Oil', 'for frying'), ('Ginger', '1 tablespoon')])
meals['90003'] = meal('90003', 'Synthetic Pepper Salad', 'Starter', [('Red Pepper', '2'), ('Tomatoes', '3'), ('Garlic', '2 cloves'), ('Olive Oil', '3 tbsp'), ('Salt', 'to taste')])
meals['90004'] = meal('90004', 'Synthetic Spiced Meatballs', 'Beef', [('Beef', '500g'), ('Onions', '1'), ('Garlic', '2 cloves'), ('Ground Cumin', '1 tsp'), ('Parsley', '1 bunch'), ('Salt', '1 tsp')])
# Four meals using only identified ingredients, so a restricted user can be shown some.
for i in range(4):
    mid = f'9010{i}'
    names = rnd.sample(FOOD, 5) + rnd.sample(PANTRY, 2)
    meals[mid] = meal(mid, f'Synthetic Plain Plate {i + 1}', rnd.choice(CATEGORIES), [(n, rnd.choice(MEASURES)) for n in names])
# The rest: ingredient names drawn from the pools in a fixed mix (about 60% foods, 12% pantry, 8% derived, 20% other).
n = 0
while len(meals) < 80:
    mid = f'902{n:02d}'
    n += 1
    k = rnd.randint(9, 14)
    names = []
    for _ in range(k):
        r = rnd.random()
        pool = FOOD if r < 0.60 else PANTRY if r < 0.72 else DERIVED if r < 0.80 else OTHER
        names.append(rnd.choice(pool))
    meals[mid] = meal(mid, f'Synthetic Test Meal {n}', rnd.choice(CATEGORIES), [(x, rnd.choice(MEASURES)) for x in names], rnd.choice(AREAS))

lookups = {mid: {'meals': [m]} for mid, m in meals.items()}


def listing(ids):
    return {'meals': [{'strMeal': meals[i]['strMeal'], 'strMealThumb': meals[i]['strMealThumb'], 'idMeal': i, 'strArea': meals[i]['strArea'], 'strCountry': meals[i]['strCountry']} for i in ids]}


garlic = ['90001', '90002', '90003', '90004', '90100', '90101', '90200', '90201', '90202', '90203']
kale = ['90001', '90102', '90204', '90205', '90206', '90207']
files = {'themealdb_lookups.json': lookups, 'themealdb_filter_garlic.json': listing(garlic), 'themealdb_filter_kale.json': listing(kale)}

# ---------------- Recipe API-shaped fixtures ----------------
SKILLET, OMELETTE = uid('recipe-skillet'), uid('recipe-omelette')
SPINACH_ING, CHICKPEA_CANNED, CHICKPEA_DRIED = uid('ingredient-spinach'), uid('ingredient-canned-chickpeas'), uid('ingredient-dried-chickpeas')


def ing(name, category, source='Aggregated Public Sources'):
    return {'id': uid('ingredient-' + name), 'name': name, 'category': category, 'source': source}


spinach_ings = [{'id': SPINACH_ING, 'name': 'spinach', 'category': 'Vegetables', 'source': 'Aggregated Public Sources'},
                ing('baby spinach', 'Vegetables'), ing('fresh spinach leaves', 'Vegetables'), ing('large leaf spinach', 'Vegetables'),
                ing('Spinach, cooked, boiled, drained, without salt', 'Vegetables', 'USDA'), ing('Spinach, raw', 'Vegetables', 'USDA'),
                ing('Noodles, egg, spinach, enriched, cooked', 'Grains & Pasta', 'USDA'), ing('Spaghetti, spinach, dry', 'Grains & Pasta', 'USDA'),
                ing('Malabar spinach, cooked', 'Vegetables', 'USDA'), ing('spinach pesto', 'Sauces')]
chickpea_ings = [{'id': CHICKPEA_CANNED, 'name': 'canned chickpeas', 'category': 'Legumes', 'source': 'Aggregated Public Sources'},
                 ing('Chickpea flour (besan)', 'Legumes', 'USDA'), ing('chickpea liquid, drained', 'Legumes'),
                 ing('Chickpeas, mature seeds, canned, drained solids', 'Legumes', 'USDA'), ing('Chickpeas, mature seeds, raw', 'Legumes', 'USDA'),
                 ing('chickpeas, canned', 'Legumes'), ing('Wheat flour, chickpea', 'Grains & Pasta'),
                 {'id': CHICKPEA_DRIED, 'name': 'dried chickpeas', 'category': 'Legumes', 'source': 'Aggregated Public Sources'}]


def rec(rid, name, flags, warnings, mins=30):
    return {'id': rid, 'name': name, 'description': 'Invented description for tests.', 'category': 'Dinner', 'cuisine': 'Testland', 'difficulty': 'Easy',
            'tags': ['Synthetic'], 'meta': {'active_time': 'PT15M', 'passive_time': 'PT15M', 'total_time': f'PT{mins}M', 'overnight_required': False,
                                            'yields': '4 servings', 'yield_count': 4, 'serving_size_g': 280},
            'dietary': {'flags': flags, 'not_suitable_for': warnings}}


def steps(n):
    phases = ['prep', 'cook', 'finish']
    return [{'step_number': i, 'phase': phases[min(2, i * 3 // (n + 1))], 'text': f'Invented step {i}: do the next thing for the test.'} for i in range(1, n + 1)]


def item(name, qty, unit):
    return {'name': name, 'quantity': qty, 'unit': unit, 'preparation': None, 'notes': None, 'substitutions': [], 'ingredient_id': uid('ingredient-' + name),
            'nutrition_source': 'invented'}


skillet = rec(SKILLET, 'Synthetic Chicken and Spinach Skillet', ['Gluten-Free'], ['Individuals with dairy allergies (contains parmesan)'])
skillet.update(ingredients=[{'group_name': 'Main', 'items': [item('chicken breast', 600, 'g'), item('olive oil', 30, 'ml'), item('garlic', 4, None),
                                                             item('baby spinach', 150, 'g'), item('parmesan', 40, 'g'), item('canned tomatoes', 200, 'g'),
                                                             item('fine sea salt', 2, 'g')]}], instructions=steps(11))
omelette = rec(OMELETTE, 'Synthetic Garden Omelette', ['Vegetarian', 'Gluten-Free', 'Dairy-Free', 'Nut-Free'], ['Individuals with egg allergies'], 15)
omelette.update(ingredients=[{'group_name': 'Base', 'items': [item('egg', 3, None), item('water', 15, 'ml'), item('fine sea salt', 1.5, 'g'), item('black pepper', 0.5, 'g')]},
                             {'group_name': 'Filling', 'items': [item('olive oil', 10, 'ml'), item('red bell pepper', 40, 'g'), item('mushroom', 35, 'g'),
                                                                 item('baby spinach', 30, 'g'), item('scallion', 15, 'g')]}], instructions=steps(13))
others = [('Synthetic Veal and Spinach Plate', ['Gluten-Free'], ['x']), ('Synthetic Spinach Salad', ['Vegetarian', 'Dairy-Free'], ['x']),
          ('Synthetic Herb Rice', ['Vegetarian', 'Vegan', 'Dairy-Free'], []), ('Synthetic Minestrone', ['Vegetarian'], ['x']),
          ('Synthetic Tomato Spaghetti', ['Vegetarian'], []), ('Synthetic Savoury Pancakes', ['Vegetarian', 'Nut-Free'], ['x']),
          ('Synthetic Crispy Tofu Bowl', ['Vegan', 'Vegetarian', 'Dairy-Free'], []), ('Synthetic Roasted Mushrooms', ['Vegan', 'Vegetarian', 'Gluten-Free'], [])]
rlist = [dict(skillet), dict(omelette)] + [rec(uid('recipe-' + n), n, f, w) for n, f, w in others]
for r in rlist:
    r.pop('ingredients', None); r.pop('instructions', None)
files.update({
    'recipeapi_synth_ingredients_spinach.json': {'data': spinach_ings},
    'recipeapi_synth_ingredients_chickpea.json': {'data': chickpea_ings},
    'recipeapi_synth_recipes_spinach.json': {'data': rlist, 'meta': {'total': len(rlist), 'page': 1, 'per_page': 10, 'total_capped': False}},
    'recipeapi_synth_recipes_empty.json': {'data': [], 'meta': {'total': 0, 'page': 1, 'per_page': 10, 'total_capped': False}},
    'recipeapi_synth_detail_skillet.json': {'data': dict(skillet)},
    'recipeapi_synth_detail_omelette.json': {'data': dict(omelette)},
})
os.makedirs(OUT, exist_ok=True)
for name, data in files.items():
    open(f'{OUT}/{name}', 'w').write(json.dumps(data, indent=1, ensure_ascii=False) + '\n')
print('ids:', dict(SKILLET=SKILLET, OMELETTE=OMELETTE, SPINACH=SPINACH_ING, CANNED=CHICKPEA_CANNED, DRIED=CHICKPEA_DRIED))
print(len(meals), 'synthetic meals')
