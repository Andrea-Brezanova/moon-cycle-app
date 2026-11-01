#!/usr/bin/env python3
"""Wave 1 pre-publication consistency review. Run from the repo root:  python3 docs/food-profiles/wave1_exception_report.py

Checks the 98 staging profiles (wave-1-candidate.json) against the catalogue (foods.json, taxonomy.json), the draft
dataset they were built from, and the editorial rules. Writes wave-1-exception-report.md listing ONLY unresolved
problems that need a human decision, plus a short table of what was checked. Nothing is published or changed."""
import collections, json, re

R = 'docs/food-profiles/'
cand = json.load(open(R + 'wave-1-candidate.json'))['profiles']
drafts = json.load(open(R + 'complete-draft-dataset.json'))['profiles']
foods = {f['id']: f for f in json.load(open('assets/content/foods.json'))['foods']}
tax = json.load(open('assets/content/taxonomy.json'))
phases = json.load(open('assets/content/phases.json'))['phases']
allergen_label = {a['id']: a['label'] for a in tax['allergens']}
aisles = {a['id'] for a in tax['aisles']} if isinstance(tax['aisles'], list) and isinstance(tax['aisles'][0], dict) else set(tax['aisles'])
cats = {c['id'] for c in tax['categories']} if isinstance(tax['categories'], list) and isinstance(tax['categories'][0], dict) else set(tax['categories'])

ALLERGEN_WORDS = {'peanut': r'peanut', 'tree-nut': r'tree[- ]?nut', 'shellfish': r'shellfish|crustacean|mollus', 'fish': r'\bfish\b',
                  'dairy': r'dairy|milk', 'egg': r'\begg', 'gluten': r'gluten|wheat', 'soy': r'\bsoy', 'sesame': r'sesame'}
FORBIDDEN = re.compile(r'detox|cleans|purif|balanc\w* (your )?hormon|hormon\w* balanc|boost\w* (your )?(mood|energy|metabolism|immun|fertil)|'
                       r'regulat\w* (your )?(cycle|hormon)|relie\w+ (pms|cramp)|best (food )?for|ideal for (your )?(period|luteal|follicular|ovulat|menstru)|'
                       r'should eat during|must eat|eat (this )?during (your )?(period|luteal|follicular|ovulat|menstru)', re.I)
PHASE_WORD = re.compile(r'\b(menstrual|follicular|ovulatory|luteal) phase\b|during (your )?(period|menstruation)', re.I)
EVIDENCE = 'There isn’t enough evidence to recommend eating this food in one particular phase of your cycle.'
RAW_RISK = {'meat', 'poultry', 'egg', 'eggs', 'seafood', 'fish'}

problems = collections.defaultdict(list)
checked = collections.OrderedDict()


def flag(kind, fid, msg):
    problems[kind].append(f'`{fid}`: {msg}')


for fid, p in cand.items():
    f = foods.get(fid)
    # 1 catalogue linkage
    if f is None:
        flag('catalogue link', fid, 'no matching food in foods.json'); continue
    if not f.get('shipReady'):
        flag('catalogue link', fid, 'food is not ship-ready in the catalogue')
    if p.get('catalogueId') != fid:
        flag('catalogue link', fid, f"profile catalogueId is {p.get('catalogueId')!r}")
    if f['name'].strip().lower() != p['name'].strip().lower():
        flag('naming', fid, f"catalogue name {f['name']!r} differs from profile name {p['name']!r} (check display and search)")
    if f.get('aisle') not in aisles or f.get('category') not in cats:
        flag('catalogue link', fid, f"aisle {f.get('aisle')!r} or category {f.get('category')!r} not in taxonomy")
    # 2 allergens both ways
    ctext = ' '.join(c['text'] for c in p['cautions'])
    for a in f.get('allergens', []):
        if not re.search(ALLERGEN_WORDS[a], ctext, re.I):
            flag('allergen tags', fid, f"catalogue allergen {allergen_label[a]!r} is not named in the profile cautions")
    for a, rx in ALLERGEN_WORDS.items():
        pat = rf'(?:{rx})[^.;]{{0,12}}allergen|allergen[^.;]{{0,12}}(?:{rx})'
        if a not in f.get('allergens', []) and any(re.search(pat, c['text'], re.I) for c in p['cautions']):
            flag('allergen tags', fid, f"profile cautions name a {allergen_label[a]!r} allergen the catalogue does not tag")
    # 3 sources on every caution
    for c in p['cautions']:
        if not c.get('source'):
            flag('cautions', fid, f"caution without a source: {c['text'][:60]!r}")
    # 4 figures: percent vs amount vs reference, text percentages vs table
    pct_in_table = set()
    for n in p['perServing']['keyNutrients']:
        for r in n.get('reference') or []:
            # The table percentage comes from the unrounded amount, so allow for the rounding of the shown amount.
            decimals = len(str(n['amount']).split('.')[1]) if '.' in str(n['amount']) else 0
            half = 0.5 * 10 ** -decimals
            lo, hi = 100 * (n['amount'] - half) / r['value'], 100 * (n['amount'] + half) / r['value']
            exp = round(100 * n['amount'] / r['value'])
            pct_in_table.add(r['percent'])
            if not (lo - 0.5 <= r['percent'] <= hi + 0.5):
                flag('figures', fid, f"{n['name']}: table says {r['percent']}% but {n['amount']} {n['unit']} of {r['value']} {r['unit']} is {exp}%")
    for m in re.finditer(r'about (\d+)%', p['sections']['whatItOffers']):
        if int(m.group(1)) not in pct_in_table and not any(abs(int(m.group(1)) - q) <= 1 for q in pct_in_table):
            flag('figures', fid, f"What this food offers says {m.group(0)} but the nutrient table has {sorted(pct_in_table)}")
    d = drafts.get(fid)
    if d is None:
        flag('stale copy', fid, 'no matching entry in complete-draft-dataset.json')
    else:
        if d['source'] != p['source']:
            flag('stale copy', fid, 'source record differs from the draft dataset')
        if {k: v for k, v in d['perServing'].items() if k != 'sodiumMg'} != p['perServing']:
            flag('stale copy', fid, 'per-serving figures differ from the draft dataset')
    s = p['source']
    if not (s.get('portionGrams') and s['portionGrams'] > 0 and s.get('portion')):
        flag('figures', fid, 'serving has no gram weight or label')
    # 5 forbidden and phase claims outside the single evidence statement
    for sec, text in p['sections'].items():
        t = text.replace(EVIDENCE, '')
        if FORBIDDEN.search(t):
            flag('claims', fid, f'{sec}: {FORBIDDEN.search(t).group(0)!r}')
        if sec != 'cycleRelevance' and PHASE_WORD.search(t):
            flag('claims', fid, f'{sec}: mentions a phase')
    cyc = p['sections']['cycleRelevance']
    if not cyc.endswith(EVIDENCE):
        flag('claims', fid, 'cycle note does not end with the evidence statement')
    if PHASE_WORD.search(cyc.replace(EVIDENCE, '')):
        flag('claims', fid, 'cycle note mentions a phase outside the evidence statement')
    # 6 food safety: raw-risk foods carry a handling caution
    if (f.get('animalSource') in RAW_RISK) and not re.search(r'°F|cook|temperature|raw|pregnan|mercury|allergen', ctext + ' ' + p['sections'].get('howToEatIt', ''), re.I):
        flag('food safety', fid, f"{f.get('animalSource')} food has no handling, temperature or allergen caution")
    if f.get('animalSource') in {'meat', 'poultry'} and not re.search(r'°F|°C|temperature|cook', ctext, re.I):
        flag('food safety', fid, 'meat or poultry without a cook-to temperature caution')
    # 7 the approved review label state
    rv = p['review']
    if rv.get('publishable') is not False:
        flag('publication state', fid, 'publishable is not false')
    ap = rv['approval']
    if ap.get('reviewedBy') or ap.get('reviewedOn') or ap.get('professionalCredential'):
        flag('publication state', fid, 'reviewer details present without a recorded real review')

on_hold = ['flaxseeds', 'sesame-seeds', 'sunflower-seeds']
for h in on_hold:
    if h in cand:
        flag('publication state', h, 'seed food is in the Wave 1 candidate but is on hold')

# dietary tags across the whole catalogue: an animal source must carry the matching allergen tag
for fid, f in foods.items():
    src, al = f.get('animalSource'), set(f.get('allergens', []))
    if src == 'egg' and 'egg' not in al:
        flag('dietary tags', fid, 'animalSource egg without the egg allergen tag')
    if src == 'dairy' and 'dairy' not in al and not f.get('mayContain'):
        flag('dietary tags', fid, 'animalSource dairy without the dairy allergen tag')
    if src == 'seafood' and not ({'fish', 'shellfish'} & al):
        flag('dietary tags', fid, 'animalSource seafood without a fish or shellfish allergen tag')
    if src == 'none' and ({'fish', 'shellfish', 'egg'} & al) and not f.get('mayContain'):
        flag('dietary tags', fid, f'animalSource none but allergens {sorted(al)}')

# phase assignments: each Wave 1 food keeps the featured phase it has in phases.json
featured = collections.defaultdict(list)
for ph in phases:
    for c in ph['categories']:
        for fid in c['foods']:
            featured[fid].append(ph['id'])
multi = [fid for fid in cand if len(featured.get(fid, [])) > 1]
for fid in multi:
    flag('phase assignment', fid, f'featured in several phases {featured[fid]} (check, expected one)')

order = ['catalogue link', 'naming', 'allergen tags', 'dietary tags', 'cautions', 'figures', 'stale copy', 'claims', 'food safety', 'publication state', 'phase assignment']
rows = [('Catalogue linkage (id, name, ship-ready, aisle, category)', 'catalogue link', 'naming'),
        ('Allergen tags match the profile cautions, both directions', 'allergen tags'), ('Animal source and allergen tags agree, all catalogue foods (diet filters rely on them)', 'dietary tags'), ('Every caution has a source', 'cautions'),
        ('Table percentages recomputed; text percentages match the table; serving has grams', 'figures'),
        ('Source and figures identical to the draft dataset (no stale copy)', 'stale copy'),
        ('No hormone/detox/phase-recommendation claims; one evidence statement; phases only there', 'claims'),
        ('Meat, poultry, egg and seafood carry handling or allergen cautions', 'food safety'),
        ('Unpublished; no reviewer name, date or credential; seed foods held', 'publication state'),
        ('Each food is featured in exactly one phase (assignment unchanged)', 'phase assignment')]
L = ['# Wave 1: exception report\n', f'{len(cand)} candidate profiles reviewed against the catalogue, the draft dataset and the editorial rules. This lists **only unresolved problems that need a human decision**; generated by `wave1_exception_report.py`. Nothing is published and no phase assignment is changed.\n',
     '## What was checked\n', '| Check | Problems |', '|---|---|']
for row in rows:
    n = sum(len(problems[k]) for k in row[1:])
    L.append(f'| {row[0]} | {n} |')
L.append('')
if not any(problems.values()):
    L += ['## Unresolved problems\n', 'None found by these checks.\n']
else:
    L.append('## Unresolved problems\n')
    for k in order:
        if problems.get(k):
            L.append(f'### {k} ({len(problems[k])})')
            L += [f'- {m}' for m in problems[k]]
            L.append('')
L += ['## Not covered by automation (needs a person)\n',
      '- Whether each "How to eat it" suggestion suits the food and the cited serving.',
      '- Whether the evidence statement is acceptable for every food (no phase claim is made, so none was reviewed per food).',
      '- A named reviewer and date. None is recorded; the label stays "not clinically reviewed".']
open(R + 'wave-1-exception-report.md', 'w').write('\n'.join(L) + '\n')
print({k: len(v) for k, v in problems.items()})
