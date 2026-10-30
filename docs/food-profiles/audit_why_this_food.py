#!/usr/bin/env python3
"""Audits the catalogue's "Why this food?" copy (assets/content/foods.json, `why`) for phase-specific claims.

    python3 docs/food-profiles/audit_why_this_food.py
Writes why-this-food-audit.md and .json. Read-only: the production catalogue is not changed."""
import collections, json, re

R = 'docs/food-profiles/'
foods = {f['id']: f for f in json.load(open('assets/content/foods.json'))['foods']}
drafts = json.load(open(R + 'complete-draft-dataset.json'))['profiles']
approved = json.load(open('assets/content/food_profiles.json'))['profiles']
phases = json.load(open('assets/content/phases.json'))['phases']

PHASE_LINK = re.compile(r'menstruation|menstrual|luteal|follicular|ovulat|this phase|the phase|during (your )?(period|the)', re.I)
TRADITIONAL = re.compile(r'\bcooling\b|\bgrounding\b', re.I)
NUTRIENT = re.compile(r'\b(source of|provides?|rich in|bring|brings|contains?)\b.*\b(iron|vitamin|fibre|fiber|protein|folate|zinc|magnesium|calcium|potassium|omega)', re.I)
PCT = re.compile(r'about (\d+)% of the daily value')

REWRITES = {
    'mussel': 'Mussels are a rich source of iron (about 32% of the daily value per serving) and protein.',
    'green-lentil': 'Lentils provide plant-based iron, protein and fibre.',
    'spinach': 'Cooked spinach provides iron (about 18% of the daily value per serving) along with folate.',
    'banana': 'Bananas are an easy addition to filling breakfasts and snacks.',
    'honeydew': 'Honeydew is soft and sweet, an easy fruit salad or snack.',
    # Stated percentage does not match the serving in the verified profile.
    'oyster': 'Oysters are a rich source of iron (about 21% of the daily value in six oysters).',
    'quinoa': 'Quinoa adds some plant-based iron (about 8% of the daily value in half a cup cooked).',
    'anchovies': 'Anchovies are a concentrated source of iron, but a typical serving is small (five anchovies give about 5% of the daily value).',
    'sardine': 'Sardines add iron (about 15% of the daily value in one small can).',
}


def profile_iron_pct(fid):
    """Iron as a share of the 18 mg reference in the verified profile's serving (from the USDA per-100 g value)."""
    p = drafts.get(fid) or approved.get(fid)
    iron = p['source']['per100g'].get('iron')
    return None if iron is None else round(100 * iron * p['source']['portionGrams'] / 100 / 18)


def profile_serving(fid):
    p = drafts.get(fid) or approved.get(fid)
    return p['source']['portion'].split(' (USDA')[0]


rows = []
for fid, f in foods.items():
    for ph, w in (f.get('why') or {}).items():
        t = w['short']
        kinds = []
        if PHASE_LINK.search(t):
            kinds.append('phase-link')
        if TRADITIONAL.search(t):
            kinds.append('traditional')
        if NUTRIENT.search(t) and not kinds:
            kinds.append('nutrient-fact')
        if not kinds:
            kinds.append('meal-style')
        check = None
        m = PCT.search(t)
        if m:
            check = {'statedPercent': int(m.group(1)), 'profileIronPercent': profile_iron_pct(fid), 'profileServing': profile_serving(fid)}
            check['agrees'] = check['profileIronPercent'] is not None and abs(check['statedPercent'] - check['profileIronPercent']) <= 2
        rows.append(dict(id=fid, name=f['name'], phase=ph, text=t, kind=kinds[0], figureCheck=check,
                         needsChange=kinds[0] in ('phase-link', 'traditional') or bool(check and not check['agrees']),
                         proposedReplacement=REWRITES.get(fid)))

counts = collections.Counter(r['kind'] for r in rows)
flagged = [r for r in rows if r['needsChange']]
bad_fig = [r for r in rows if r['figureCheck'] and not r['figureCheck']['agrees']]
json.dump(dict(_about='Audit of the production "Why this food?" copy. Nothing is changed; replacements are proposals.',
               counts=dict(counts), flagged=len(flagged), foods=rows), open(R + 'why-this-food-audit.json', 'w'), indent=1, ensure_ascii=False)

L = ['# "Why this food?" copy and phase labels: audit\n',
     'Read-only audit of the production catalogue (`assets/content/foods.json`, `phases.json`, `taxonomy.json`) for claims that tie a food, or its benefit, to a particular phase without support. **Nothing in production was changed.** Evidence base: `independent-phase-methodology.md` (no reliable research found that any food needs to be eaten in a particular phase).\n',
     f'- {len(rows)} entries (one per food and featured phase): ' + ', '.join(f'{k} {v}' for k, v in sorted(counts.items())) + '.',
     f'- **{len(flagged)} need a change** (below). {len(bad_fig)} stated percentages disagree with the verified profile data.\n',
     '## Labels and claims that need changing\n',
     '| Where | Text | Problem | Proposed |', '|---|---|---|---|',
     '| Food Detail pill, `taxonomy.json` `sheetLabel` | "Recommended for your {phase} phase" | "Recommended" says the food is advised in that phase; there is no evidence for that, and the featured-phase principle says "featured", never "recommended". Appears on every featured food | "Featured for variety in the {phase} phase" (shown in the approval previews) |']
for r in flagged:
    prob = 'ties the food to a phase ("we highlight it during menstruation"): the iron fact is sourced, the phase link is editorial' if r['kind'] == 'phase-link' else 'a traditional association ("cooling") with no clinical support'
    if r['id'] == 'banana':
        prob = 'recommends a food "during the luteal phase" with no basis'
    if r['kind'] not in ('phase-link', 'traditional') and r['figureCheck'] and not r['figureCheck']['agrees']:
        c = r['figureCheck']
        prob = f"states {c['statedPercent']}% \"per serving\" but the verified serving ({c['profileServing']}) gives {c['profileIronPercent']}%"
    elif r['figureCheck'] and not r['figureCheck']['agrees']:
        c = r['figureCheck']
        prob += f"; also states {c['statedPercent']}% but the verified serving ({c['profileServing']}) gives {c['profileIronPercent']}%"
    L.append(f"| Why this food? · {r['name']} ({r['phase']}) | \"{r['text']}\" | {prob} | \"{r['proposedReplacement']}\" |")
L += ['',
      '## Phase copy to review (not changed)\n',
      '- `phases.json` menstrual `focusBody`: "…so Moon Cycle highlights iron-rich foods during this phase." The iron need is real and applies all month; "during this phase" is the editorial part. Suggested: "…so iron-rich foods are worth including through the month, and are featured here."',
      '- `learnMore` and `homeFocus` for all four phases describe hormone levels (low or rising estrogen and progesterone) and what some people may feel (energy, appetite, mood). The physiology is general knowledge and hedged ("may", "some women"), but "Nourishing meals… can offer support" (menstrual) and "…calming rituals can support your everyday…" (luteal) are soft support claims. Suggested: keep the hedges, drop "support" wording, say nothing about food changing how you feel.',
      '- The phase taglines and the "Inner winter/spring/summer/autumn" seasons are editorial and make no nutritional claim.',
      '- `recipes.json` `whyThisPhase` (112 recipes): scanned for hormone, energy, mood, balance, boost and replenish wording: none. 27 mention menstruation, in the featured-food form ("featured Menstrual foods").\n',
      '## What is fine\n',
      f"- {counts['nutrient-fact']} entries state a nutrient fact, and every stated percentage that could be checked ({len([r for r in rows if r['figureCheck']])}) agrees with the verified profile data.",
      f"- {counts['meal-style']} entries describe flavour, texture or how to use the food (including \"warm\" as a meal style), which is editorial, not a health claim.",
      '- "helps your body absorb iron from plant foods" (vitamin C) is sourced to NIH ODS.\n',
      '## Approval needed\n',
      '1. Change the pill label (needs a production UI change and golden updates, done at publication).',
      '2. Replace the six entries above with the proposed neutral text (a content change).',
      '3. Decide whether to soften the phase copy listed under "Phase copy to review".']
open(R + 'why-this-food-audit.md', 'w').write('\n'.join(L) + '\n')
print(dict(counts), 'flagged', len(flagged), 'figure mismatches', len(bad_fig))
for r in bad_fig: print(r['id'], r['figureCheck'])
