# External ingredient mapping

How a provider's ingredient text ("Red Onions", "chicken stock") becomes
something Moon Cycle can reason about. Code: `ingredient_vocabulary.dart` (the
reviewed vocabulary) and `ingredient_mapper.dart`. The Moon Cycle food library
and phase mappings are untouched.

## Classes

| Class | Meaning | Counts as a chosen food | Shown to a user with a diet/allergy |
|---|---|---|---|
| Food | Same food as ours (other name, spelling, variety, form) | Yes | Checked with that food's data |
| Pantry-safe | Plain salt, water, sugar, single dried spices, plain vinegars | No | Yes |
| Derived | Not our food, but allergens and animal source are known (stock, soy sauce, cheeses, semolina) | No | Checked against the known data |
| Ambiguous | Named so nobody assumes it is safe (vegetable oil, wine, curry powder, sauces) | No | **No** |
| Unknown | Not recognised | No | **No** |

Rules: no matching by a shared word ("peanut butter" is not butter, "chicken
stock" is not chicken); every vocabulary entry is a deliberate decision, a test
checks that aliases point at real foods and that no entry sits in two classes;
allergen checks were not loosened (they gained lines: derived items carry their
allergens and animal source, which the diet filter now honours).

## Before and after (80 real TheMealDB recipes, 874 ingredient lines)

| | Before | After |
|---|---|---|
| Lines mapped to a Moon Cycle food | 428 (49%) | 531 (61%) |
| Plain pantry lines | 97 | 185 |
| Derived (known allergens/animal) | 0 | 49 |
| **Identified in total** | **525 (60%)** | **765 (88%)** |
| Ambiguous (named) | 0 | 40 |
| Unknown | 349 | 69 |
| **Recipes that can be shown to a user with any restriction** | **1 of 80** | **24 of 80** |

Remaining unknowns are a long tail of one-offs (fajita seasoning, jam, sake,
specific sausages). The largest ambiguous items are vegetable oil and "oil" (16
lines; they can be soy or sesame), white wine and curry powder.

## Findings that need your decision

1. **Dataset gap: `wheat-flour` has no gluten allergen** in the reviewed
   `foods.json`. Two **internal** recipes (`napa-cabbage-egg-pancakes`,
   `ricotta-strawberry-pancakes`) use it, so a gluten-avoider can currently be
   offered them. I did not edit the dataset. External lines for flour are
   protected in code (`allergenOverrides`); the same one-line fix to the
   dataset (`"allergens": ["gluten"]`) would protect the library. Please approve.
2. `coconut milk` is a synonym of `coconut` (tree-nut) and `peanut butter` of
   `nut-butter` (peanut and tree-nut): conservative, left as is.
