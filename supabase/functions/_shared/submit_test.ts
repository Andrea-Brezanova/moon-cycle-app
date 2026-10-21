import { assertEquals } from "jsr:@std/assert@1";
import { handleSubmit, type SubmitDb } from "./submit.ts";
import { StubModel } from "./model.ts";

const request = { idempotency_key: "key-0000001", phase: "luteal" as const, protein_id: "tofu", base_id: "farro", plant_ids: ["kale", "carrot"] };

async function db(over: Partial<SubmitDb> = {}, invalid = false): Promise<SubmitDb & { recorded: unknown[] }> {
  const recorded: unknown[] = [];
  const { recipe } = await new StubModel(invalid ? 1 : 0).generate(request, []);
  return {
    recorded,
    submitAsUser: () => Promise.resolve(),
    loadForValidation: () => Promise.resolve({ recipe, request }),
    recordValidation: (_id, _r, passed) => { recorded.push(passed); return Promise.resolve(passed ? "validated" : "pending"); },
    ...over,
  };
}

const call = (d: SubmitDb, body: unknown, user = true) =>
  handleSubmit(new Request("http://x", { method: "POST", body: JSON.stringify(body) }), {
    db: d, authenticate: () => Promise.resolve(user ? { userId: "u", token: "t" } : null),
  });

Deno.test("signed out", async () => assertEquals((await call(await db(), {}, false)).status, 401));
Deno.test("consent is required", async () => {
  const r = await call(await db(), { recipe_id: "r" });
  assertEquals(r.status, 400);
  assertEquals((await r.json()).error, "consent_required");
});
Deno.test("a valid suggestion is validated, never published", async () => {
  const d = await db();
  const r = await call(d, { recipe_id: "r", consent: true });
  assertEquals(r.status, 200);
  assertEquals((await r.json()).status, "validated");
  assertEquals(d.recorded, [true]);
});
Deno.test("a recipe that fails validation stays a candidate", async () => {
  const d = await db({}, true);
  const r = await call(d, { recipe_id: "r", consent: true });
  assertEquals((await r.json()).status, "pending");
  assertEquals(d.recorded, [false]);
});
Deno.test("the database's ownership and lifecycle errors are surfaced", async () => {
  for (const [msg, status] of [["not_found", 404], ["not_private", 409]] as const) {
    const d = await db({ submitAsUser: () => Promise.reject(new Error(msg)) });
    const r = await call(d, { recipe_id: "r", consent: true });
    assertEquals(r.status, status);
    assertEquals(d.recorded, []);
  }
});
