"""Builds the consolidated draft dataset and the review reports from the batches.

Run from the repo root: python3 docs/food-profiles/build_reports.py
Outputs (all docs, nothing bundled in the app):
  complete-draft-dataset.json   every draft profile keyed by catalogue food id, plus blocked entries
  coverage-report.md            exact counts by status and category
  editorial-review-report.md    review notes grouped by issue type
  review-list.md                one prioritised review list with sampling sheets per category
"""
import glob, json, re, collections

ROOT = 'docs/food-profiles/'
foods = {f['id']: f for f in json.load(open('assets/content/foods.json'))['foods']}
approved = set(json.load(open('assets/content/food_profiles.json'))['profiles'])
queue = {i['foodId']: i for i in json.load(open(ROOT + 'work-queue.json'))['items']}
blocked = json.load(open(ROOT + 'blocked.json'))
mapping = json.load(open(ROOT + 'mapping-142.json'))
phase_ids = {i for m in mapping for i in m.get('catalogueIds', [])}

profiles, batch_of, notes = {}, {}, {}
for path in sorted(glob.glob(ROOT + 'draft-batch-*.json'), key=lambda p: int(re.search(r'(\d+)\.json', p).group(1))):
    n = int(re.search(r'(\d+)\.json', path).group(1))
    src = json.load(open(ROOT + f'batch-{n}.src.json'))['foods']
    for fid, p in json.load(open(path))['profiles'].items():
        profiles[fid] = p
        batch_of[fid] = n
        notes[fid] = src.get(fid, {}).get('reviewNote') or ''

dataset = {
    '_status': 'DRAFT for editorial review. Not production content; nothing here is bundled in the app or published.',
    '_counts': {'catalogueFoods': len(foods), 'approvedPublished': len(approved), 'drafted': len(profiles), 'blocked': len(blocked)},
    'profiles': {fid: dict(profiles[fid], status='drafted-unreviewed', draftBatch=batch_of[fid]) for fid in sorted(profiles)},
    'blocked': {fid: {'name': foods[fid]['name'], 'reason': r} for fid, r in sorted(blocked.items())},
    'approved': sorted(approved),
}
json.dump(dataset, open(ROOT + 'complete-draft-dataset.json', 'w'), indent=1, ensure_ascii=False)

# ---- coverage ----
def status(fid):
    return 'approved' if fid in approved else 'blocked' if fid in blocked else 'drafted' if fid in profiles else 'missing'
cats = collections.defaultdict(collections.Counter)
for fid, f in foods.items():
    cats[f.get('category', '?')][status(fid)] += 1
tot = collections.Counter(status(f) for f in foods)
phase_total = len([f for f in foods if f in phase_ids])
phase_counts = collections.Counter(status(f) for f in foods if f in phase_ids)
L = ['# Food profile coverage report', '', 'All numbers computed by `build_reports.py` from the catalogue and the draft files.', '',
     f'- Catalogue foods: **{len(foods)}**',
     f'- Approved and published (unchanged): **{tot["approved"]}**',
     f'- Drafted (USDA-sourced, validated by script/test, **unreviewed, unpublished**): **{tot["drafted"]}**',
     f'- Blocked (no sound source or needs an owner decision): **{tot["blocked"]}**',
     f'- Missing: **{tot["missing"]}**', '',
     f'Phase-assigned foods (from mapping-142.json): {phase_total}; approved {phase_counts["approved"]}, drafted {phase_counts["drafted"]}, blocked {phase_counts["blocked"]}, missing {phase_counts["missing"]}.', '',
     'Tracking states used: Published (approved only) / Drafted / Source matched (USDA record named, FDC id and serving recorded) / Validated (numbers recomputed by script and Dart test) / Editorial review needed (all drafted foods) / Blocked.',
     'Every drafted food is Drafted + Source matched + Validated + Editorial review needed. None is Published.', '',
     '## By category', '', '| Category | Total | Approved | Drafted | Blocked |', '|---|---|---|---|---|']
for c in sorted(cats):
    k = cats[c]
    L.append(f'| {c} | {sum(k.values())} | {k["approved"]} | {k["drafted"]} | {k["blocked"]} |')
L += ['', '## Blocked foods', '', '| Food | Reason |', '|---|---|']
for fid, r in sorted(blocked.items()):
    L.append(f'| {foods[fid]["name"]} (`{fid}`) | {r} |')
open(ROOT + 'coverage-report.md', 'w').write('\n'.join(L) + '\n')

# ---- issues grouped ----
RULES = [
 ('Food identity or variety not specified by the catalogue', r'does not say|not specify|unspecified|different (fruit|food|fish|vegetable)|separate (food|record)|are different|differ'),
 ('Preparation state (raw / cooked / dry / canned) chosen by the researcher', r'\braw\b|\bdry\b|uncooked|cooked|canned|dried|roasted|fried|battered'),
 ('Fortification or enrichment drives the numbers', r'fortif|enrich'),
 ('USDA record lacks some nutrient values (so they are not shown)', r'lists no|not given|not in this|no fibre|not shown'),
 ('Unusual or surprising USDA value to double-check', r'unusually|surprising|much higher|very high|flagged'),
 ('Processed food: sodium or added sugar not in the nutrient set', r'sodium|added sugar|salty|high in salt'),
 ('Caution needs a source or was not researched', r'not looked up|not researched|not read|source not|sourced caution'),
 ('Serving size assumption (labelled USDA measure, may differ from real portions)', r'serving|portion|larger|typical'),
]
groups = collections.defaultdict(list)
for fid in sorted(profiles):
    t = notes[fid]
    for title, rx in RULES:
        if t and re.search(rx, t, re.I):
            groups[title].append((fid, t))
unsourced = [fid for fid in sorted(profiles) if any('no external source recorded' in c['source'] for c in profiles[fid]['cautions'])]
L = ['# Editorial review report (grouped by issue type)', '', 'Generated from the researcher notes attached to each draft. A food can appear under several types. Nothing here is published.', '']
for title, _ in RULES:
    L += [f'## {title}', '', f'{len(groups[title])} foods', '']
    for fid, t in groups[title]:
        L.append(f'- **{foods[fid]["name"]}** (`{fid}`, batch {batch_of[fid]}): {t}')
    L.append('')
L += ['## Cautions carried over from the catalogue without an external source', '',
      f'{len(unsourced)} drafts contain at least one catalogue caution whose source is "Existing MoonCycle catalogue caution (no external source recorded)". They are kept (the app shows a profile\'s cautions instead of the catalogue\'s) but need a source or an editorial decision.', '']
for fid in unsourced:
    L.append(f'- {foods[fid]["name"]} (`{fid}`): ' + '; '.join(c['text'] for c in profiles[fid]['cautions'] if 'no external source recorded' in c['source']))
L += ['', '## Blocked', '']
for fid, r in sorted(blocked.items()):
    L.append(f'- **{foods[fid]["name"]}** (`{fid}`): {r}')
no_note = [fid for fid in profiles if not notes[fid]]
L += ['', f'## Drafts with no researcher note ({len(no_note)})', '', 'These have a USDA record matching the catalogue name, a labelled serving and no ambiguity noted. They still need the normal editorial read.', '']
open(ROOT + 'editorial-review-report.md', 'w').write('\n'.join(L) + '\n')

# ---- review list ----
def risk(fid):
    p = profiles[fid]
    s = 0
    if notes[fid]:
        s += 2 + sum(1 for _, rx in RULES if re.search(rx, notes[fid], re.I))
    s += sum(1 for c in p['cautions'] if 'no external source recorded' in c['source'])
    s += 2 if any(c['source'] and 'no external source' not in c['source'] for c in p['cautions']) else 0
    return s
L = ['# Prioritised review list and sampling sheets', '',
     'Order: (1) blocked foods needing an owner decision, (2) categories with the highest number of risk flags, (3) within a category, highest-risk foods first. A reviewer who checks the **sample** of each category (the top-risk 4 plus every 10th food) and finds no problem can spot-check the rest; any problem in a sample means checking the whole category.', '',
     '## 1. Owner decisions (blocked)', '']
for fid, r in sorted(blocked.items()):
    L.append(f'- [ ] **{foods[fid]["name"]}**: {r}')
bycat = collections.defaultdict(list)
for fid in profiles:
    bycat[foods[fid].get('category', '?')].append(fid)
order = sorted(bycat, key=lambda c: -sum(risk(f) for f in bycat[c]) / len(bycat[c]))
L += ['', '## 2. Categories (highest average risk first)', '', '| Category | Drafts | Avg risk | Sample size |', '|---|---|---|---|']
samples = {}
for c in order:
    ids = sorted(bycat[c], key=lambda f: (-risk(f), f))
    s = ids[:4] + [f for i, f in enumerate(ids) if i % 10 == 9 and f not in ids[:4]]
    samples[c] = s
    L.append(f'| {c} | {len(ids)} | {sum(risk(f) for f in ids) / len(ids):.1f} | {len(s)} |')
L += ['', '## 3. Sampling sheets', '', 'For each food, tick: [ ] food identity matches the catalogue; [ ] USDA record and preparation are right; [ ] serving is realistic; [ ] percentages look right against the NIH ODS value; [ ] cautions are sourced and proportionate; [ ] no claim beyond the numbers; [ ] wording reads well.', '']
for c in order:
    L += [f'### {c}', '', '| Food | Batch | FDC id | Preparation | Serving | Risk | Why sampled |', '|---|---|---|---|---|---|---|']
    for fid in samples[c]:
        p = profiles[fid]
        src = p['source']
        L.append(f'| {foods[fid]["name"]} (`{fid}`) | {batch_of[fid]} | {src["usdaFdcId"]} | {src["preparationState"]} | {src["portion"].split(" (USDA")[0]} | {risk(fid)} | {(notes[fid] or "no note")[:110]} |')
    L.append('')
open(ROOT + 'review-list.md', 'w').write('\n'.join(L) + '\n')
print(dataset['_counts'])
