export type Phase = "menstrual" | "follicular" | "ovulatory" | "luteal";

export interface GenerationRequest {
  idempotency_key: string;
  phase: Phase;
  protein_id: string;
  base_id: string;
  plant_ids: string[];
  category?: string;
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
