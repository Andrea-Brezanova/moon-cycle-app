// deno test --allow-read supabase/functions/_shared/handler_test.ts
import { assertEquals } from "jsr:@std/assert@1";
import { type Db, fingerprint, handle, type StoredRecipe } from "./handler.ts";
import { ModelError, type ModelResult, type RecipeModel, StubModel } from "./model.ts";
import type { GeneratedRecipe } from "./types.ts";

const body = {
  idempotency_key: "key-0000001", phase: "luteal", protein_id: "tofu",
  base_id: "farro", plant_ids: ["kale", "carrot"],
};

class FakeDb implements Db {
  jobs = new Map<string, { id: string; status: string; recipeId: string | null }>();
  recipes = new Map<string, StoredRecipe>();
  failed: string[] = [];
  charged = 0;
  beginError: string | null = null;

  beginGeneration(a: { key: string }) {
    if (this.beginError) return Promise.reject(new Error(this.beginError));
    const existing = this.jobs.get(a.key);
    if (existing) {
      return Promise.resolve({ jobId: existing.id, status: existing.status, recipeId: existing.recipeId, isNew: false });
    }
    const job = { id: `job-${this.jobs.size + 1}`, status: "generating", recipeId: null as string | null };
    this.jobs.set(a.key, job);
    return Promise.resolve({ jobId: job.id, status: "generating", recipeId: null, isNew: true });
  }
  completeGeneration(a: { jobId: string; recipe: GeneratedRecipe }) {
    const id = `recipe-${a.jobId}`;
    this.recipes.set(id, { recipe: a.recipe, origin: "local_stub", provider: "local-stub", model: "template-v1" });
    for (const j of this.jobs.values()) if (j.id === a.jobId) { j.status = "succeeded"; j.recipeId = id; }
    this.charged++;
    return Promise.resolve(id);
  }
  failGeneration(jobId: string, kind: string) {
    this.failed.push(kind);
    for (const j of this.jobs.values()) if (j.id === jobId) j.status = "failed";
    return Promise.resolve();
  }
  getRecipe(id: string) { return Promise.resolve(this.recipes.get(id) ?? null); }
}

function call(db: Db, model: RecipeModel, payload: unknown = body, user: string | null = "u1") {
  return handle(
    new Request("http://x/generate-recipe", { method: "POST", body: JSON.stringify(payload) }),
    { db, model, appEnv: "local", authenticate: () => Promise.resolve(user) },
  );
}

Deno.test("signed-out callers are refused", async () => {
  const r = await call(new FakeDb(), new StubModel(), body, null);
  assertEquals(r.status, 401);
});

Deno.test("a valid request creates a recipe and charges once", async () => {
  const db = new FakeDb();
  const r = await call(db, new StubModel());
  assertEquals(r.status, 200);
  const j = await r.json();
  assertEquals(j.existing, false);
  assertEquals(db.charged, 1);
});

Deno.test("the same key returns the saved recipe without calling the model", async () => {
  const db = new FakeDb();
  const model = new StubModel();
  await call(db, model);
  const r = await call(db, model);
  const j = await r.json();
  assertEquals(j.existing, true);
  assertEquals(model.calls, 1);
  assertEquals(db.charged, 1);
});

Deno.test("unknown foods, repeats and wrong plant counts are refused before any call", async () => {
  const model = new StubModel();
  for (const p of [
    { ...body, protein_id: "moon-dust" },
    { ...body, plant_ids: ["kale"] },
    { ...body, plant_ids: ["kale", "kale"] },
    { ...body, plant_ids: ["kale", "carrot", "spinach", "lemon"] },
  ]) {
    const r = await call(new FakeDb(), model, p);
    assertEquals(r.status, 422);
  }
  assertEquals(model.calls, 0);
});

Deno.test("Try Something New: three foods, a variant, and its own fingerprint", async () => {
  const db = new FakeDb();
  const tn = { idempotency_key: "tn-key-0001", phase: "luteal", kind: "try_new", food_ids: ["kale", "carrot", "tofu"], variant: 1 };
  const r = await call(db, new StubModel(), tn);
  assertEquals(r.status, 200);
  const j = await r.json();
  assertEquals(j.recipe.title, "Kale, Carrot & Tofu Soup");
  assertEquals(fingerprint({ ...tn, protein_id: "", base_id: "", plant_ids: [] } as never), "try_new|luteal|carrot,kale,tofu|1");
});

Deno.test("Try Something New: wrong food counts or variants are refused", async () => {
  const model = new StubModel();
  for (const t of [
    { idempotency_key: "tn-key-0002", phase: "luteal", kind: "try_new", food_ids: ["kale", "carrot"], variant: 0 },
    { idempotency_key: "tn-key-0003", phase: "luteal", kind: "try_new", food_ids: ["kale", "carrot", "tofu"], variant: 3 },
    { idempotency_key: "tn-key-0004", phase: "luteal", kind: "try_new", food_ids: ["kale", "kale", "tofu"], variant: 0 },
    { idempotency_key: "tn-key-0005", phase: "luteal", kind: "try_new", food_ids: ["kale", "carrot", "moon-dust"], variant: 0 },
  ]) {
    assertEquals((await call(new FakeDb(), model, t)).status, 422);
  }
  assertEquals(model.calls, 0);
});

Deno.test("malformed bodies are 400", async () => {
  const r = await call(new FakeDb(), new StubModel(), { nope: true });
  assertEquals(r.status, 400);
});

Deno.test("database refusals map to their status", async () => {
  for (const [msg, status] of [["not_entitled", 403], ["quota_exceeded", 429], ["rate_limited", 429], ["budget_exhausted", 503], ["generation_disabled", 503]] as const) {
    const db = new FakeDb();
    db.beginError = msg;
    const model = new StubModel();
    const r = await call(db, model);
    assertEquals(r.status, status, msg);
    assertEquals(model.calls, 0);
  }
});

Deno.test("an invalid first answer is repaired once", async () => {
  const model = new StubModel(1);
  const r = await call(new FakeDb(), model);
  assertEquals(r.status, 200);
  assertEquals(model.calls, 2);
});

Deno.test("two invalid answers fail the job without charging", async () => {
  const db = new FakeDb();
  const r = await call(db, new StubModel(2));
  assertEquals(r.status, 422);
  assertEquals(db.charged, 0);
  assertEquals(db.failed, ["invalid_result"]);
});

Deno.test("a provider timeout fails the job without charging", async () => {
  const db = new FakeDb();
  const model: RecipeModel = {
    generate: (): Promise<ModelResult> => Promise.reject(new ModelError("timeout")),
  };
  const r = await call(db, model);
  assertEquals(r.status, 504);
  assertEquals(db.charged, 0);
  assertEquals(db.failed, ["timeout"]);
});

Deno.test("the fingerprint matches the app's", () => {
  assertEquals(
    fingerprint({ ...body, phase: "luteal", plant_ids: ["carrot", "kale"] } as never),
    "luteal|tofu|farro|carrot,kale",
  );
});
