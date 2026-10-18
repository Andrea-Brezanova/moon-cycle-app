import { assertEquals } from "jsr:@std/assert@1";
import { handleProxy, type ProxyDb } from "./proxy.ts";

function setup(opts: { key?: string; takeError?: string; upstream?: { status: number; body: string } } = {}) {
  const calls: string[] = [];
  const cache = new Map<string, unknown>();
  let takes = 0;
  const db: ProxyDb = {
    take: () => {
      if (opts.takeError) return Promise.reject(new Error(opts.takeError));
      takes++;
      return Promise.resolve();
    },
    getCache: (_p, k) => Promise.resolve(cache.get(k) ?? null),
    putCache: (_p, k, b) => { cache.set(k, b); return Promise.resolve(); },
  };
  const call = (body: unknown, user = true) =>
    handleProxy(new Request("http://x", { method: "POST", body: JSON.stringify(body) }), {
      db,
      authenticate: () => Promise.resolve(user ? "u" : null),
      secret: () => opts.key === undefined ? "secret-key" : opts.key || undefined,
      fetchUpstream: (u, h) => {
        calls.push(`${u} ${JSON.stringify(h)}`);
        return Promise.resolve(opts.upstream ?? { status: 200, body: '{"data":[1]}' });
      },
    });
  return { call, calls, takes: () => takes, cache };
}

Deno.test("signed-out callers are refused and nothing is fetched", async () => {
  const s = setup();
  assertEquals((await s.call({ provider: "recipeapi", op: "ingredients", q: "kale" }, false)).status, 401);
  assertEquals(s.calls.length, 0);
});

Deno.test("only allow-listed providers, operations and well-formed ids", async () => {
  const s = setup();
  for (const b of [
    { provider: "other", op: "search" },
    { provider: "recipeapi", op: "delete" },
    { provider: "recipeapi", op: "detail", id: "../../admin" },
    { provider: "recipeapi", op: "detail" },
    { provider: "recipeapi", op: "ingredients", q: "<script>" },
    { provider: "recipeapi", op: "search", ingredient: "a b" },
  ]) assertEquals((await s.call(b)).status, 400);
  assertEquals((await s.call("not json" as never)).status, 400);
  assertEquals(s.calls.length, 0);
});

Deno.test("the key goes to the provider only, never in the response", async () => {
  const s = setup();
  const r = await s.call({ provider: "recipeapi", op: "ingredients", q: "kale" });
  assertEquals(r.status, 200);
  assertEquals(s.calls[0].includes("secret-key"), true);
  assertEquals((await r.text()).includes("secret-key"), false);
});

Deno.test("free calls cost no budget; a full recipe takes one", async () => {
  const s = setup();
  await s.call({ provider: "recipeapi", op: "ingredients", q: "kale" });
  await s.call({ provider: "recipeapi", op: "search", ingredient: "abc-1" });
  assertEquals(s.takes(), 0);
  await s.call({ provider: "recipeapi", op: "detail", id: "r-1" });
  assertEquals(s.takes(), 1);
});

Deno.test("a repeat is served from the cache with no second request or budget", async () => {
  const s = setup();
  const b = { provider: "recipeapi", op: "detail", id: "r-1" };
  await s.call(b);
  const r = await s.call(b);
  assertEquals((await r.json()).cached, true);
  assertEquals(s.calls.length, 1);
  assertEquals(s.takes(), 1);
});

Deno.test("budget and disabled errors stop the request before the provider", async () => {
  for (const [err, status] of [["provider_budget_exhausted", 429], ["provider_cost_exhausted", 429], ["provider_disabled", 503]] as const) {
    const s = setup({ takeError: err });
    assertEquals((await s.call({ provider: "recipeapi", op: "detail", id: "r-1" })).status, status);
    assertEquals(s.calls.length, 0);
  }
});

Deno.test("no secret configured, upstream errors and bad upstream JSON", async () => {
  assertEquals((await setup({ key: "" }).call({ provider: "recipeapi", op: "ingredients", q: "kale" })).status, 503);
  assertEquals((await setup({ upstream: { status: 500, body: "" } }).call({ provider: "recipeapi", op: "ingredients", q: "kale" })).status, 502);
  assertEquals((await setup({ upstream: { status: 200, body: "<html>" } }).call({ provider: "recipeapi", op: "ingredients", q: "kale" })).status, 502);
});
