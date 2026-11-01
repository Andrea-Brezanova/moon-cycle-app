"""Builds FINAL-APPROVAL-PACKAGE.md: the owner's decisions as applied, the exact final text, and what is still open.
Run from the repo root after why-this-food-rewrites.json and nine-rewrites-verification.json exist."""
import json, subprocess

R = 'docs/food-profiles/'
rw = json.load(open(R + 'why-this-food-rewrites.json'))['rewrites']
ver = {r['id']: r for r in json.load(open(R + 'nine-rewrites-verification.json'))['rows']}
assert len(rw) == 9


def phase_diff():
    out = subprocess.run(['git', 'diff', 'main', '--', 'assets/content/phases.json'], capture_output=True, text=True).stdout
    return out


L = ['# Wave 1: final editorial approval package\n',
     '**Nothing is published.** The 98 Wave 1 profiles stay unpublished (`wave-1-candidate.json`, `publishable: false`); flax, sesame and sunflower seed stay on hold; no phase assignment was changed.\n',
     '## 1. Decisions applied (1 Nov 2026)\n',
     '| Decision | Applied |', '|---|---|',
     '| Heading and plainer closing | Heading **Nutrition & your cycle** now shows on every profile. The evidence statement stands apart from the nutrient facts. Used in the Wave 1 candidate; added to the two live profiles that lacked one (spinach, lentils). |',
     '| Phase badge | The pill **"Recommended for your {phase} phase"** now reads **"Explore this food"** (phase tint kept; no claim about a phase). |',
     '| Nine rewrites | In production, after checking every sentence, serving and figure against the live USDA record (section 4). |',
     '| `phases.json` | Softened (section 5). Menstrual physiology kept. |',
     '| Reviewer | Role recorded as "App owner (editorial owner; not a clinician)". Name, date and credential stay empty; `finalMaterialReviewed` is false. |',
     '| Wave 1 | All 98 unpublished; three seed foods on hold. |',
     '| AI disclosure | Credits & Sources now has an "Illustrations" section (section 6). |\n',
     '## 2. Final wording for "Nutrition & your cycle" (exact)\n',
     '- **Iron (only where a serving gives 10% or more):** "Women aged 19 to 50 need 18 mg of iron a day (men: 8 mg), partly because of menstrual blood loss (NIH ODS). That need applies every day of the month, not only during a period. A serving of this food has about {x} mg."',
     '- **Nutrient sentence (only where a serving gives a meaningful amount of something):** "This food provides nutrients that support general health."',
     '- **Evidence statement (always, as its own paragraph):** "There isn’t enough evidence to recommend eating this food in one particular phase of your cycle."',
     '- **Label on every profile:** "Nutrition values checked against USDA and NIH sources; not clinically reviewed."\n',
     '## 3. Food Detail screenshots (real app rendering, unpublished profiles)\n',
     '| Beef | Kale | Almond |', '|---|---|---|',
     '| ![Beef](wave-1-screens/beef.png) | ![Kale](wave-1-screens/kale.png) | ![Almond](wave-1-screens/almond.png) |',
     '| **Arugula** | **Sardine** | **Strawberry** |',
     '| ![Arugula](wave-1-screens/arugula.png) | ![Sardine](wave-1-screens/sardine.png) | ![Strawberry](wave-1-screens/strawberry.png) |\n',
     '## 4. The nine "Why this food?" rewrites (diff, with verification)\n',
     'Checked against the live USDA FoodData Central record for each FDC id; 18 mg iron reference from NIH ODS (Iron fact sheet, Table 1, women 19 to 50). Detail: `nine-rewrites-verification.md`. Phase assignments are unchanged.\n',
     '| Food (phase) | Before | After | Verified |', '|---|---|---|---|']
for r in rw:
    v = ver[r['id']]
    note = '; '.join(c[1] for c in v['checks'] if c[0].startswith('stated iron')) or 'no figure; wording only'
    L.append(f"| {r['id']} ({r['phase']}) | {r['shortBefore']} | {r['shortAfter']} | {'✓ ' if v['ok'] else '✗ '}{note} |")
L += ['',
      '## 5. `phases.json` changes (menstrual and luteal; follicular and ovulatory unchanged)\n',
      '| Field | Before | After |', '|---|---|---|',
      '| menstrual `focusBody` / `focus` | "…so Moon Cycle highlights iron-rich foods during this phase." | "…and iron is needed every day of the month, so iron-rich foods are worth including throughout your cycle; some are featured here." |',
      '| menstrual `learnMore` | "Nourishing meals, gentle movement and restful moments can offer support." | "Meals, gentle movement and restful moments are all options." |',
      '| menstrual `homeFocus` | "…can help you care for yourself." | "Meals, comfortable movement and moments of rest are ways to look after yourself, if they suit you." |',
      '| luteal `learnMore` | "…calming rituals can help you feel cared for." | "…calming rituals can all have a place in your day." |',
      '| luteal `homeFocus` | "…calming rituals can support your everyday comfort." | "…calming rituals are options for your everyday routine." |',
      '',
      'Kept: the descriptions of low or rising estrogen and progesterone, the lining being shed, the LH surge, and the hedged "you may notice" wording. No text says a food balances hormones, detoxifies, or must be eaten in a phase.\n',
      '## 6. Credits & Sources statement (exact)\n',
      '"Some food and lifestyle illustrations in Moon Cycle, including the recipe images, were generated using AI. They show the idea of a dish and may differ from a recipe in small details."\n',
      '## 7. Still open\n',
      '1. **Reviewer:** the final material has not been reviewed by a named person. Say who reviewed it and on what date, or leave it empty. No credential is implied.',
      '2. **Phase taglines** ("Fresh, curious & energising", "Grounded, steady & restorative") are editorial mood words, not nutrition claims. Keep or soften?',
      '3. **Publication:** only on your explicit "publish". The 98 stay unpublished until then.']
open(R + 'FINAL-APPROVAL-PACKAGE.md', 'w').write('\n'.join(L) + '\n')
print('written')
