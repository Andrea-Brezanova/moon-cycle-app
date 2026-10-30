# "Why this food?" copy and phase labels: audit

Read-only audit of the production catalogue (`assets/content/foods.json`, `phases.json`, `taxonomy.json`) for claims that tie a food, or its benefit, to a particular phase without support. **Nothing in production was changed.** Evidence base: `independent-phase-methodology.md` (no reliable research found that any food needs to be eaten in a particular phase).

- 142 entries (one per food and featured phase): meal-style 91, nutrient-fact 45, phase-link 5, traditional 1.
- **9 need a change** (below). 4 stated percentages disagree with the verified profile data.

## Labels and claims that need changing

| Where | Text | Problem | Proposed |
|---|---|---|---|
| Food Detail pill, `taxonomy.json` `sheetLabel` | "Recommended for your {phase} phase" | "Recommended" says the food is advised in that phase; there is no evidence for that, and the featured-phase principle says "featured", never "recommended". Appears on every featured food | "Featured for variety in the {phase} phase" (shown in the approval previews) |
| Why this food? · Mussel (menstrual) | "Mussels are a rich source of iron (about 32% of the daily value per serving) and protein, so we highlight them during menstruation." | ties the food to a phase ("we highlight it during menstruation"): the iron fact is sourced, the phase link is editorial | "Mussels are a rich source of iron (about 32% of the daily value per serving) and protein." |
| Why this food? · Oyster (menstrual) | "Oysters are a rich source of iron (about 37% of the daily value per serving), which is why we highlight them during menstruation." | ties the food to a phase ("we highlight it during menstruation"): the iron fact is sourced, the phase link is editorial; also states 37% but the verified serving (6 medium oysters, cooked) gives 21% | "Oysters are a rich source of iron (about 21% of the daily value in six oysters)." |
| Why this food? · Sardine (menstrual) | "Sardines add iron (about 11% of the daily value per serving) and are easy to put on toast or in pasta." | states 11% "per serving" but the verified serving (1 small can, drained) gives 15% | "Sardines add iron (about 15% of the daily value in one small can)." |
| Why this food? · Lentils (menstrual) | "Lentils provide plant-based iron, protein and fibre, which is why we highlight them during menstruation." | ties the food to a phase ("we highlight it during menstruation"): the iron fact is sourced, the phase link is editorial | "Lentils provide plant-based iron, protein and fibre." |
| Why this food? · Quinoa (menstrual) | "Quinoa adds some plant-based iron (about 12% of the daily value per serving) and is lovely in warm bowls." | states 12% "per serving" but the verified serving (½ cup cooked) gives 8% | "Quinoa adds some plant-based iron (about 8% of the daily value in half a cup cooked)." |
| Why this food? · Spinach (menstrual) | "Cooked spinach provides iron (about 18% of the daily value per serving) along with folate, which is why we highlight it during menstruation." | ties the food to a phase ("we highlight it during menstruation"): the iron fact is sourced, the phase link is editorial | "Cooked spinach provides iron (about 18% of the daily value per serving) along with folate." |
| Why this food? · Anchovies (menstrual) | "Anchovies are a concentrated source of iron (about 22% of the daily value per serving) and protein." | states 22% "per serving" but the verified serving (5 anchovies) gives 5% | "Anchovies are a concentrated source of iron, but a typical serving is small (five anchovies give about 5% of the daily value)." |
| Why this food? · Banana (luteal) | "Bananas are an easy addition to filling breakfasts and snacks during the luteal phase." | recommends a food "during the luteal phase" with no basis | "Bananas are an easy addition to filling breakfasts and snacks." |
| Why this food? · Honeydew melon (ovulatory) | "Honeydew is soft, sweet and cooling, an easy fruit salad or snack." | a traditional association ("cooling") with no clinical support | "Honeydew is soft and sweet, an easy fruit salad or snack." |

## Phase copy to review (not changed)

- `phases.json` menstrual `focusBody`: "…so Moon Cycle highlights iron-rich foods during this phase." The iron need is real and applies all month; "during this phase" is the editorial part. Suggested: "…so iron-rich foods are worth including through the month, and are featured here."
- `learnMore` and `homeFocus` for all four phases describe hormone levels (low or rising estrogen and progesterone) and what some people may feel (energy, appetite, mood). The physiology is general knowledge and hedged ("may", "some women"), but "Nourishing meals… can offer support" (menstrual) and "…calming rituals can support your everyday…" (luteal) are soft support claims. Suggested: keep the hedges, drop "support" wording, say nothing about food changing how you feel.
- The phase taglines and the "Inner winter/spring/summer/autumn" seasons are editorial and make no nutritional claim.
- `recipes.json` `whyThisPhase` (112 recipes): scanned for hormone, energy, mood, balance, boost and replenish wording: none. 27 mention menstruation, in the featured-food form ("featured Menstrual foods").

## What is fine

- 45 entries state a nutrient fact, and every stated percentage that could be checked (12) agrees with the verified profile data.
- 91 entries describe flavour, texture or how to use the food (including "warm" as a meal style), which is editorial, not a health claim.
- "helps your body absorb iron from plant foods" (vitamin C) is sourced to NIH ODS.

## Approval needed

1. Change the pill label (needs a production UI change and golden updates, done at publication).
2. Replace the six entries above with the proposed neutral text (a content change).
3. Decide whether to soften the phase copy listed under "Phase copy to review".
