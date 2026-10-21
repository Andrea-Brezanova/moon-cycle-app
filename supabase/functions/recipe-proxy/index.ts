// Edge Function: POST /functions/v1/recipe-proxy   (LOCAL ONLY for now)
import { createClient } from "jsr:@supabase/supabase-js@2";
import { handleProxy, type ProxyDb } from "../_shared/proxy.ts";

const url = Deno.env.get("SUPABASE_URL")!;
const admin = createClient(url, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!, { auth: { persistSession: false } });
const anonKey = Deno.env.get("SUPABASE_ANON_KEY")!;

const db: ProxyDb = {
  async take(provider) {
    const { error } = await admin.rpc("take_provider_budget", { p_provider: provider });
    if (error) throw new Error(error.message);
  },
  async getCache(provider, key) {
    const { data } = await admin.rpc("get_provider_cache", { p_provider: provider, p_key: key });
    return data ?? null;
  },
  async putCache(provider, key, body) {
    await admin.rpc("put_provider_cache", { p_provider: provider, p_key: key, p_body: body });
  },
};

Deno.serve((req) =>
  handleProxy(req, {
    db,
    secret: (p) => Deno.env.get(`${p.toUpperCase()}_API_KEY`) ?? (p === "recipeapi" ? Deno.env.get("RECIPE_API_KEY") : undefined),
    async fetchUpstream(u, headers) {
      const r = await fetch(u, { headers, signal: AbortSignal.timeout(10_000) });
      return { status: r.status, body: await r.text() };
    },
    async authenticate(r) {
      const token = r.headers.get("authorization")?.replace(/^Bearer /i, "");
      if (!token) return null;
      const { data } = await createClient(url, anonKey, { auth: { persistSession: false } }).auth.getUser(token);
      return data.user?.id ?? null;
    },
  })
);
