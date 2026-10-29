#!/usr/bin/env python3
"""Applies the editorial and data corrections found by the audit to batch-N.src.json.

Run from the repo root (needs the USDA cache that audit_profiles.py fills):
    python3 docs/food-profiles/audit_profiles.py && python3 docs/food-profiles/apply_audit_fixes.py
then rebuild: for n in 1..14: python3 docs/food-profiles/build_draft_batch.py $n

Idempotent. It (1) adds sodium to every per-100 g record, from the USDA record each profile
cites; (2) removes boilerplate and filler from the cycle text; (3) fixes grammar and
wording; (4) attaches the sourced food-safety cautions defined in build_draft_batch.py.
"""
import json, os, re

HERE = os.path.dirname(os.path.abspath(__file__))
CACHE = os.environ.get('USDA_CACHE', '/tmp/usda')

CYCLE_BOILERPLATE = [
    (r'^This profile makes no claim linking (.+?) to a cycle phase or to period symptoms; it is here as one source of .+?, as part of a varied diet\.',
     r'No cycle-phase claim is made for \1.'),
    (r'^No cycle-phase claim is made for ([^;.]+?); this profile covers what it provides nutritionally, as part of a varied diet\.',
     r'No cycle-phase claim is made for \1.'),
]
# Plural subjects that were given a singular verb.
GRAMMAR = [
    (r'\b(Black-eyed peas|Kidney beans|Lima beans|Peanuts|Pinto beans|Split peas) is a good source', r'\1 are a good source'),
    (r'\b(Black beans|Cashews|Red lentils|White beans) adds plant iron', r'\1 add plant iron'),
]
# Filler and promotional wording, replaced exactly.
REWORD = {
    'grapes': {'cycle': 'No cycle-phase claim is made for grapes.',
               'offers': lambda s: s.replace(', so it is more refreshing than filling', '')},
    'watermelon': {'cycle': 'No cycle-phase claim is made for watermelon.',
                   'offers': lambda s: s.replace('is a hydrating fruit that is mostly water', 'is a fruit that is mostly water')},
    'flaxseeds': {'offers': lambda s: s.replace('fibre and healthy fats', 'fibre and fats')},
    'red-snapper': {'offers': lambda s: s.replace('Cooked snapper is', 'Cooked snapper (the USDA record covers mixed species) is', 1)},
    'shrimp': {'offers': lambda s: s if 'additives' in s else s.rstrip() + ' The USDA record notes that shrimp may contain additives that retain moisture.'},
    'eggplant': {'cycle': lambda s: s.replace(' to a meal at any time', ' to a meal')},
    'mushrooms': {'cycle': lambda s: s.replace(' to a meal at any point in the cycle', ' to a meal')},
    'string-bean': {'cycle': lambda s: s.replace(' to a meal at any point', ' to a meal')},
}
# Opening label for generated "what it offers" text where the catalogue name is broader than the USDA record.
LEADS = {'wheat': 'Durum wheat (dry)', 'mint': 'Spearmint (raw)', 'granola': 'Homemade granola',
         'salsa': 'Ready-to-serve salsa (with salt)'}
DROP_KEYS = {'bagel': ['vite'], 'granola': ['vite']}  # decision D5 in audit-notes.json
PORTIONS = {
    'cucumber': '85 g, about a third of a cucumber',
    'duck': 'about 3½ oz (100 g)',
    'sourdough-bread': '2 oz of sliced bread (USDA: 1 oz = 28.35 g)',
}
# Sourced food-safety cautions added by the audit (text and sources: build_draft_batch.py).
ADD_CAUTIONS = {
    'bean-sprouts': ['sprouts'], 'smoked-salmon': ['smoked-fish'], 'ham': ['deli-meat'],
    'feta': ['pasteurised-cheese'], 'goat-cheese': ['pasteurised-cheese'],
    'ricotta': ['pasteurised-cheese'], 'mozzarella': ['pasteurised-cheese'],
    'honey': ['honey-infant'], 'white-rice': ['rice-arsenic'], 'rice-cakes': ['rice-arsenic'], 'rice-noodles': ['rice-arsenic'], 'fava-beans': ['fava-g6pd'], 'kelp': ['iodine-ods'], 'wakame': ['iodine-ods'],
}


def sodium(fdc):
    raw = json.load(open(f'{CACHE}/{fdc}.json'))
    for fn in raw['foodNutrients']:
        if fn['nutrient']['number'] == '307' and 'value' in fn:
            return fn['value']


def sub(text, rules):
    for pat, rep in rules:
        text = re.sub(pat, rep, text)
    return text


for n in range(1, 15):
    path = f'{HERE}/batch-{n}.src.json'
    src = json.load(open(path))
    for fid, f in src['foods'].items():
        na = sodium(f['fdc'])
        if na is not None:
            f['per100']['na'] = na
        for field in ('cycle', 'offers'):
            if f[field] != 'TBD':
                f[field] = sub(f[field], GRAMMAR + (CYCLE_BOILERPLATE if field == 'cycle' else []))
        # Every cycle text must say that no phase-specific claim is made.
        if f['cycle'] != 'TBD' and not re.search(r'(cycle-phase|phase-specific) claim', f['cycle']):
            f['cycle'] = f['cycle'].rstrip() + ' No phase-specific claim is made.'
        for field, fix in REWORD.get(fid, {}).items():
            f[field] = fix(f[field]) if callable(fix) else fix
        if fid in DROP_KEYS:
            f['dropKeys'] = DROP_KEYS[fid]
        if fid in LEADS:
            f['lead'] = LEADS[fid]
        if fid in PORTIONS:
            f['portion'] = PORTIONS[fid]
        for c in ADD_CAUTIONS.get(fid, []):
            if c not in f.setdefault('cautions', []):
                f['cautions'].append(c)
    json.dump(src, open(path, 'w'), indent=1, ensure_ascii=False)
