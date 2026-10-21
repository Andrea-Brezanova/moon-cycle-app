// Edge Function: POST /functions/v1/submit-recipe   (LOCAL ONLY for now)
import { createClient } from "jsr:@supabase/supabase-js@2";
import { handleSubmit, type SubmitDb } from "../_shared/submit.ts";

const url = Deno.env.get("SUPABASE_URL")!;
const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const anonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
const admin = createClient(url, serviceKey, { auth: { persistSession: false } });

const db: SubmitDb = {
  async submitAsUser(token, recipeId, consent) {
    const asUser = createClient(url, anonKey, {
      auth: { persistSession: false },
      global: { headers: { Authorization: `Bearer ${token}` } },
    });
    const { error } = await asUser.rpc("submit_for_review", { p_recipe: recipeId, p_consent: consent });
    if (error) throw new Error(error.message);
  },
  async loadForValidation(recipeId) {
    const { data: r } = await admin.from("generated_recipes").select("*").eq("id", recipeId).single();
    if (!r) return null;
    const { data: job } = await admin.from("generation_jobs").select("*").eq("id", r.job_id).single();
    if (!job) return null;
    return {
      recipe: {
        schema_version: r.schema_version, title: r.title, intro: r.intro, category: r.category,
        minutes: r.minutes, serves: r.serves, ingredients: r.ingredients, steps: r.steps,
      },
      request: {
        idempotency_key: job.idempotency_key, phase: job.phase, protein_id: job.protein_id,
        base_id: job.base_id, plant_ids: job.plant_ids,
      },
    };
  },
  async recordValidation(recipeId, report, passed) {
    const { data, error } = await admin.rpc("record_validation", {
      p_recipe: recipeId, p_report: report, p_passed: passed,
    });
    if (error) throw new Error(error.message);
    return data as string;
  },
};

Deno.serve((req) =>
  handleSubmit(req, {
    db,
    async authenticate(r) {
      const token = r.headers.get("authorization")?.replace(/^Bearer /i, "");
      if (!token) return null;
      const { data } = await createClient(url, anonKey, { auth: { persistSession: false } }).auth.getUser(token);
      return data.user ? { userId: data.user.id, token } : null;
    },
  })
);
