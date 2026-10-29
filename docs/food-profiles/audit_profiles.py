#!/usr/bin/env python3
"""Independent audit of the drafted Food Detail profiles.

Re-checks every profile in complete-draft-dataset.json against the live USDA FoodData
Central record it cites (identity, publication date, per-100 g values, serving weight)
and recomputes every per-serving amount and reference-intake percentage. Writes
audit-findings.json. Needs network access; the Dart test covers the same invariants
offline.

    python3 docs/food-profiles/audit_profiles.py [--refresh]
"""
import json, os, re, subprocess, sys, concurrent.futures as cf

HERE = os.path.dirname(os.path.abspath(__file__))
CACHE = os.environ.get('USDA_CACHE', '/tmp/usda')
NUM = {'208': 'kcal', '957': 'kcalA', '203': 'protein', '204': 'fat', '205': 'carb',
       '291': 'fiber', '301': 'ca', '303': 'iron', '304': 'mg', '306': 'k', '309': 'zn',
       '401': 'vitc', '435': 'folate', '418': 'b12', '320': 'vita', '328': 'vitd',
       '323': 'vite', '430': 'vitk', '307': 'na', '629': 'epa', '621': 'dha', '1123': 'vite'}
FRAC = {'½': .5, '¼': .25, '¾': .75, '⅓': 1 / 3, '⅔': 2 / 3, '⅛': .125}


def fetch(fid):
    path = f'{CACHE}/{fid}.json'
    if '--refresh' in sys.argv or not os.path.exists(path) or os.path.getsize(path) < 200:
        os.makedirs(CACHE, exist_ok=True)
        for t in range(4):
            subprocess.run(['curl', '-s', '-m', '30', '-A', 'Mozilla/5.0',
                            f'https://fdc.nal.usda.gov/portal-data/external/{fid}', '-o', path])
            if os.path.getsize(path) > 200:
                break
    return json.load(open(path))


def qty(text):
    m = re.match(r'\s*(\d+)?\s*([½¼¾⅓⅔⅛])?(?:\s*(\d+)/(\d+))?', text)
    if not m or not (m.group(1) or m.group(2) or m.group(3)):
        return None
    v = float(m.group(1) or 0)
    if m.group(2):
        v += FRAC[m.group(2)]
    if m.group(3):
        v += int(m.group(3)) / int(m.group(4))
    return v


# Findings a person looked at and accepted, with the reason (the audit still reports them).
REVIEWED_OK = {
    ('chestnut', 'serving'): '1 oz = 28.35 g is a USDA measure; USDA 10 kernels = 84 g, so "about 3 kernels" holds.',
    ('cottage-cheese', 'serving'): 'USDA 1 cup = 226 g and 4 oz = 113 g, so half a cup is 113 g.',
}


def exp_pct(ps, kn, s, f, keymap, r):
    src = keymap.get(kn['name'])
    return (s['per100g'][src] * f / r['value'] * 100) if src in s['per100g'] else -999


def audit(fid, p, raw):
    out = []
    s = p['source']
    if raw.get('fdcId') != s['usdaFdcId']:
        out.append(('provenance', 'fdcId does not match the USDA record'))
    if raw.get('description') != s['usdaDescription']:
        out.append(('identity', f"USDA description changed: {raw.get('description')!r}"))
    if raw.get('lastUpdated') != s['published']:
        out.append(('provenance', f"USDA date {raw.get('lastUpdated')} != {s['published']}"))
    for k in ('usdaFdcId', 'usdaDescription', 'dataType', 'published', 'preparationState', 'portion'):
        if not s.get(k):
            out.append(('provenance', f'missing {k}'))
    if not s.get('portionGrams'):
        out.append(('provenance', 'missing portionGrams'))
    # per-100 g values
    vals = {}
    for fn in raw.get('foodNutrients', []):
        k = NUM.get((fn.get('nutrient') or {}).get('number'))
        if k and 'value' in fn:
            vals.setdefault(k, fn['value'])
    n3 = [fn['value'] for fn in raw.get('foodNutrients', [])
          if (fn.get('nutrient') or {}).get('number') in ('629', '621') and 'value' in fn]
    if n3:
        vals['omega3'] = sum(n3)
    for k, v in s['per100g'].items():
        ref = vals.get(k)
        if k == 'kcal' and ref is None:
            ref = vals.get('kcalA')
        if ref is None:
            if v not in (0, None):
                out.append(('nutrients', f'{k}: stored {v}, USDA has no value'))
        elif abs(ref - v) > max(0.006, abs(ref) * 0.005):
            out.append(('nutrients', f'{k}: stored {v} != USDA {ref}'))
    # serving weight against USDA household measures
    m = re.search(r'USDA: (?:(\d+(?:\.\d+)?)\s*([a-z ]+?)\s*=\s*)?(\d+(?:\.\d+)?) g\)', s['portion'])
    q = qty(s['portion'])
    measures = raw.get('foodMeasures', [])
    if m:
        g = float(m.group(3))
        if not any(abs(x.get('gramWeight', 0) - g) < 0.06 for x in measures):
            out.append(('serving', f'{g} g is not a USDA household measure'))
        if m.group(1):
            n = float(m.group(1))
            ok = q is not None and abs(q * g / n - s['portionGrams']) < 0.6
        else:  # "(USDA: 85 g)": the quoted weight is the whole measure named in the text
            ok = abs(g - s['portionGrams']) < 0.6 or (q is not None and abs(q * g - s['portionGrams']) < 0.6)
        if not ok:
            out.append(('serving', f"portionGrams {s['portionGrams']} vs text {s['portion']!r}"))
    elif 'reference amount' in s['portion'] or re.search(r'\d+ g', s['portion']):
        pass
    else:
        out.append(('serving', 'portion text has no USDA household measure'))
    # per-serving recomputation
    f = s['portionGrams'] / 100
    ps = p['perServing']
    for key, src in (('proteinG', 'protein'), ('fatG', 'fat'), ('carbohydrateG', 'carb'), ('fiberG', 'fiber')):
        if ps.get(key) is not None and src in s['per100g']:
            if abs(ps[key] - s['per100g'][src] * f) > 0.06 + 0.005 * abs(ps[key]):
                out.append(('calculation', f"{key}: {ps[key]} != {s['per100g'][src] * f:.2f}"))
    if 'na' in s['per100g'] and abs((ps.get('sodiumMg') or 0) - s['per100g']['na'] * f) > 0.6:
        out.append(('calculation', f"sodiumMg {ps.get('sodiumMg')} != {s['per100g']['na'] * f:.1f}"))
    if ps.get('energyKcal') is not None and 'kcal' in s['per100g']:
        if abs(ps['energyKcal'] - s['per100g']['kcal'] * f) > 0.6:
            out.append(('calculation', f"energyKcal {ps['energyKcal']} != {s['per100g']['kcal'] * f:.1f}"))
    keymap = {'Iron': 'iron', 'Folate': 'folate', 'Vitamin C': 'vitc', 'Magnesium': 'mg', 'Zinc': 'zn',
              'Potassium': 'k', 'Vitamin A': 'vita', 'Calcium': 'ca', 'Vitamin B12': 'b12',
              'Vitamin D': 'vitd', 'Vitamin E': 'vite', 'Vitamin K': 'vitk', 'Protein': 'protein',
              'Fiber': 'fiber', 'Fibre': 'fiber'}
    for kn in ps.get('keyNutrients', []):
        src = keymap.get(kn['name'])
        if src and src in s['per100g']:
            exp = s['per100g'][src] * f
            if abs(kn['amount'] - exp) > (0.51 if float(kn['amount']).is_integer() else 0.06 + abs(exp) * 0.01):
                out.append(('calculation', f"{kn['name']}: {kn['amount']} != {exp:.2f}"))
        for r in kn.get('reference', []):
            pct = kn['amount'] / r['value'] * 100
            if abs(pct - r['percent']) > 1.01 and abs(exp_pct(ps, kn, s, f, keymap, r) - r['percent']) > 1.01:
                out.append(('calculation', f"{kn['name']} percent {r['percent']} != {pct:.1f}"))
    return out


def main():
    d = json.load(open(f'{HERE}/complete-draft-dataset.json'))
    ids = {fid: p['source']['usdaFdcId'] for fid, p in d['profiles'].items()}
    with cf.ThreadPoolExecutor(6) as ex:
        raws = dict(zip(ids, ex.map(fetch, ids.values())))
    findings = {fid: audit(fid, p, raws[fid]) for fid, p in d['profiles'].items()}
    json.dump(findings, open(f'{HERE}/audit-findings.json', 'w'), indent=1, ensure_ascii=False)
    bad = {k: [x for x in v if (k, x[0]) not in REVIEWED_OK] for k, v in findings.items()}
    bad = {k: v for k, v in bad.items() if v}
    accepted = sum(1 for k, v in findings.items() for x in v if (k, x[0]) in REVIEWED_OK)
    print(f'{len(findings)} profiles audited against USDA: {len(findings) - len(bad)} clean, '
          f'{len(bad)} with open data findings ({accepted} findings reviewed and accepted)')
    for k, v in bad.items():
        for kind, msg in v:
            print(f'  {k}: [{kind}] {msg}')


main()
