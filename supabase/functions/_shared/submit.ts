import { validate } from "./validator.ts";
import type { GeneratedRecipe, GenerationRequest } from "./types.ts";

/** What the submit handler needs from the database. */
export interface SubmitDb {
  /** Runs `submit_for_review` AS THE USER, so the database checks ownership. */
  submitAsUser(token: string, recipeId: string, consent: boolean): Promise<void>;
  /** The saved recipe and the foods it was made from (service role). */
  loadForValidation(recipeId: string): Promise<{
    recipe: GeneratedRecipe; request: GenerationRequest;
  } | null>;
  recordValidation(recipeId: string, report: unknown, passed: boolean): Promise<string>;
}

export interface SubmitDeps {
  authenticate(req: Request): Promise<{ userId: string; token: string } | null>;
  db: SubmitDb;
}

const json = (status: number, body: Record<string, unknown>) =>
  new Response(JSON.stringify(body), { status, headers: { "content-type": "application/json" } });

/**
 * POST { recipe_id, consent: true }. The user explicitly suggests their own
 * recipe; the database enforces ownership and lifecycle. The recipe is then
 * validated by the same validator that gates generation, and either becomes
 * "validated" (waiting for an editor) or stays a candidate. Nothing is
 * published here.
 */
export async function handleSubmit(req: Request, deps: SubmitDeps): Promise<Response> {
  if (req.method !== "POST") return json(400, { error: "bad_request" });
  const auth = await deps.authenticate(req);
  if (!auth) return json(401, { error: "not_signed_in" });
  let body: { recipe_id?: unknown; consent?: unknown };
  try {
    body = JSON.parse(await req.text());
  } catch {
    return json(400, { error: "bad_request" });
  }
  if (typeof body.recipe_id !== "string" || body.consent !== true) {
    return json(400, { error: body.consent === true ? "bad_request" : "consent_required" });
  }
  try {
    await deps.db.submitAsUser(auth.token, body.recipe_id, true);
  } catch (e) {
    const m = (e as Error).message;
    const status = m === "not_found" ? 404 : 409;
    return json(status, { error: m });
  }
  const loaded = await deps.db.loadForValidation(body.recipe_id);
  if (!loaded) return json(500, { error: "unavailable" });
  const issues = validate(loaded.recipe, loaded.request, { diet: "omnivore", allergens: [] });
  const status = await deps.db.recordValidation(body.recipe_id, { issues }, issues.length === 0);
  return json(200, { status });
}
