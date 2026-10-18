import { foods } from "./catalogue.ts";
import { ModelError, type ModelResult, type RecipeModel } from "./model.ts";
import type { Filter, GeneratedRecipe, GenerationRequest, Issue } from "./types.ts";
import { validate } from "./validator.ts";

/** What the handler needs from the database (service-role functions). */
export interface Db {
  beginGeneration(args: {
    userId: string; key: string; fingerprint: string; phase: string;
    protein: string; base: string; plants: string[];
  }): Promise<{ jobId: string; status: string; recipeId: string | null; isNew: boolean }>;
  completeGeneration(args: {
    jobId: string; recipe: GeneratedRecipe; result: ModelResult; validation: Issue[];
  }): Promise<string>;
  failGeneration(jobId: string, kind: string, costMicros: number): Promise<void>;
  getRecipe(recipeId: string): Promise<StoredRecipe | null>;
}

/** A saved recipe with who made it. */
export interface StoredRecipe {
  recipe: GeneratedRecipe;
  origin: string;
  provider: string;
  model: string;
}

export interface Deps {
  /** The user id from a verified JWT, or null. */
  authenticate(req: Request): Promise<string | null>;
  db: Db;
  model: RecipeModel;
  appEnv: string | undefined;
}

const STATUS: Record<string, number> = {
  not_signed_in: 401,
  not_entitled: 403,
  quota_exceeded: 429,
  rate_limited: 429,
  generation_disabled: 503,
  budget_exhausted: 503,
  unavailable: 503,
  invalid_selection: 422,
  invalid_result: 422,
  timeout: 504,
  provider: 502,
  bad_request: 400,
};

function reply(kind: string, body: Record<string, unknown> = {}): Response {
  const ok = kind === "ok";
  return new Response(JSON.stringify(ok ? body : { error: kind, ...body }), {
    status: ok ? 200 : STATUS[kind] ?? 500,
    headers: { "content-type": "application/json" },
  });
}

/** The canonical selection text, identical to the app's `fingerprint`. */
export function fingerprint(r: GenerationRequest): string {
  return `${r.phase}|${r.protein_id}|${r.base_id}|${[...r.plant_ids].sort().join(",")}`;
}

function parse(body: unknown): GenerationRequest | null {
  const b = body as Record<string, unknown> | null;
  if (!b || typeof b !== "object") return null;
  const phases = ["menstrual", "follicular", "ovulatory", "luteal"];
  if (
    typeof b.idempotency_key !== "string" || b.idempotency_key.length < 8 || b.idempotency_key.length > 80 ||
    typeof b.phase !== "string" || !phases.includes(b.phase) ||
    typeof b.protein_id !== "string" || typeof b.base_id !== "string" ||
    !Array.isArray(b.plant_ids) || !b.plant_ids.every((p) => typeof p === "string")
  ) return null;
  return b as unknown as GenerationRequest;
}

export async function handle(req: Request, deps: Deps): Promise<Response> {
  if (req.method !== "POST") return reply("bad_request", { detail: "POST only" });
  const userId = await deps.authenticate(req);
  if (!userId) return reply("not_signed_in");

  // Small bodies only.
  const text = await req.text();
  if (text.length > 4096) return reply("bad_request", { detail: "too large" });
  let request: GenerationRequest | null;
  try {
    request = parse(JSON.parse(text));
  } catch {
    request = null;
  }
  if (!request) return reply("bad_request");

  // Every id is re-resolved against the server's copy of the catalogue.
  const ids = [request.protein_id, request.base_id, ...request.plant_ids];
  if (
    request.plant_ids.length < 2 || request.plant_ids.length > 3 ||
    new Set(ids).size !== ids.length || ids.some((id) => !foods.has(id))
  ) return reply("invalid_selection");

  // The local stub may only run when APP_ENV is "local".
  let job;
  try {
    job = await deps.db.beginGeneration({
      userId, key: request.idempotency_key, fingerprint: fingerprint(request),
      phase: request.phase, protein: request.protein_id, base: request.base_id,
      plants: request.plant_ids,
    });
  } catch (e) {
    const kind = (e as Error).message;
    return reply(kind in STATUS ? kind : "unavailable");
  }

  // A repeat of a finished request returns the saved recipe, with no model call.
  if (!job.isNew) {
    if (job.status === "succeeded" && job.recipeId) {
      const stored = await deps.db.getRecipe(job.recipeId);
      if (stored) return reply("ok", { recipe_id: job.recipeId, ...stored, existing: true });
    }
    if (job.status === "failed") return reply("unavailable", { detail: "previous attempt failed" });
    return reply("rate_limited", { detail: "already in progress" });
  }

  // Filters are applied only if the client sent them with consent.
  const filter: Filter = parseFilter((JSON.parse(text) as Record<string, unknown>).filter);

  let spent = 0;
  let repair: Issue[] = [];
  try {
    for (let attempt = 0; attempt < 2; attempt++) {
      const result = await deps.model.generate(request, repair);
      spent += result.costMicros;
      const issues = validate(result.recipe, request, filter);
      if (issues.length === 0) {
        const recipeId = await deps.db.completeGeneration({
          jobId: job.jobId, recipe: result.recipe, result, validation: [],
        });
        return reply("ok", {
          recipe_id: recipeId, recipe: result.recipe, origin: result.origin,
          provider: result.provider, model: result.model, existing: false,
        });
      }
      repair = issues;
    }
    await deps.db.failGeneration(job.jobId, "invalid_result", spent);
    return reply("invalid_result");
  } catch (e) {
    if (e instanceof ModelError) {
      await deps.db.failGeneration(job.jobId, e.kind, spent);
      return reply(e.kind);
    }
    const msg = (e as Error).message;
    if (msg === "quota_exceeded") return reply("quota_exceeded");
    await deps.db.failGeneration(job.jobId, "provider", spent);
    return reply("provider");
  }
}

function parseFilter(raw: unknown): Filter {
  const f = raw as Partial<Filter> | undefined;
  const diets = ["omnivore", "pescatarian", "vegetarian", "vegan"];
  return {
    diet: f && diets.includes(f.diet as string) ? (f.diet as Filter["diet"]) : "omnivore",
    allergens: Array.isArray(f?.allergens) ? f!.allergens!.filter((a) => typeof a === "string") : [],
    avoidFoods: Array.isArray(f?.avoidFoods) ? f!.avoidFoods!.filter((a) => typeof a === "string") : [],
  };
}
