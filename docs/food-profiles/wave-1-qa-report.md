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
| Cycle section could imply a phase link | 2 (see below) |

## implication (2)

- lamb: iron/menstruation sentence on a food featured in the luteal phase
- pork: iron/menstruation sentence on a food featured in the luteal phase

## Flagged by a check, read, and accepted

- figure, beef: "90%" is "90% lean", not a nutrient percentage.
- readability, cabbage: Short plain sentence; the score is driven by syllable counts.
- readability, mackerel: A long list of nutrients in one sentence; accepted, could be split in editing.
- readability, tomato: Short plain sentence; the score is driven by syllable counts.
- overstatement, kidney-bean: "must" is a safety instruction (soak and boil dried beans).
- overstatement, mackerel: "Best" is the FDA/EPA term "Best Choice".

## Does the cycle-relevance section create misleading implications?

- The heading "Cycle relevance" can suggest every food has a cycle link, when 92 of 98 Wave 1 profiles say only that none is claimed. Suggested options: keep the heading, or rename it "Cycle note", or show the section only when a sourced nutrient fact exists.
- 6 profiles carry the sourced iron sentence ("partly because of menstrual blood loss"). 2 of them are foods featured in a phase other than menstrual, which could read as "this food is for your period". The sentence is true all month; the proposed wording (below) says so explicitly.

