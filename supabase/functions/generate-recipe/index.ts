// Edge Function: POST /functions/v1/generate-recipe
// LOCAL ONLY until the owner approves hosting. No provider key is read here:
// the model comes from `modelFromEnv` (a local stub, or "unavailable").
import { createClient } from "jsr:@supabase/supabase-js@2";
import { handle, type Db } from "../_shared/handler.ts";
import { modelFromEnv } from "../_shared/model.ts";

const url = Deno.env.get("SUPABASE_URL")!;
const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const anonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
const admin = createClient(url, serviceKey, { auth: { persistSession: false } });

const db: Db = {
  async beginGeneration(a) {
    const { data, error } = a.kind === "try_new"
      ? await admin.rpc("begin_try_new_generation", {
        p_user: a.userId, p_key: a.key, p_fingerprint: a.fingerprint, p_phase: a.phase,
        p_food_ids: a.foodIds, p_variant: a.variant,
      })
      : await admin.rpc("begin_generation", {
        p_user: a.userId, p_key: a.key, p_fingerprint: a.fingerprint, p_phase: a.phase,
        p_protein: a.protein, p_base: a.base, p_plants: a.plants,
      });
    if (error) throw new Error(error.message);
    const row = data[0];
    return { jobId: row.job_id, status: row.status, recipeId: row.recipe_id, isNew: row.is_new };
  },
  async completeGeneration(a) {
    const { data, error } = await admin.rpc("complete_generation", {
      p_job: a.jobId, p_recipe: a.recipe, p_origin: a.result.origin,
      p_provider: a.result.provider, p_model: a.result.model,
      p_input_tokens: a.result.inputTokens, p_output_tokens: a.result.outputTokens,
      p_cost_micros: a.result.costMicros, p_validation: a.validation,
    });
    if (error) throw new Error(error.message);
    return data as string;
  },
  async failGeneration(jobId, kind, costMicros) {
    await admin.rpc("fail_generation", { p_job: jobId, p_kind: kind, p_cost_micros: costMicros });
  },
  async getRecipe(id) {
    const { data } = await admin.from("generated_recipes").select("*").eq("id", id).single();
    if (!data) return null;
    return {
      origin: data.origin, provider: data.provider, model: data.model,
      recipe: {
        schema_version: data.schema_version, title: data.title, intro: data.intro,
        category: data.category, minutes: data.minutes, serves: data.serves,
        ingredients: data.ingredients, steps: data.steps,
      },
    };
  },
};

Deno.serve((req) =>
  handle(req, {
    db,
    model: modelFromEnv(Deno.env),
    appEnv: Deno.env.get("APP_ENV"),
    async authenticate(r) {
      const token = r.headers.get("authorization")?.replace(/^Bearer /i, "");
      if (!token) return null;
      const client = createClient(url, anonKey, { auth: { persistSession: false } });
      const { data } = await client.auth.getUser(token);
      return data.user?.id ?? null;
    },
  })
);
