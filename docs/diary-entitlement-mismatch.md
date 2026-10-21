# Diary access: resolved (basic diary is Free)

Decision (owner): the basic diary is **Free**: logging foods, recipes and own
meals, logging basic symptoms, viewing history, editing and deleting.

`defaultFeatureTiers[Feature.logDiary]` is now `Tier.free`. The Premium
infrastructure is untouched: the tier map, `Tier.premium`, the gate, and the
`Feature.buildMeal` Premium rule all remain, and every diary screen still asks
the gate, so a later Premium diary feature (for example insights) only needs a
new `Feature` value.

Consistency: Home "Log diary", More › My Diary, Food detail › Log meal and
Recipe detail › Log meal all use the same gate and now open for every user.
Debug builds are unchanged ("All features unlocked (dev)").

No advanced diary insights were implemented.
