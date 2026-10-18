// Deterministic recipe validation: a port of the app's
// lib/features/generation/domain/recipe_validator.dart. Both run against
// test/fixtures/generation/validator_cases.json, so they cannot drift apart.
import { foods } from "./catalogue.ts";
import {
  type Filter,
  type Food,
  type GeneratedRecipe,
  type GenerationRequest,
  type Issue,
  requestedFoodIds,
} from "./types.ts";

const ALLOWED_UNITS = new Set([
  "g", "kg", "ml", "l", "tsp", "tbsp", "cup", "oz", "lb", "piece", "pinch",
  "can", "jar", "handful", "clove", "fillet", "thumb", "head", "bunch",
]);

const BANNED = new RegExp(
  "hormon|estrogen|oestrogen|progesterone|fertil|detox|regulat|prevent|" +
    "\\btreat|\\bcure|\\bfix\\b|deficien|\\bpms\\b|cramp|symptom|scientific|" +
    "proven|science|clinical|boost|\\bheal(s|ing)?\\b|inflammat|immun|" +
    "superfood|weight loss|lose weight|anti-?oxidant|cleanse|balance your",
  "i",
);
const PANTRY = new RegExp(
  "\\b(salt|pepper|cumin|paprika|cinnamon|chil+i|curry|thyme|oregano|" +
    "turmeric|coriander|cardamom|nutmeg|ginger powder|garlic powder|" +
    "onion powder|vanilla|stock|bouillon|baking powder|oil|vinegar|water|" +
    "mustard|soy sauce|tamari|spice|spices|seasoning)\\b",
  "i",
);
const POULTRY_PORK = new Set(["chicken", "turkey", "duck", "pork", "bacon"]);
const OTHER_MEAT = new Set(["beef", "lamb"]);
const SHELLFISH = new Set([
  "shrimp", "clam", "crab", "lobster", "mussel", "oyster", "scallop", "squid",
  "octopus",
]);
const COOK_VERB = new RegExp(
  "\\b(cook|bake|roast|simmer|boil|fry|sear|grill|poach|steam|saut[eé]|" +
    "stir-fry|braise|heat|scramble)",
  "i",
);
const COOKED_THROUGH = new RegExp(
  "cooked through|no longer pink|until (it|they) (is|are) (cooked|done)|" +
    "\\b(165|74|71|160)\\s?(°|degrees|f\\b|c\\b)|juices run clear|piping hot|" +
    "steaming hot|until (cooked|done|golden)",
  "i",
);
const RAW_ONLY = new RegExp(
  "\\bserve (it |them )?raw\\b|\\buncooked (chicken|turkey|duck|pork|egg)|" +
    "\\bundercooked\\b|\\braw (chicken|turkey|duck|pork|egg)s?\\b|\\brunny\\b",
  "i",
);

function maxAmount(unit: string | null): number {
  switch (unit) {
    case "g": return 1500;
    case "kg": return 3;
    case "ml": return 1500;
    case "l": return 3;
    case "tsp": case "tbsp": return 12;
    case "cup": return 8;
    case "oz": return 48;
    case "lb": return 4;
    case "pinch": return 4;
    case "can": case "jar": return 4;
    case "clove": case "fillet": case "thumb": case "head": case "bunch": return 10;
    case "handful": return 6;
    default: return 20;
  }
}

function dietAllows(diet: Filter["diet"], source: Food["animalSource"]): boolean {
  switch (diet) {
    case "omnivore": return true;
    case "pescatarian": return source !== "meat";
    case "vegetarian": return source !== "meat" && source !== "seafood";
    case "vegan": return source === "none";
  }
}

function allowsFood(f: Food, filter: Filter): boolean {
  const allergens = new Set(filter.allergens);
  return dietAllows(filter.diet, f.animalSource) &&
    !(filter.avoidFoods ?? []).includes(f.id) &&
    !f.allergens.some((a) => allergens.has(a)) &&
    !f.mayContainAllergens.some((a) => allergens.has(a));
}

export function validate(
  recipe: GeneratedRecipe,
  request: GenerationRequest,
  filter: Filter,
): Issue[] {
  const issues: Issue[] = [];
  const add = (code: string, message: string) => issues.push({ code, message });
  const length = (what: string, text: string, min: number, max: number) => {
    const n = text.trim().length;
    if (n < min || n > max) add("length", `${what} is ${n} characters`);
  };

  length("title", recipe.title, 3, 80);
  length("intro", recipe.intro, 10, 400);
  if (recipe.minutes < 5 || recipe.minutes > 180) add("range", `minutes ${recipe.minutes}`);
  if (recipe.serves < 1 || recipe.serves > 8) add("range", `serves ${recipe.serves}`);
  if (recipe.steps.length < 3 || recipe.steps.length > 5) {
    add("range", `${recipe.steps.length} steps`);
  }
  recipe.steps.forEach((s, i) => length(`step ${i + 1}`, s, 10, 400));
  if (recipe.ingredients.length < 4 || recipe.ingredients.length > 16) {
    add("range", `${recipe.ingredients.length} ingredients`);
  }

  const used: Food[] = [];
  const seen = new Set<string>();
  for (const line of recipe.ingredients) {
    length("ingredient label", line.label, 2, 80);
    if (line.food_id == null) {
      if (!PANTRY.test(line.label)) add("pantryLine", `"${line.label}" is not a pantry line`);
    } else {
      const food = foods.get(line.food_id);
      if (!food) add("unknownFood", `unknown food "${line.food_id}"`);
      else {
        used.push(food);
        if (seen.has(food.id)) add("duplicateIngredient", `"${food.id}" appears twice`);
        seen.add(food.id);
      }
    }
    if (line.unit != null && !ALLOWED_UNITS.has(line.unit)) add("unit", `unit "${line.unit}"`);
    if (line.amount != null) {
      if (!Number.isFinite(line.amount) || line.amount <= 0 || line.amount > maxAmount(line.unit)) {
        add("amount", `"${line.label}": ${line.amount}`);
      }
      if (line.unit == null) add("unit", `"${line.label}" has an amount but no unit`);
    } else if (line.qty_text == null || line.qty_text.trim() === "") {
      add("amount", `"${line.label}" has no quantity`);
    }
  }

  const ids = new Set(used.map((f) => f.id));
  const chosen = requestedFoodIds(request);
  for (const id of chosen) {
    if (!ids.has(id)) add("missingSelection", `the chosen food "${id}" is missing`);
  }
  for (const f of used) {
    if (chosen.includes(f.id)) continue;
    if (f.animalSource !== "none" && f.animalSource !== "honey") {
      add("extraAnimalProduct", `"${f.id}" (${f.animalSource}) was not chosen`);
    }
  }

  // Diet and allergens come from the linked foods, never from the model.
  const conditionallyAnimal = (filter.diet === "vegetarian" || filter.diet === "vegan") &&
    used.some((f) => f.mayContainAllergens.some((a) => a === "fish" || a === "shellfish"));
  if (conditionallyAnimal || used.some((f) => !allowsFood(f, filter))) {
    add("dietOrAllergen", "conflicts with the user's diet or avoidances");
  }

  const text = [
    recipe.title, recipe.intro, ...recipe.steps,
    ...recipe.ingredients.map((l) => l.label),
  ].join("\n");
  const claim = BANNED.exec(text);
  if (claim) add("bannedClaim", `contains "${claim[0]}"`);

  const steps = recipe.steps.join("\n");
  const needsCooking = [...ids].some((id) =>
    POULTRY_PORK.has(id) || OTHER_MEAT.has(id) || SHELLFISH.has(id) || id === "eggs"
  );
  if (needsCooking && !COOK_VERB.test(steps)) add("foodSafety", "no cooking step");
  if ([...ids].some((id) => POULTRY_PORK.has(id)) && !COOKED_THROUGH.test(steps)) {
    add("foodSafety", "poultry or pork without cooked-through wording");
  }
  if (ids.has("kidney-bean")) {
    const line = recipe.ingredients.filter((l) => l.food_id === "kidney-bean").map((l) => l.label).join(" ");
    if (!/canned|tinned|cooked/i.test(line) && !/\bboil/i.test(steps)) {
      add("foodSafety", "kidney beans must be canned or boiled");
    }
  }
  if (RAW_ONLY.test(steps)) add("foodSafety", "raw or undercooked instruction");
  return issues;
}
