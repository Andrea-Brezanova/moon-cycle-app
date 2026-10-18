# TheMealDB: what must be verified before any production use

Status: **development only** (free test key `1`, debug builds). No supporter
subscription has been bought. Everything below is an open question to put to
TheMealDB (themealdb.com, contact/support) **in writing**, and to a lawyer, before
the provider is enabled in a release build. Nothing here is a legal conclusion.

| Topic | What we do today | What must be verified |
|---|---|---|
| Commercial use | Test key, development only | Whether the app (paid premium features) may use the free key or needs the supporter key; exact supporter price and terms |
| Recipe text | Shown in full inside the app with credit "Recipe from TheMealDB · original: <site>" and a link | Who owns method and ingredient text (community-submitted, often copied from other sites named in the `strSource` field); whether TheMealDB can license it for display in a commercial app; whether showing it in full is permitted |
| Photos | Loaded from TheMealDB's URL, never downloaded or re-hosted | Whether images may be shown commercially, hot-linking rules, per-image rights, attribution wording |
| Attribution | Provider name plus original site where known | Required wording, placement and logo use |
| Caching and storage | Saved recipes store only a reference (provider, id, title, link); the app caches search results in memory for the session | Whether any caching or offline storage is allowed, for how long, and whether copying text into My Recipes is ever allowed (we do not) |
| Rate limits and key exposure | Direct client calls with the public test key | Limits for the supporter key; whether a key embedded in a mobile app is permitted or must be proxied |
| Takedown | None | Process if a rights holder objects to a listed recipe; whether we must remove cached references |
| Data accuracy | Allergens and diet are inferred by our own ingredient mapping; unidentified ingredients drop the recipe for restricted users | Disclaimer wording; TheMealDB gives no allergen or diet data |
| Availability | Per-source failure falls back to the library | Uptime commitments, change notice |

Decision rule: until each row has a written answer, TheMealDB stays behind the
debug-only gate and is not enabled for any release build.
