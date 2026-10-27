"""Builds a DRAFT batch of Food Detail profiles from verified USDA values.

Run from the repo root: python3 docs/food-profiles/build_draft_batch.py 1
Reads docs/food-profiles/batch-<n>.src.json (hand-written: FDC record, preparation, serving
in grams, per-100 g values copied from FoodData Central, and the prose), recomputes every
serving amount and reference percentage, and writes docs/food-profiles/draft-batch-<n>.json.
Nothing here is bundled in the app and every profile is marked not publishable: approval
is an editorial decision made by the owner.
"""
import json, math, sys


def rhu(x, dec=0):
    """Round half up (Python's round() rounds halves to even; the app and its tests do not)."""
    m = 10 ** dec
    r = math.floor(x * m + 0.5) / m
    return int(r) if dec == 0 else r

# Reference intakes for adult women (NIH ODS; read 2026-10-25 and 2026-10-27).
REF = {
    'iron': ('mg', [('19–50 y', 18)], 'RDA', 'Iron'),
    'folate': ('µg DFE', [('19–50 y', 400)], 'RDA', 'Folate'),
    'vitc': ('mg', [('19–50 y', 75)], 'RDA', 'Vitamin C'),
    'vitk': ('µg', [('19–50 y', 90)], 'AI', 'Vitamin K'),
    'mg': ('mg', [('19–30 y', 310), ('31–50 y', 320)], 'RDA', 'Magnesium'),
    'zn': ('mg', [('19–50 y', 8)], 'RDA', 'Zinc'),
    'k': ('mg', [('19–50 y', 2600)], 'AI', 'Potassium'),
    'vita': ('µg RAE', [('19–50 y', 700)], 'RDA', 'Vitamin A'),
    'ca': ('mg', [('19–50 y', 1000)], 'RDA', 'Calcium'),
    'b12': ('µg', [('19+ y', 2.4)], 'RDA', 'Vitamin B12'),
    'vitd': ('µg', [('19–50 y', 15)], 'RDA', 'Vitamin D'),
    'vite': ('mg', [('19+ y', 15)], 'RDA', 'Vitamin E'),
}
# Shown as an amount only: no population reference is quoted for these.
AMOUNT_ONLY = {'protein': ('g', 'Protein'), 'fiber': ('g', 'Fiber'), 'omega3': ('g', 'Omega-3 (EPA + DHA)')}
DECIMALS = {'iron': 1, 'zn': 1, 'vite': 1, 'b12': 1, 'vitd': 1, 'protein': 1, 'fiber': 1, 'omega3': 2}
CAUTIONS = {
    'vitk': dict(text='{n} contains vitamin K. If you take warfarin or a similar blood thinner, keep your intake steady and tell your clinician.',
                 source='NIH ODS Vitamin K (interaction with warfarin and other anticoagulants)'),
    'grapefruit-meds': dict(text='Grapefruit and grapefruit juice can change the way some medicines work, including some statins and some blood pressure medicines. If your medicine label or pharmacist warns against grapefruit, avoid it.',
                            source="FDA, Grapefruit Juice and Some Drugs Don't Mix (consumer update, read 2026-10-27)"),
    'oxalate-nuts': dict(text='Nuts are high in oxalate. If you have had calcium oxalate kidney stones, ask a health professional how many to eat.',
                         source='NIDDK, Eating, Diet & Nutrition for Kidney Stones (lists nuts and nut products among foods to reduce for calcium oxalate stones)'),
}

def auto_keys(f):
    """Picks the key nutrients for one serving: up to three reference nutrients at
    10% or more (two at 5% if nothing reaches 10%), vitamin K when it is 20 µg or
    more (amount only), then protein (5 g), fibre (3 g), omega-3 (0.25 g). A
    nutrient the USDA record does not report is skipped, never treated as zero."""
    g = f['grams']
    per = f['per100']
    pct = []
    for k in ('ca', 'iron', 'mg', 'k', 'zn', 'vitc', 'folate', 'vita', 'b12', 'vitd', 'vite'):
        if per.get(k):
            pct.append((per[k] * g / 100 / REF[k][1][0][1], k))
    pct.sort(reverse=True)
    picks = [k for p, k in pct if p >= 0.10][:3]
    if len(picks) < 2:
        picks = [k for p, k in pct if p >= 0.05][:2] or picks
    keys = [(k, DECIMALS.get(k, 0)) for k in picks]
    if per.get('vitk') and per['vitk'] * g / 100 >= 20:
        keys.append(('vitk', 0))
    for k, minimum in (('protein', 5), ('fiber', 3), ('omega3', 0.25)):
        if per.get(k) and per[k] * g / 100 >= minimum:
            keys.append((k, DECIMALS[k]))
    if not keys:
        # A food with little to report: its two best reference nutrients (any
        # amount), plus fibre if there is a gram or more.
        keys = [(k, DECIMALS.get(k, 0)) for p, k in pct if p > 0][:2]
        if per.get('fiber') and per['fiber'] * g / 100 >= 1:
            keys.append(('fiber', DECIMALS['fiber']))
    return keys[:5]


n = sys.argv[1]
src = json.load(open(f'docs/food-profiles/batch-{n}.src.json'))
out = {'_status': 'DRAFT BATCH for editorial review. Not production content. Nothing here is bundled in the app.',
       '_sources': src['_sources'], '_reviewLabel': 'Nutrition values checked against USDA and NIH sources; not clinically reviewed.',
       'profiles': {}}
for fid, f in src['foods'].items():
    amt = lambda k: f['per100'][k] * f['grams'] / 100
    if f['keys'] == 'auto':
        f['keys'] = auto_keys(f)
    keys = []
    for key, dec in f['keys']:
        assert key in f['per100'], (fid, key)
        v = amt(key)
        if key in AMOUNT_ONLY:
            unit, nm = AMOUNT_ONLY[key]
            keys.append({'name': nm, 'amount': rhu(v, dec), 'unit': unit})
            continue
        unit, groups, kind, nm = REF[key]
        e = {'name': nm, 'amount': rhu(v, dec), 'unit': unit}
        if key != 'vitk':
            e['reference'] = [{'group': g, 'kind': kind, 'value': val, 'unit': unit, 'percent': rhu(100 * v / val)} for g, val in groups]
        else:
            e['referenceNote'] = 'Adequate intake for women 19 and over is 90 µg; shown as an amount only. See the note on blood thinners.'
        keys.append(e)
    assert all(f.get(x, '').strip() for x in ('offers', 'how', 'cycle')), f"{fid}: prose missing"
    names = list(f.get('cautions', []))
    # Vitamin K at 100 µg or more per 100 g carries the blood-thinner note.
    if f['per100'].get('vitk', 0) >= 100 and 'vitk' not in names:
        names.append('vitk')
    f['cautions'] = names
    cautions = [dict(text=CAUTIONS[c]['text'].format(n=f['name']), source=CAUTIONS[c]['source']) for c in f.get('cautions', [])]
    out['profiles'][fid] = {
        'catalogueId': fid, 'name': f['name'],
        'sections': {'whatItOffers': f['offers'], 'practicalServing': f['portion'], 'howToEatIt': f['how'], 'cycleRelevance': f['cycle']},
        'source': {'usdaFdcId': f['fdc'], 'usdaDescription': f['desc'], 'dataType': f['type'], 'published': f['published'],
                   'preparationState': f['state'], 'portionGrams': f['grams'], 'portion': f['portion'], 'per100g': f['per100']},
        'perServing': {'energyKcal': rhu(amt('kcal')), 'proteinG': rhu(amt('protein'), 1), 'fatG': rhu(amt('fat'), 1),
                       'carbohydrateG': rhu(amt('carb'), 1), 'fiberG': rhu(amt('fiber'), 1) if 'fiber' in f['per100'] else None,
                       'keyNutrients': keys},
        'cautions': cautions, 'evidence': f['evidence'],
        'review': {'composition': 'copied from USDA FoodData Central; recomputed by script', 'referenceIntakes': 'NIH ODS values',
                   'cautions': 'verified against the cited page' if cautions else 'none recorded',
                   'editorial': 'draft; awaiting editorial review', 'clinical': 'not clinically reviewed', 'publishable': False},
    }
json.dump(out, open(f'docs/food-profiles/draft-batch-{n}.json', 'w'), indent=2, ensure_ascii=False)
print(len(out['profiles']), 'draft profiles written')
