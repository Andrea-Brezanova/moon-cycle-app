export type Phase = "menstrual" | "follicular" | "ovulatory" | "luteal";

export interface GenerationRequest {
  idempotency_key: string;
  phase: Phase;
  /** "meal" (Build a Meal) or "try_new" (Try Something New). */
  kind?: "meal" | "try_new";
  // Build a Meal.
  protein_id: string;
  base_id: string;
  plant_ids: string[];
  // Try Something New: three foods, and which of three dishes to make.
  food_ids?: string[];
  variant?: number;
  category?: string;
}

/** Every food the recipe must use, whichever kind of request it is. */
export function requestedFoodIds(r: GenerationRequest): string[] {
  return r.kind === "try_new"
    ? (r.food_ids ?? [])
    : [r.protein_id, r.base_id, ...r.plant_ids];
}

export interface GeneratedIngredient {
  label: string;
  food_id: string | null;
  amount: number | null;
  unit: string | null;
  qty_text: string | null;
}

/** The structured recipe (schema version 1), as the model returns it. */
export interface GeneratedRecipe {
  schema_version: number;
  title: string;
  intro: string;
  category: "breakfast" | "lunch" | "dinner" | "snack";
  minutes: number;
  serves: number;
  ingredients: GeneratedIngredient[];
  steps: string[];
}

export interface Food {
  id: string;
  name: string;
  category: string;
  animalSource: "none" | "dairy" | "egg" | "seafood" | "meat" | "honey";
  allergens: string[];
  mayContainAllergens: string[];
}

/** What the user avoids; sent only with explicit consent. */
export interface Filter {
  diet: "omnivore" | "pescatarian" | "vegetarian" | "vegan";
  allergens: string[];
  avoidFoods?: string[];
}

export interface Issue {
  code: string;
  message: string;
}

export const SCHEMA_VERSION = 1;
