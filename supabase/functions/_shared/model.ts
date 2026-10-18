import { foods } from "./catalogue.ts";
import {
  type GeneratedIngredient,
  type GeneratedRecipe,
  type GenerationRequest,
  type Issue,
  SCHEMA_VERSION,
} from "./types.ts";

export interface ModelResult {
  recipe: GeneratedRecipe;
  provider: string;
  model: string;
  origin: "cloud" | "local_stub";
  inputTokens: number;
  outputTokens: number;
  /** Millionths of a US dollar. */
  costMicros: number;
}

/** Thrown when the model cannot answer; mapped to an HTTP status. */
export class ModelError extends Error {
  constructor(public kind: "unavailable" | "timeout" | "provider", message?: string) {
    super(message ?? kind);
  }
}

/** The swappable generator. The handler knows nothing else about providers. */
export interface RecipeModel {
  generate(request: GenerationRequest, repair: Issue[]): Promise<ModelResult>;
}

/**
 * LOCAL STUB. Not an AI: a deterministic template so the backend can be built
 * and tested without a provider key or spend. The handler refuses to use it
 * unless APP_ENV is "local", and rows it makes are marked origin "local_stub".
 */
export class StubModel implements RecipeModel {
  calls = 0;
  constructor(private invalidFirst = 0) {}

  // deno-lint-ignore require-await
  async generate(request: GenerationRequest, _repair: Issue[]): Promise<ModelResult> {
    this.calls++;
    const name = (id: string) => (foods.get(id)?.name ?? id).replace(/ \(.*\)$/, "").toLowerCase();
    const title = (id: string) => {
      const n = (foods.get(id)?.name ?? id).replace(/ \(.*\)$/, "");
      return n[0].toUpperCase() + n.slice(1);
    };
    const line = (id: string, amount: number, unit: string): GeneratedIngredient => ({
      label: title(id), food_id: id, amount, unit, qty_text: null,
    });
    const plants = request.plant_ids.map(name);
    const kidney = request.protein_id === "kidney-bean";
    const broken = this.calls <= this.invalidFirst;
    const recipe: GeneratedRecipe = {
      schema_version: SCHEMA_VERSION,
      title: `${title(request.protein_id)} & ${title(request.base_id)} Bowl`,
      intro: broken
        ? "A bowl that can balance your hormones and boost energy."
        : `A simple bowl of ${name(request.protein_id)} and ${name(request.base_id)} with ${plants.join(" and ")}.`,
      category: (request.category as GeneratedRecipe["category"]) ?? "dinner",
      minutes: 30,
      serves: 2,
      ingredients: [
        line(request.protein_id, 150, "g"),
        line(request.base_id, 90, "g"),
        ...request.plant_ids.map((p) => line(p, 100, "g")),
        { label: "Olive oil", food_id: "olive-oil", amount: 1, unit: "tbsp", qty_text: null },
        { label: "Salt and black pepper", food_id: null, amount: 1, unit: "pinch", qty_text: null },
      ],
      steps: [
        `Cook the ${name(request.base_id)} until tender, then keep it warm.`,
        kidney
          ? "Boil the soaked kidney beans hard for 10 minutes, then simmer until soft."
          : `Cook the ${name(request.protein_id)} until cooked through and piping hot.`,
        `Chop the ${plants.join(" and ")} and sauté in the oil for 5 minutes until tender.`,
        "Serve everything together, seasoned with salt and pepper.",
      ],
    };
    return {
      recipe, provider: "local-stub", model: "template-v1", origin: "local_stub",
      inputTokens: 0, outputTokens: 0, costMicros: 0,
    };
  }
}

/**
 * Placeholder for the real provider. It makes NO network call: the exact model,
 * structured-output behaviour, pricing and data-handling terms must be verified
 * (and approved) before this is implemented. Until then it reports the service
 * as unavailable, so a deployment without a stub never pretends to generate.
 */
export class UnconfiguredModel implements RecipeModel {
  // deno-lint-ignore require-await
  async generate(): Promise<ModelResult> {
    throw new ModelError("unavailable", "no recipe model is configured");
  }
}

/** Chooses the model from the environment. Stub only in a local environment. */
export function modelFromEnv(env: { get(k: string): string | undefined }): RecipeModel {
  if (env.get("MODEL_PROVIDER") === "stub" && env.get("APP_ENV") === "local") {
    return new StubModel();
  }
  return new UnconfiguredModel();
}
