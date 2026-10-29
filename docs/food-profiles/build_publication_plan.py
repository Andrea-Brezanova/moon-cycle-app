"""Builds the publication plan: publication-plan.md, publication-plan.json and wave-1-candidate.json.

Run after build_audit_report.py:  python3 docs/food-profiles/build_publication_plan.py
Nothing here publishes anything. wave-1-candidate.json is a docs file in the approved-profile format with
`publishable: false`; moving profiles into assets/content/food_profiles.json is a separate, approved change.
"""
import collections, json, sys

sys.path.insert(0, 'docs/food-profiles')
from wave1_wording import HEADING, proposed_cycle_note  # noqa: E402

ROOT = 'docs/food-profiles/'
data = json.load(open(ROOT + 'complete-draft-dataset.json'))
profiles, blocked = data['profiles'], data['blocked']
notes = json.load(open(ROOT + 'audit-notes.json'))
foods = {f['id']: f for f in json.load(open('assets/content/foods.json'))['foods']}
phase = {k: list(f['why'])[0] for k, f in foods.items() if f['why']}
dec = {f for d in notes['decisions'] for f in d['foods']}
name = lambda i: profiles[i]['name']
has = lambda p, s: any(c['status'] == s for c in p['cautions'])

group = {}
for k, p in profiles.items():
    group[k] = 'decision' if k in dec else 'source-work' if has(p, 'unverified-inherited') else 'ready'
wave1 = sorted(k for k, g in group.items() if g == 'ready' and k in phase and not profiles[k]['nutritionNotes']
               and not has(profiles[k], 'partly-sourced')
               and not any(r['kind'] in ('identity', 'servingState', 'unusualValues') for r in profiles[k]['recordNotes']))
ready_other = sorted(k for k, g in group.items() if g == 'ready' and k not in wave1)


def why_not_wave1(k):
    p, r = profiles[k], []
    if k not in phase:
        r.append('not featured in a phase')
    if p['nutritionNotes']:
        r.append('has a sodium note')
    if has(p, 'partly-sourced'):
        r.append('has a partly sourced caution')
    if any(x['kind'] in ('identity', 'servingState', 'unusualValues') for x in p['recordNotes']):
        r.append('record narrower than the catalogue name or unusual value (resolved in the text)')
    return '; '.join(r)


# Candidate file in the approved-profile format (no audit-only fields).
cand = {}
for k in wave1:
    p = profiles[k]
    sections = dict(p['sections'], cycleRelevance=proposed_cycle_note(p['name'], p['sections']['cycleRelevance']))
    cand[k] = {'catalogueId': k, 'name': p['name'], 'sections': sections,
               'source': {x: p['source'][x] for x in ('usdaFdcId', 'usdaDescription', 'dataType', 'published', 'preparationState', 'portionGrams', 'portion', 'per100g')},
               'perServing': {x: v for x, v in p['perServing'].items() if x != 'sodiumMg'},
               'cautions': [{'text': c['text'], 'source': c['source']} for c in p['cautions']],
               'evidence': p['evidence'],
               'review': {'composition': 'verified against USDA FoodData Central (re-checked in the audit)', 'referenceIntakes': 'verified against NIH ODS',
                          'cautions': 'sourced or catalogue allergen tags', 'editorial': 'awaiting owner approval',
                          'clinical': 'not clinically reviewed', 'publishable': False}}
json.dump({'_status': 'CANDIDATE for owner approval. Not bundled, not published. publishable is false for every profile. The cycleRelevance text is the PROPOSED final wording.', 'cycleHeading': HEADING, 'profiles': cand},
          open(ROOT + 'wave-1-candidate.json', 'w'), indent=1, ensure_ascii=False)

# A sampling sheet spread over phases and categories (first food alphabetically in each cell, up to 12).
cells = collections.OrderedDict()
for k in wave1:
    cells.setdefault((phase[k], foods[k]['category']), k)
sample = []
by_phase = collections.defaultdict(list)
for (ph, cat), k in cells.items():
    by_phase[ph].append(k)
for i in range(3):
    for ph in ('menstrual', 'follicular', 'ovulatory', 'luteal'):
        if i < len(by_phase[ph]):
            sample.append(by_phase[ph][i])

plan = {'ready': sorted(k for k, g in group.items() if g == 'ready'), 'wave1': wave1, 'readyOutsideWave1': ready_other,
        'sourceWork': sorted(k for k, g in group.items() if g == 'source-work'), 'needsDecision': sorted(k for k, g in group.items() if g == 'decision'),
        'blocked': sorted(blocked), 'alreadyApproved': data['approved'], 'sampleSheet': sample}
json.dump(plan, open(ROOT + 'publication-plan.json', 'w'), indent=1)

L = []
w = L.append
w('# Publication plan for the Food Detail profiles\n')
w('**Nothing is published by this plan.** All drafts stay unreviewed and outside the app until you approve them and a separate change moves them into `assets/content/food_profiles.json`. Food Detail, Build a Meal and the phase mapping are untouched.\n')
w('## Where the 271 foods stand\n')
w('| Group | Foods | Meaning |\n|---|---|---|')
w(f'| Already approved and published | {len(plan["alreadyApproved"])} | Spinach, lentils, pumpkin seeds, broccoli, orange. Unchanged. |')
w(f'| **Wave 1: recommended first group** | **{len(wave1)}** | Ready, featured in a phase, every caution sourced or an allergen tag, no sodium note, no open question. |')
w(f'| Ready, but not in Wave 1 | {len(ready_other)} | Also clean, held back for a reason listed below (not featured in a phase, sodium note, record note). Can follow in Wave 2. |')
extra = sum(1 for k in plan['needsDecision'] if has(profiles[k], 'unverified-inherited'))
w(f'| Requires source work | {len(plan["sourceWork"])} | Carry an inherited caution I could not source ({extra} more profiles also carry one but are counted under decisions). Publishable only if you accept it labelled as inherited, or after a source is found. |')
w(f'| Requires your decision | {len(plan["needsDecision"])} | Affected by one of the {len(notes["decisions"])} decisions in `audit-report.md` section 3. |')
w(f'| Blocked | {len(blocked)} | Decision table in `audit-report.md` section 5. |')
w(f'| **Total** | **{len(plan["alreadyApproved"]) + len(profiles) + len(blocked)}** | |\n')

w('## What you need to decide to publish Wave 1 safely\n')
w('These five decisions cover every Wave 1 profile; none needs a per-food judgment.\n')
w('1. **Approve the five-part template and wording.** Cycle relevance reads "No cycle-phase claim is made for <food>." plus, where a serving gives 10% or more of the reference, a sourced NIH ODS sentence on iron or calcium. Opening lines are built from the recomputed numbers. (Section "Sampling sheet" shows 12 complete profiles.)')
w('2. **Approve the cautions as written.** Every Wave 1 caution is either `sourced` (an authoritative page, named in the profile) or a `catalogue-tag` allergen line taken from `foods.json`. The list of distinct texts is in the sampling sheet and in `wave-1-candidate.json`.')
w('3. **Approve the review label.** "Nutrition values checked against USDA and NIH sources; not clinically reviewed." (the same label the five approved profiles use).')
w('4. **Name the reviewer and date.** An approved profile records who approved it and when; that is yours to fill in.')
w('5. **Approve the publishing step.** After approval, a small separate change copies the approved profiles from `wave-1-candidate.json` into `assets/content/food_profiles.json` with `publishable: true`, runs CI, and then I rebuild the iPhone app. Approving a sample is not approval of a food that was not in the sample unless you say so.\n')
w('Safe default if you approve nothing: no profile appears; Food Detail looks exactly as it does today.\n')

w('## Wave 1 (%d profiles)\n' % len(wave1))
for ph in ('menstrual', 'follicular', 'ovulatory', 'luteal'):
    w(f'- **{ph}** ({sum(1 for k in wave1 if phase[k] == ph)}): ' + ', '.join(name(k) for k in wave1 if phase[k] == ph))
w('')
w('## Ready but not in Wave 1 (%d)\n' % len(ready_other))
for k in ready_other:
    w(f'- {name(k)}: {why_not_wave1(k)}')
w('\n## Requires source work (%d)\n' % len(plan['sourceWork']))
for k in plan['sourceWork']:
    w(f'- {name(k)}: ' + '; '.join(c['text'] for c in profiles[k]['cautions'] if c['status'] == 'unverified-inherited'))
w('\n## Requires your decision (%d profiles)\n' % len(plan['needsDecision']))
for d in notes['decisions']:
    w(f'- **{d["id"]} {d["title"]}**: ' + ', '.join(name(f) if f in profiles else f for f in d['foods']))
w('\n## Blocked (%d)\n' % len(blocked))
w(', '.join(blocked[k]['name'] for k in sorted(blocked)) + '\n')

w('## Sampling sheet: 12 complete Wave 1 profiles\n')
for k in sample:
    p = profiles[k]
    s = p['sections']
    w(f'### {p["name"]} (`{k}`, {phase[k]}, {foods[k]["category"]})\n')
    w(f'- Record: USDA FDC {p["source"]["usdaFdcId"]}, "{p["source"]["usdaDescription"]}" ({p["source"]["dataType"]}, {p["source"]["published"]}); serving {p["source"]["portion"]}')
    w(f'- What it offers: {s["whatItOffers"]}')
    w(f'- How to eat it: {s["howToEatIt"]}')
    w(f'- Cycle relevance: {s["cycleRelevance"]}')
    for c in p['cautions']:
        w(f'- Caution ({c["status"]}): {c["text"]} *[{c["source"]}]*')
    w('')
open(ROOT + 'publication-plan.md', 'w').write('\n'.join(L) + '\n')
print({k: len(v) for k, v in plan.items()})
