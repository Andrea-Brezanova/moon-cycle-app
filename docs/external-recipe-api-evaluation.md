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
