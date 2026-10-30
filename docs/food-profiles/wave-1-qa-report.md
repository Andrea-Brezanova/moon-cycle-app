# Wave 1 editorial quality assurance

Automated checks over the 98 Wave 1 profiles (`wave1_qa.py`), on top of the data audit (every figure re-checked against live USDA records) and the regression tests. Nothing was changed and nothing is published.

| Check | Result |
|---|---|
| Nutrient figures and servings | Re-verified against USDA (0 open findings); serving text matches the source portion (test) |
| Five-section format | 0 length outliers |
| Readability (Flesch reading ease below 35) | 0 |
| Technical terms in text | 0 |
| Percentages in prose that disagree with the data | 0 |
| Overstating words (best, must, boosts, supports…) | 0 |
| Repeated sentences | 0 |
| Hormone, fertility, PMS, mood or phase-benefit claims | 0 (test over all drafts) |
| Cautions | all `sourced` or catalogue allergen tags; none unverified (test) |
| Cycle section could imply a phase link | 0 (see below) |

## Flagged by a check, read, and accepted

- figure, beef: "90%" is "90% lean", not a nutrient percentage.
- readability, cabbage: Short plain sentence; the score is driven by syllable counts.
- readability, mackerel: A long list of nutrients in one sentence; accepted, could be split in editing.
- readability, tomato: Short plain sentence; the score is driven by syllable counts.
- overstatement, kidney-bean: "must" is a safety instruction (soak and boil dried beans).
- overstatement, mackerel: "Best" is the FDA/EPA term "Best Choice".

## Does the cycle section create misleading implications?

- Checked on the PROPOSED wording. Every one of the 98 notes ends with the same evidence statement; none says or implies that a food should be eaten in a phase.
- 4 notes carry the iron sentence. 0 of them are on foods featured in a phase other than menstrual; each says the need applies every day of the month, not only during a period, so it does not read as "for your period".
- The old heading "Cycle relevance" suggested every food has a cycle link; the proposed heading "Nutrition & your cycle" with this wording does not.
- The pill "Recommended for your {phase} phase" did contradict the evidence; the previews use "Featured for variety in the {phase} phase" (see `why-this-food-audit.md`).

