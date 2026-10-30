#!/usr/bin/env python3
"""Builds wave-1-approval-summary.md: the short final approval package for Wave 1.

    python3 docs/food-profiles/build_wave1_approval_summary.py
It renders the PROPOSED cycle-relevance wording on representative profiles without changing any draft."""
import json, re, sys

sys.path.insert(0, 'docs/food-profiles')
from wave1_wording import HEADING, proposed_cycle_note  # noqa: E402

R = 'docs/food-profiles/'
profiles = json.load(open(R + 'complete-draft-dataset.json'))['profiles']
plan = json.load(open(R + 'publication-plan.json'))
meta = json.load(open('assets/content/food_profiles.json'))
foods = {f['id']: f for f in json.load(open('assets/content/foods.json'))['foods']}
phase = {k: list(f['why'])[0] for k, f in foods.items() if f['why']}
wave1 = plan['wave1']
CHOSEN = ['beef', 'kale', 'almond', 'arugula', 'sardine', 'strawberry']
CHOSEN = [k for k in CHOSEN if k in wave1][:6]


def proposed(fid):
    return proposed_cycle_note(profiles[fid])


L = ['# Wave 1: final approval package (short)\n',
     f'**Nothing is published.** {len(wave1)} factual nutrition profiles are ready for your approval; they stay unpublished (`wave-1-candidate.json`, `publishable: false`) until you say so. Full detail: `wave-1-review-package.md` (12 profiles), `wave-1-qa-report.md` (checks).\n',
     '## What was checked\n',
     '- Every figure re-checked against the live USDA record; serving text matches the source; sodium, allergens and calculations tested.',
     '- Every caution is sourced (FDA, NIH ODS, NIDDK, MedlinePlus, CDC) or a catalogue allergen tag; none is unverified. Kidney bean guidance was corrected to the FDA wording first.',
     '- Format, readability, repeated text, overstatement and hormone/phase-claim checks pass (a handful of flags were read and accepted, listed in the QA report).',
     '- **Issue found and fixed in the proposal:** the old iron sentence also appeared on foods featured in other phases (lamb, pork), which could read as "for your period". The new iron sentence says the need applies every day of the month.\n',
     '- Real Food Detail renderings of the proposed wording, heading and badge: `wave-1-screens/` (beef, kale, almond, arugula, sardine, strawberry).\n',
     '## Proposed wording for "Nutrition & your cycle" (exact)\n',
     'Heading: **Nutrition & your cycle** (your choice). The note is built from up to three parts, in this order, and nothing else is allowed in it:\n',
     '1. **Iron (only where a serving gives 10% or more of the iron reference).** Simplified, with its source and the measured amount: "Women aged 19 to 50 need 18 mg of iron a day (men: 8 mg), partly because of menstrual blood loss (NIH ODS). That need applies every day of the month, not only during a period. A serving of this food has about {x} mg."',
     '2. **Any other sourced or descriptive fact already in the profile**, kept as written (calcium, folate, vitamin C with plant iron, a mercury, gluten or product note).',
     '3. **Closing statement, always.** Your wording, with "it" written as "this food" so it reads correctly for plural foods such as sardines or eggs: "This food provides nutrients that support general health. There is currently insufficient evidence to recommend eating this food during one particular menstrual phase."',
     '   - **Used only where it is accurate.** The first sentence ("provides nutrients that support general health") appears only where a serving gives at least 10% of a reference nutrient, 5 g of protein, 3 g of fibre, 20 µg of vitamin K or 0.25 g of omega-3. For the remaining foods (barley, bean sprouts, eggplant, fig and plum) the closing is only the second sentence. The second sentence is consistent with the research register (`independent-phase-methodology.md`): no reliable research ties any of these foods to one phase.',
     '   - **Optional plainer wording** (your call; the fixed sentence reads at a difficult level, Flesch 33): "There isn\'t enough evidence to recommend eating this food in one particular phase of your cycle."\n',
     '**Badge.** The existing pill "Recommended for your {phase} phase" contradicts the evidence, so the previews show **"Featured for variety in the {phase} phase"** instead (the principle already says "featured", never "recommended"). The production app still has the old pill until you approve the change.\n',
     '**"Why this food?" copy.** Audited in `why-this-food-audit.md`: 9 of the 142 production lines need changing (5 tie a food to a phase: mussel, oyster, lentils and spinach "highlight during menstruation" and banana "during the luteal phase"; 1 calls honeydew "cooling"; 3 more, sardine, quinoa and anchovies, state an iron percentage that does not match the verified serving, as does oyster). Proposed replacements are listed there; production is unchanged.\n',
     '## Representative complete profiles with the proposed wording\n']
for k in CHOSEN:
    p = profiles[k]
    s = p['sections']
    src = p['source']
    ps = p['perServing']
    L.append(f'### {p["name"]}  (featured in the {phase[k]} phase; editorial)\n')
    L.append(f'*Record:* USDA FDC {src["usdaFdcId"]}, "{src["usdaDescription"]}" ({src["published"]}). *Serving:* {s["practicalServing"]}. *Per serving:* {ps["energyKcal"]} kcal; ' + ', '.join(f'{n["name"]} {n["amount"]} {n["unit"]}' + (f' ({n["reference"][0]["percent"]}%)' if n.get('reference') else '') for n in ps['keyNutrients']) + '.\n')
    L.append(f'1. **What this food offers.** {s["whatItOffers"]}')
    L.append(f'2. **A practical serving.** {s["practicalServing"]}')
    L.append(f'3. **How to eat it.** {s["howToEatIt"]}')
    L.append(f'4. **Nutrition & your cycle (proposed).** {proposed(k)}')
    L.append(f'   *Currently:* {s["cycleRelevance"]}')
    L.append('5. **Good to know.** ' + (' / '.join(f'{c["text"]}' for c in p['cautions']) or '(none)'))
    L.append('   *Sources:* ' + '; '.join(sorted({c['source'] for c in p['cautions']})) if p['cautions'] else '')
    L.append('')
L += ['## Labels\n',
      f'- Review label on every profile: "{meta["reviewLabel"]}"',
      '- No profile is described as clinically reviewed; none has been. No reviewer credentials are stated or implied.',
      '- Data attribution: nutrient amounts from USDA FoodData Central (record and date shown), reference intakes from NIH ODS.\n',
      '## What I need from you\n',
      '1. Approve the wording above (or amend it). The heading "Nutrition & your cycle" is already your choice.',
      '2. Approve Wave 1 for publication, or name the profiles to hold back.',
      '3. Give the name and date to record for the editorial approval. No professional credential is assigned or implied; the label stays "not clinically reviewed".',
      '4. Check the Food Detail previews in `wave-1-screens/` (real app rendering of the proposed text; unpublished).',
      '5. Say "publish" when ready: a separate change moves the approved profiles into `assets/content/food_profiles.json` with the new wording and heading, CI runs, then I rebuild the iPhone app. The three seed foods stay on hold. If you do not approve, nothing changes.\n']
open(R + 'wave-1-approval-summary.md', 'w').write('\n'.join(L) + '\n')
print('ok', CHOSEN)
