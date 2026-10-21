import type { Food } from "./types.ts";
import data from "./data/catalogue.json" with { type: "json" };

/** The shippable foods, generated from the app's own `foods.json`. */
export const foods: Map<string, Food> = new Map(
  (data.foods as Food[]).map((f) => [f.id, f]),
);
