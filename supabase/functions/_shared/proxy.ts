// Server-side proxy for external recipe providers. The provider's API key exists
// only here (a function secret); the app never sees it.
//
// Only a short allow-list of provider requests can be made, every request needs
// a signed-in user, paid requests are budgeted in the database, and responses
// are cached only as long as the provider's terms allow (provider_limits).

export interface ProxyDb {
  take(provider: string): Promise<void>; // throws provider_* errors
  getCache(provider: string, key: string): Promise<unknown | null>;
  putCache(provider: string, key: string, body: unknown): Promise<void>;
}

export interface ProxyDeps {
  authenticate(req: Request): Promise<string | null>;
  db: ProxyDb;
  /** The provider's API key from the secret store, or undefined. */
  secret(provider: string): string | undefined;
  fetchUpstream(url: string, headers: Record<string, string>): Promise<{ status: number; body: string }>;
}

type Op = "ingredients" | "search" | "detail";

interface Provider {
  base: string;
  keyHeader: string;
  /** Whether the operation counts against the provider's quota (a "paid" call). */
  paid: (op: Op) => boolean;
  path: (op: Op, p: Record<string, string>) => string | null;
}

const ID = /^[A-Za-z0-9-]{1,64}$/;
const TEXT = /^[\p{L}\p{N} '-]{1,60}$/u;

const PROVIDERS: Record<string, Provider> = {
  recipeapi: {
    base: "https://recipe-api.com/api/v1",
    keyHeader: "X-API-Key",
    // Ingredient and recipe search are free; opening a full recipe is paid.
    paid: (op) => op === "detail",
    path: (op, p) => {
      if (op === "ingredients" && p.q && TEXT.test(p.q)) return `/ingredients?q=${encodeURIComponent(p.q)}`;
      if (op === "search" && p.ingredient && ID.test(p.ingredient)) {
        return `/recipes?ingredients=${p.ingredient}&per_page=25`;
      }
      if (op === "detail" && p.id && ID.test(p.id)) return `/recipes/${p.id}`;
      return null;
    },
  },
};

const STATUS: Record<string, number> = {
  not_signed_in: 401,
  bad_request: 400,
  provider_disabled: 503,
  provider_not_configured: 503,
  provider_budget_exhausted: 429,
  provider_cost_exhausted: 429,
  upstream_error: 502,
};

function reply(kind: string, body: Record<string, unknown> = {}): Response {
  const ok = kind === "ok";
  return new Response(JSON.stringify(ok ? body : { error: kind }), {
    status: ok ? 200 : STATUS[kind] ?? 500,
    headers: { "content-type": "application/json" },
  });
}

/** POST { provider, op, q? | ingredient? | id? } */
export async function handleProxy(req: Request, deps: ProxyDeps): Promise<Response> {
  if (req.method !== "POST") return reply("bad_request");
  if (!(await deps.authenticate(req))) return reply("not_signed_in");
  const text = await req.text();
  if (text.length > 1024) return reply("bad_request");
  let body: Record<string, string>;
  try {
    body = JSON.parse(text);
  } catch {
    return reply("bad_request");
  }
  const provider = PROVIDERS[body.provider];
  const op = body.op as Op;
  if (!provider || !["ingredients", "search", "detail"].includes(op)) return reply("bad_request");
  const path = provider.path(op, body);
  if (!path) return reply("bad_request");

  const cacheKey = path;
  const cached = await deps.db.getCache(body.provider, cacheKey);
  if (cached != null) return reply("ok", { data: cached, cached: true });

  const key = deps.secret(body.provider);
  if (!key) return reply("provider_not_configured");
  if (provider.paid(op)) {
    try {
      await deps.db.take(body.provider);
    } catch (e) {
      const m = (e as Error).message;
      return reply(m in STATUS ? m : "provider_disabled");
    }
  }
  let res;
  try {
    res = await deps.fetchUpstream(provider.base + path, { [provider.keyHeader]: key });
  } catch {
    return reply("upstream_error");
  }
  if (res.status !== 200) return reply("upstream_error");
  let data: unknown;
  try {
    data = JSON.parse(res.body);
  } catch {
    return reply("upstream_error");
  }
  await deps.db.putCache(body.provider, cacheKey, data);
  return reply("ok", { data, cached: false });
}
