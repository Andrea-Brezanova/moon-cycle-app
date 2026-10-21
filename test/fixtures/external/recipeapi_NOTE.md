These fixtures are **hand-written from Recipe API's public documentation**
(recipe-api.com/docs), not captured from the live service: no key exists yet.
The shape of an ingredient's amount is not documented, so `items` use several
plausible field names to prove the adapter tolerates them. Replace with real
captures when a trial key is approved.

## Real-response fixtures (`recipeapi_real_*.json`)

Captured on 2026-10-18 from the Recipe API evaluation account with the capped
probe, then trimmed (details keep only id, name, description, category, cuisine,
tags, meta, dietary, ingredients and instructions; the `usage` block and
nutrition/storage/equipment sections are removed). They contain no key or
account data. The older `recipeapi_*` fixtures (r-1, r-3, chickpea) were written
from documentation and are kept for the parser's tolerance tests.
