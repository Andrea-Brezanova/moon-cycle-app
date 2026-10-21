# External recipe API evaluation (no provider is activated)

Facts below were read from each provider's own public pages on the date of this
revision (links at the end). Prices, limits and terms change and **must be
re-checked, and the full terms reviewed by someone qualified, before any
purchase**. Nothing was subscribed to, no key was requested and no request was
made to any API.

## What we need

Search by several foods, each recipe with full ingredients and method we may
show, a licensed photograph, stable ids, clear attribution rules, and permission
to cache what we show. Ingredient data must be mappable to our food ids, because
diet and allergen exclusion works on those ids.

## Comparison

| | Spoonacular | TheMealDB | Edamam |
|---|---|---|---|
| Coverage | Large general recipe database (size not stated on the pages read) | Small, hobbyist catalogue; free listings capped at 100 items | About 2 million web recipes (no instructions) plus 20,000+ Edamam-owned recipes (with instructions) |
| Multi-ingredient search | Yes, a ranked find-by-ingredients endpoint (from general knowledge; verify) | Free: one ingredient at a time. Multi-ingredient filter is a paid "V2" feature | Yes (search with ingredient terms) |
| Full instructions | Yes, via a per-recipe call | Yes | Only the Plus plan's own recipes; web recipes link out to the source |
| Images | Yes (URLs may be stored) | Yes | Yes |
| Commercial licensing | Allowed on paid plans; may not build a competing recipe app; no resale | Free test key is for development and education; a paid supporter key is needed before a public store release | Paid plans; commercial-use details not visible on the page read |
| Attribution | Original source credited and linked; the free plan also needs a backlink | Not detailed on the page | Required on every plan; missing attribution is treated as a breach |
| Storage / caching | Ids, titles and image URLs may be stored. Ingredients, instructions and nutrition may **not** be stored; any other cache only for 1 hour with written permission | Not stated | Caching not allowed by default; Core/Plus may cache a few fields; cached data only inside a logged-in account |
| Rate limits | Free 50 points/day, 1/s. Cook ($29/mo) 1,500 points/day, 5/s | Not stated | 10 / 100 / 300 calls per minute by plan |
| Cost | Free (limited, backlink), $29, $79, $149 per month | Free test key; one-off/paid supporter tier | $9 (web recipes, 10k calls/mo), $99, $399 per month |
| Allergen / diet data | Provides diet and intolerance filters (verify) | None | Provides diet and health labels (verify) |

## Fit with Moon Cycle

The app's abstraction is already compatible with the likely terms: an external
recipe carries `RecipeRights` (`mayStore`, `requiresLinkBack`, `mayShowImage`,
attribution, source URL), results show attribution, and a recipe whose terms do
not allow full display is dropped. The results card opens the **original source**
for external recipes (it does not open our recipe page), which is what link-out
terms expect.

Constraints that matter for design:

1. **Do not store the content.** Spoonacular and Edamam forbid keeping
   ingredients and methods. External recipes must therefore be fetched live and
   shown, never saved to My recipes or the shopping list as our own data
   (`mayStore: false`).
2. **Allergens and diets.** Our exclusion filter needs our food ids. An adapter
   must map each ingredient name to a catalogue food (`foodNamed`); a recipe with
   an ingredient it cannot map **must be dropped** (it cannot be checked), unless
   the provider's own diet/intolerance filters are used in addition. This is the
   largest risk and should be tested with a real sample before launch.
3. **Cost and quotas.** Each search is at least one call; results with details
   cost more. A per-user cap and a cache of search *results lists* (ids and
   titles only, where terms allow) are needed.
4. **Quality.** Real recipes from a broad database vary in quality and cuisine;
   the library comes first and external results are labelled with their source.

## Recommendation

1. **Ship with the internal library only for now.** It already returns real,
   reviewed recipes for most single foods and many pairs (see the match counts in
   the revision report).
2. If more coverage is wanted, **evaluate Spoonacular on its paid Cook plan
   first**, as a link-out source: store only ids, titles and image URLs, show
   attribution, send people to the original source, and drop recipes whose
   ingredients cannot be mapped. It has the clearest multi-ingredient search and
   documented storage rules.
3. **Edamam is second**: very large, but its web recipes are link-out only and
   its attribution rules are strict; consider only if Spoonacular's coverage or
   terms do not fit.
4. **TheMealDB is not recommended for production**: small catalogue, one
   ingredient at a time on the free tier, and a development-only free key.

## Decisions needed before any provider is activated

- Approval to subscribe (and a monthly budget), and who holds the account/keys.
- A legal read of the full terms for: commercial use in a subscription app,
  link-out vs in-app display, caching of result lists, image display, and
  handling of allergy/diet claims.
- Whether external recipes may be added to the shopping list (storage terms).
- The ingredient-mapping rule (drop unmapped recipes vs. rely on provider
  filters) and an acceptance sample (e.g. 100 searches checked by hand).
- Data protection: only food ids and diet filters would be sent; confirm the
  provider's privacy terms.

Sources: spoonacular.com/food-api/pricing and /food-api/terms; themealdb.com/api.php;
developer.edamam.com/edamam-recipe-api.


---

# Update: multi-provider architecture, TheMealDB, and Provider B

Facts below were read from the providers' own pages when this update was made;
re-check prices and terms before buying anything. **Nothing was purchased or
activated.** TheMealDB's free *test key* was called for development (as its docs
permit) only to capture fixtures.

## What is built

- `RecipeSourceProvider` (library or one external provider) → `RecipeDiscovery`
  asks **all sources at once**, each with its own timeout and failure handling,
  then ranks (most chosen foods first; library before external at equal
  relevance), removes duplicates (`RecipeDeduper`) and returns one list.
- `ExternalRecipeClient` is the only thing a provider implements; parsing,
  endpoints and ingredient names stay in the adapter. Every external recipe
  becomes the app's own `Recipe` plus `RecipeRights` (full display, storage,
  photo, attribution, source URL, publish) and a provider id.
- `ProviderPolicy` per provider: enabled, development-only, timeout, monthly
  request budget, requests per minute, detail-lookup cap, approximate cost per
  request, cache time. `ProviderHttp` enforces them on every request and records
  usage per provider per month in the local database (`provider_usages`).
- Safety rule for every provider: an ingredient that cannot be reliably mapped to
  a Moon Cycle food is **unknown, never safe**. With any diet or avoidance set,
  a recipe with an unknown ingredient (other than plain water, salt, pepper,
  sugar) is not shown.
- Saving to My recipes keeps a **reference** (provider, id, title, link), never a
  third-party recipe's ingredients or method; it is fetched again to open.
- No AI generation anywhere in Build a meal.

## Provider A: TheMealDB (development only)

Official endpoints, free test key `1`. Free search is **one ingredient at a
time** (multi-ingredient filtering is a paid V2 feature), so a search asks once
per chosen food, ranks meals by how many foods listed them, and fetches full
details for the best 12.

| Item | Finding |
|---|---|
| Full method and ingredients | Yes (`lookup.php`) |
| Photos | Yes (thumbnail URL); shown from TheMealDB's own URL, never downloaded |
| Times and servings | **Not provided** (shown as unknown, never invented) |
| Diet / allergen data | None. Only a category (e.g. Vegetarian) |
| Terms | Free key is for development and education; **an app store release needs a paid supporter key**. Reselling prohibited. Paid users using custom artwork must credit the site. No stated caching rule, so nothing is stored and recipes are kept in memory for 10 minutes only |
| Collection | Per ingredient on the free key (live check): chicken 20, garlic 223, lemon 49, chickpeas 13, spinach 10, salmon 8, broccoli 7, kale 6, tofu 2, quinoa 2, lentils 2, carrot 1 |
| Ingredient mapping to our foods | On 12 real recipes, 43% of ingredient lines map reliably and **no recipe had every line mapped** |

**Consequence:** with any diet or allergy set, the safety rule leaves essentially
no TheMealDB recipes, because spices, sauces and flours do not map. TheMealDB
is useful to people with no restrictions only. Improving this needs a larger
reviewed synonym list, not looser rules.

## Provider B comparison

| | Recipe API (recipe-api.com) | Edamam | Spoonacular |
|---|---|---|---|
| Full instructions | Yes, structured (steps, times, temperatures, equipment) | Only on the Enterprise Plus plan's own recipes ($399/mo); web recipes link out | Yes per recipe, but they are third-party sites' recipes |
| Commercial in-app display | **Explicit**: commercial use from the $29 Developer plan, recipes can be shown under your own brand | Paid plans; attribution mandatory | Allowed on paid plans, but recipes must credit the original source and storing ingredients/instructions is forbidden |
| Attribution | None required | Required on every plan; breach means suspension | Original source credit required |
| Photos | **None in the recipe object** (AI image add-on only); we would use the Moon Cycle illustration | Yes | Yes (URLs may be stored) |
| Ingredient search | Free, but by ingredient UUID, and a multi-ingredient search means *all* of them; so one lookup per food, ranked by us | Yes | Ranked find-by-ingredients |
| Collection size | **Not stated** on the pages read (10,000+ ingredients) | ~2M web (no method) + 20k owned | Large, not stated on pages read |
| Diet / allergen data | Per recipe: dietary flags and a "not suitable for" list; USDA nutrition | Diet and health labels | Diet/intolerance filters |
| Price | $9 (non-commercial), **$29 Developer**, $99, $299 | $9 / $99 / $399 | Free (limited, backlink), $29, $79, $149 |
| Quota | Developer: 500 requests a day, **250 unique recipes a month**, 60 requests a minute | 10k, 500k, 1M calls a month | Cook: 1,500 points a day |
| Caching / storage | 24 hours (Developer), 7 days ($99), persistent (Scale) | Not allowed by default | Ids, titles, image URLs only; else 1 hour with permission |
| Docs / fit | REST, clear docs, MCP server | Mature | Mature |

## Recommendation: Recipe API, Developer plan ($29/month), pending a trial

It is the only candidate that explicitly licenses commercial in-app display of
**full** recipes with no attribution, and its structured data and per-recipe
dietary flags suit our safety rules. Real limits to resolve first:

1. **250 unique recipes a month** is the binding constraint: each recipe opened
   in full counts once for the whole account, however many users view it. The
   $99 plan gives 1,000. Server-side 24-hour caching of fetched recipes (allowed
   on Developer) is needed, so the key must live behind a Supabase Edge Function.
2. **No photographs**: cards use the Moon Cycle illustration.
3. **Collection size and quality are unverified**; the ingredient-amount JSON is
   undocumented. Request a trial (the Evaluation plan has 50 full recipes) and
   replace the hand-written fixtures with real captures before deciding.
4. Ingredient search is "all of them" per call; our one-food-at-a-time approach
   costs 2 free calls per chosen food.

Spoonacular is second (clear storage rules, large, but third-party recipes with
credit and no persistent storage). Edamam is third (link-out for most recipes).

The adapter (`RecipeApiClient`) and fixture tests exist but the provider has no
policy entry in the app, so it cannot be called.

## Estimated cost of operating both

| | Monthly |
|---|---|
| TheMealDB (development) | $0; production needs a paid supporter key (price not on the page read; ask) |
| Recipe API Developer | $29 (250 unique recipes) or $99 (1,000) |
| Supabase proxy and cache | about $25 (already planned) |

Per search, Recipe API costs about $0.116 per *new* recipe opened (29/250) and
nothing for searches or repeat opens; TheMealDB test key costs nothing. A
configurable monthly request budget per provider stops spend locally.

---

# Benchmark (library vs TheMealDB, live free test key)

`dart run tool/provider_benchmark.dart` (no paid service is called; Recipe API is
not included because no key exists yet). 12 selections of 1, 2, 3 and 4 foods, two
diet settings. "Shown" counts recipes that survive the safety rules; at most 12
TheMealDB recipes are opened per search.

| Selection (no restrictions) | Library | TheMealDB shown | Combined unique | Complete / partial |
|---|---|---|---|---|
| chicken | 3 | 12 | 15 | 15 / 0 |
| salmon | 1 | 8 | 9 | 9 / 0 |
| chickpea | 3 | 0 | 3 | 3 / 0 |
| kale | 5 | 6 | 11 | 11 / 0 |
| tofu | 6 | 2 | 8 | 8 / 0 |
| quinoa | 5 | 2 | 7 | 7 / 0 |
| chicken + broccoli | 5 | 12 | 17 | 1 / 16 |
| lentils + spinach | 6 | 12 | 18 | 1 / 17 |
| salmon + sweet potato | 4 | 8 | 12 | 0 / 12 |
| eggs + spinach + feta | 16 | 12 | 28 | 1 / 27 |
| chickpea + spinach + tomato + onion | 26 | 12 | 38 | 0 / 38 |
| tofu + broccoli + rice + carrot | 20 | 12 | 32 | 0 / 32 |

Vegetarian: TheMealDB adds recipes only for kale (1), lentils + spinach (3),
chicken + broccoli (1), eggs + spinach + feta (2) and the two 4-food searches
(1 each); for single foods such as tofu, quinoa and chickpea it adds none.

- **Photos:** 107 of 107 TheMealDB recipes had a photo URL.
- **Time:** 200 ms to 3.1 s per search (one request per food plus up to 12
  recipe lookups); the library is instant.
- **Instructions:** present for every recipe shown; no times, servings or diet data.
- **Duplicates:** none observed between the library and TheMealDB in these runs.

**Reading it:** TheMealDB roughly doubles the number of results for common
proteins (chicken, salmon) and adds little for plant-based foods, which are the
core of Moon Cycle. For multi-food searches nearly everything is a partial match,
for both sources. More results are not better recipes: these are community
recipes with no times, no diet metadata, and, for a restricted user, almost none
pass the safety rules.

# Real-response findings (Recipe API, 2026-10-18)

From the capped probe: 4 free calls (2 ingredient searches, 2 list calls) and 2
detail lookups; all HTTP 200. The provider's own counter, returned with every
detail, reads `detail_used` 4 of `detail_limit` 50 (the evaluation account; it
counted a first probe run too), so the probe's cap of 40 is the stricter one.
Captures are in git-ignored `tool/captures/`; trimmed copies without usage or
account data are the `recipeapi_real_*` test fixtures.

**Matches the adapter:** `data[]` envelopes; list items with `meta.total_time`
(ISO), `yields`, `dietary.flags`, `dietary.not_suitable_for`; detail
`ingredients[].items[]` with numeric `quantity` and `unit` (null for counts),
`instructions[].text` (11 and 13 steps, each with structured temperature,
duration, tips); `category` Dinner/Breakfast.

**Differences found:**
- The ingredient search is a fuzzy list of USDA entries and variants, not a
  canonical list: "chickpea" has no exact entry ("canned chickpeas", "dried
  chickpeas", "Chickpea flour (besan)", long USDA names). The adapter now uses
  an exact match, else at most two plain forms ("canned", "dried", "fresh"… plus
  the food name); flours, commas and brackets are never used.
- "canned chickpeas" returned **0 recipes** and "baby spinach" returned 12. Other
  chickpea forms were not queried (to save free calls).
- Allergen "not suitable for" warnings are free sentences ("tree nut allergies
  due to pine nuts"); matching now uses allergen words, not only our ids.
  Warnings naming vegetarians/vegans also exclude those diets.
- **No image, no source URL, no licence or attribution field** in list or detail.
  Cards show Moon Cycle art; licence terms must come from the provider's terms.
- Dietary flags are incomplete (the chicken skillet lists only Gluten-Free and
  Low-Carb), so restricted users only get recipes whose flags prove suitability.
- `chicken broth` and `fine sea salt` were unrecognised; added as reviewed
  vocabulary (real lines identified: 21 of 21 on both recipes, from 19).
- Detail responses include rich extras we do not show (nutrition, equipment,
  troubleshooting, chef notes).

**Spinach list caveat:** the probe took the first search hit ("baby spinach"),
not the exact "spinach" entries our adapter prefers; those lists were not
fetched, so the spinach search is only checked for shape.

## Follow-up: exact ingredient lists (2026-10-18, 3 free calls, 0 detail lookups)

| Ingredient entry | Recipes listed |
|---|---|
| "baby spinach" (earlier probe) | 12 |
| "spinach" entry #1 | 1 |
| "spinach" entry #2 | 9 |
| "dried chickpeas" | 1 |
| "canned chickpeas" (earlier) | 0 |

The index holds the same name more than once, each with its own recipes, so the
adapter now uses every exact-name id (up to 3). Relevance is plausible (the 9
for spinach include chickpea/spinach, tofu, pancakes, but also a duck sandwich
and a lamb burger where spinach is a minor ingredient), but coverage is thin:
a user choosing only chickpeas would get about 1 recipe. Free-call total so far
11; paid lookups 4 of the probe's 40.
