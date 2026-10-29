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
    return proposed_cycle_note(profiles[fid]['name'], profiles[fid]['sections']['cycleRelevance'])


L = ['# Wave 1: final approval package (short)\n',
     f'**Nothing is published.** {len(wave1)} factual nutrition profiles are ready for your approval; they stay unpublished (`wave-1-candidate.json`, `publishable: false`) until you say so. Full detail: `wave-1-review-package.md` (12 profiles), `wave-1-qa-report.md` (checks).\n',
     '## What was checked\n',
     '- Every figure re-checked against the live USDA record; serving text matches the source; sodium, allergens and calculations tested.',
     '- Every caution is sourced (FDA, NIH ODS, NIDDK, MedlinePlus, CDC) or a catalogue allergen tag; none is unverified. Kidney bean guidance was corrected to the FDA wording first.',
     '- Format, readability, repeated text, overstatement and hormone/phase-claim checks pass (a handful of flags were read and accepted, listed in the QA report).',
     '- **Remaining issue found:** the iron sentence ("partly because of menstrual blood loss") appears on foods featured in non-menstrual phases (lamb, pork), which could read as "for your period". The wording below fixes this.\n',
     '## Proposed cycle-relevance wording (exact)\n',
     'The section is built from up to three parts, in this order. Nothing else is allowed in it.\n',
     '1. **Sourced nutrient fact (only where it applies).** One of:',
     '   - Iron (serving gives 10% or more of the reference): "Iron needs are higher for women aged 19 to 50 (18 mg a day, against 8 mg for men), partly because of menstrual blood loss (NIH ODS), **and that need applies every day of the month**; this serving has about {x} mg."',
     '   - Calcium (10% or more): "Calcium needs are 1,000 mg a day for women aged 19 to 50 (NIH ODS); this serving has about {x} mg."',
     '   - Folate or vitamin C with plant iron: the existing NIH ODS sentences, unchanged.',
     '2. **A plain statement that the cycle is not claimed (always):** "We found no reliable research linking {food} to a particular phase of the cycle."',
     '3. Nothing about hormones, fertility, PMS, mood, energy, "balance" or "support".\n',
     'Replaces the current closing line "No cycle-phase claim is made for {food}." (clearer: it says what was looked for and not found). **Heading (your preference): "Nutrition & your cycle".** It is used in the previews below only; the app still shows "Cycle relevance" until you approve publication, and the five already-published profiles are not changed.\n',
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
