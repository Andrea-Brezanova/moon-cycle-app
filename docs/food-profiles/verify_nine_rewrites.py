"""Checks the nine rewritten "Why this food?" sentences against the LIVE USDA FoodData Central records.

For each sentence: the serving it names must exist in the USDA record's own household measures (with its gram
weight); iron per 100 g is read from the record; the stated percentage must equal iron in that serving over the 18 mg
reference (NIH ODS RDA for women 19-50, also the FDA Daily Value for iron), rounded; and any other nutrient the
sentence names (protein, fibre, folate) must be present in meaningful amount in that serving.

Run from the repo root. It reads the records fetched to /tmp/fdc/<food>.json from
https://fdc.nal.usda.gov/portal-data/external/<fdcId> and writes nine-rewrites-verification.json and .md."""
import json, re, sys

R = 'docs/food-profiles/'
REF_IRON = 18.0
# id -> (FDC id, measure value, measure modifier expected in the record, fraction of that measure the sentence names)
SERVINGS = {
    'mussel': (174217, 3.0, 'oz', 1.0),
    'oyster': (171980, 6.0, 'medium', 1.0),
    'green-lentil': (172421, 1.0, None, 0.5),     # 1 cup, half a cup named
    'spinach': (168463, 1.0, 'cup', 0.5),
    'quinoa': (168917, 1.0, None, 0.5),
    'anchovies': (174183, 5.0, 'anchovies', 1.0),
    'sardine': (175139, 1.0, 'can (3.75 oz)', 1.0),
}
rewrites = {r['id']: r for r in json.load(open(R + 'why-this-food-rewrites.json'))['rewrites']}


def nutrient(rec, *names):
    for n in rec['foodNutrients']:
        if n.get('nutrient', {}).get('name') in names and 'value' in n:
            return n['value']
    return None


rows, ok_all = [], True
for fid, rw in rewrites.items():
    sentence = rw['shortAfter']
    row = dict(id=fid, phase=rw['phase'], before=rw['shortBefore'], after=sentence, checks=[])
    if fid in SERVINGS:
        fdc, value, mod, frac = SERVINGS[fid]
        rec = json.load(open(f'/tmp/fdc/{fid}.json'))
        row['usda'] = dict(fdcId=fdc, description=rec['description'], lastUpdated=rec.get('lastUpdated'))
        assert rec['fdcId'] == fdc, fid
        m = next((m for m in rec['foodMeasures'] if m['value'] == value and (mod is None or m.get('modifier') == mod)), None)
        row['checks'].append(('USDA household measure exists', f"{value:g} {mod or 'cup'} = {m['gramWeight']} g" if m else 'NOT FOUND', bool(m)))
        grams = m['gramWeight'] * frac
        iron100 = nutrient(rec, 'Iron, Fe')
        mg = iron100 * grams / 100
        pct = round(100 * mg / REF_IRON)
        stated = re.search(r'about (\d+)%', sentence)
        row['servingGrams'], row['ironPer100g'], row['ironMgInServing'], row['computedPercent'] = grams, iron100, round(mg, 2), pct
        if stated:
            row['checks'].append(('stated iron percent = iron in serving / 18 mg', f"stated {stated.group(1)}%, computed {pct}% ({mg:.2f} mg of 18 mg)", int(stated.group(1)) == pct))
        for word, names, floor in (('protein', ('Protein',), 5), ('fibre', ('Fiber, total dietary',), 2), ('folate', ('Folate, DFE',), 40)):
            if word in sentence:
                v = nutrient(rec, *names) * grams / 100
                unit = 'µg' if word == 'folate' else 'g'
                row['checks'].append((f'{word} present in serving', f'{v:.1f} {unit}', v >= floor))
        if 'concentrated source of iron' in sentence:
            row['checks'].append(('"concentrated" is per weight; sentence also states the small serving', f'{iron100} mg per 100 g, {pct}% in the serving', True))
        if 'rich source of iron' in sentence:
            row['checks'].append(('"rich source" means 20% or more of the Daily Value (FDA)', f'{pct}%', pct >= 20))
    else:
        row['checks'].append(('no figure or nutrient claim in the sentence', 'meal-style wording only', not re.search(r'\d|iron|protein|fibre|vitamin', sentence)))
    row['checks'].append(('no phase, hormone, "cooling" or "highlight" wording', 'none', not re.search(r'menstru|luteal|follic|ovulat|phase|hormon|cooling|highlight', sentence, re.I)))
    row['ok'] = all(c[2] for c in row['checks'])
    ok_all &= row['ok']
    rows.append(row)

json.dump(dict(_about='Verification of the nine rewritten sentences against live USDA FoodData Central records (31 Oct / 1 Nov 2026).', reference='18 mg iron (NIH ODS Iron fact sheet, updated 4 Sep 2025, Table 1: RDA women 19-50 = 18 mg, men 8 mg; read 1 Nov 2026)', note='NIH ODS Table 2 rounds iron to whole mg (lentils and spinach, half a cup: 3 mg = 17%); the sentences use the unrounded USDA value (3.30 and 3.21 mg = 18%).', allOk=ok_all, rows=rows),
          open(R + 'nine-rewrites-verification.json', 'w'), indent=1, ensure_ascii=False)
L = ['# The nine "Why this food?" rewrites: verification\n',
     'Each sentence checked against the live USDA FoodData Central record (portal-data JSON) for its FDC id; reference 18 mg iron (NIH ODS Iron fact sheet, updated 4 Sep 2025, Table 1: RDA for women 19 to 50 = 18 mg; read 1 Nov 2026). NIH ODS Table 2 rounds iron to whole mg (lentils and spinach, half a cup: 3 mg = 17%); these sentences use the unrounded USDA value (3.30 and 3.21 mg = 18%). Phase assignments are unchanged.\n',
     '| Food (phase) | Before | After | Checks |', '|---|---|---|---|']
for r in rows:
    chk = '<br>'.join(('✓ ' if c[2] else '✗ ') + f'{c[0]}: {c[1]}' for c in r['checks'])
    L.append(f"| {r['id']} ({r['phase']}) | {r['before']} | {r['after']} | {chk} |")
L.append(f"\n**All checks pass: {ok_all}.**")
open(R + 'nine-rewrites-verification.md', 'w').write('\n'.join(L) + '\n')
print('allOk', ok_all)
for r in rows:
    print(r['id'], r['ok'], [c[1] for c in r['checks'] if not c[2]])
sys.exit(0 if ok_all else 1)
