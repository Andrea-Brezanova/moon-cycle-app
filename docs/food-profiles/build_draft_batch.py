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
FDA_RISK = 'FDA, People at Risk of Foodborne Illness (Foods to Avoid; content current as of 01/16/2025; read 2026-10-28)'
FSIS = 'USDA FSIS, Safe Minimum Internal Temperature Chart (read 2026-10-27)'
CAUTIONS = {
    'vitk': dict(text='{n} contains vitamin K. If you take warfarin or a similar blood thinner, keep your intake steady and tell your clinician.',
                 source='NIH ODS Vitamin K (interaction with warfarin and other anticoagulants)'),
    'grapefruit-meds': dict(text='Grapefruit and grapefruit juice can change the way some medicines work, including some statins and some blood pressure medicines. If your medicine label or pharmacist warns against grapefruit, avoid it.',
                            source="FDA, Grapefruit Juice and Some Drugs Don't Mix (consumer update, read 2026-10-27)"),
    'mercury-good': dict(text='Mercury: the FDA and EPA list {n} as a "Good Choice", with more mercury than their "Best Choices". For people who are or might become pregnant, or who are breastfeeding, the advice is 2 to 3 servings a week from the Best Choices or 1 serving from the Good Choices.',
                         source='FDA and EPA, Advice about Eating Fish (lists read 2026-10-27; content current as of 03/05/2024)'),
    'mackerel-king': dict(text='This profile is Atlantic mackerel, a "Best Choice" for mercury. King mackerel is a different fish with the highest mercury levels, and the FDA and EPA advise avoiding it.',
                          source='FDA and EPA, Advice about Eating Fish (lists read 2026-10-27; content current as of 03/05/2024)'),
    'temp-fish': dict(text='Cook fish and shellfish to an internal temperature of 145 °F (62.8 °C).', source=FSIS),
    'temp-poultry': dict(text='Cook poultry to an internal temperature of 165 °F (73.9 °C).', source=FSIS),
    'temp-meat': dict(text='Cook steaks, chops and roasts to 145 °F (62.8 °C) and let them rest for at least 3 minutes; cook ground meat to 160 °F (71.1 °C).', source=FSIS),
    'temp-eggs': dict(text='Cook eggs to 160 °F (71.1 °C).', source=FSIS),
    'oxalate-list': dict(text='{n} is high in oxalate. If you have had calcium oxalate kidney stones, ask a health professional how much to eat.',
                         source='NIDDK, Eating, Diet & Nutrition for Kidney Stones (lists rhubarb among foods to reduce for calcium oxalate stones)'),
    'sprouts': dict(text="Raw sprouts (alfalfa, bean or any other sprout) are on the FDA's list of foods to avoid if you are at greater risk of foodborne illness, for example during pregnancy, in older age or with a weakened immune system.",
                    source=FDA_RISK),
    'smoked-fish': dict(text="Smoked fish is on the FDA's list of foods to avoid if you are at greater risk of foodborne illness (for example during pregnancy), unless it is reheated until steaming hot.",
                        source=FDA_RISK),
    'deli-meat': dict(text="Sliced deli-style meats such as ham are on the FDA's list of foods to avoid if you are at greater risk of foodborne illness (for example during pregnancy), unless they are reheated until steaming hot.",
                      source=FDA_RISK),
    'pasteurised-cheese': dict(text="The FDA advises people at greater risk of foodborne illness (for example during pregnancy) to avoid cheese made from unpasteurised milk, and queso fresco-type cheeses even when pasteurised. Check the label for pasteurised milk.",
                               source=FDA_RISK),
    'honey-infant': dict(text='Do not give honey to a child younger than 1 year old: it can contain the bacteria that cause infant botulism.',
                         source='CDC, Botulism Prevention (read 2026-10-28)'),
    'fava-g6pd': dict(text='People with glucose-6-phosphate dehydrogenase (G6PD) deficiency can develop hemolytic anemia (favism) after eating fava beans. If you have G6PD deficiency, ask a health professional before eating them.',
                      source='NIH MedlinePlus Genetics, Glucose-6-phosphate dehydrogenase deficiency (last updated 12 April 2023; read 2026-10-28)'),
    'iodine-ods': dict(text='Seaweed such as kelp and wakame is one of the best food sources of iodine, and the tolerable upper intake level for adults is 1,100 µg of iodine a day.',
                       source='NIH ODS, Iodine fact sheet for health professionals (read 2026-10-28)'),
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
        keys = [(k, DECIMALS.get(k, 0)) for p, k in pct if p >= 0.01][:2]
        if per.get('fiber') and per['fiber'] * g / 100 >= 1:
            keys.append(('fiber', DECIMALS['fiber']))
    return keys[:5]


CATALOGUE = {f['id']: f for f in json.load(open('assets/content/foods.json'))['foods']}
EXISTING = 'Existing MoonCycle catalogue caution (no external source recorded)'
ALLERGEN_SOURCE = 'MoonCycle catalogue allergen tag (assets/content/foods.json; no external source recorded)'
# A sourced caution is skipped when the catalogue already carries one on the same topic.
SODIUM_SOURCE = 'FDA, Sodium in Your Diet (the Dietary Guidelines for Americans advise adults to limit sodium to less than 2,300 mg a day; content current as of 03/05/2024; read 2026-10-28)'
SODIUM_LIMIT_MG = 2300
# A serving at or above 15% of the daily limit is called out.
SODIUM_NOTE_MG = 345
# Allergen tags in the catalogue (assets/content/foods.json) and the wording that already covers each.
ALLERGENS = {
    'tree-nut': ('Tree-nut allergen', ['tree-nut', 'tree nut']), 'peanut': ('Peanut allergen', ['peanut']),
    'fish': ('Fish allergen', ['fish allergen']), 'shellfish': ('Shellfish allergen', ['crustacean', 'mollusc', 'shellfish']),
    'gluten': ('Contains gluten', ['gluten', 'wheat']), 'dairy': ('Dairy allergen', ['dairy']),
    'soy': ('Soy allergen', ['soy']), 'egg': ('Egg allergen', ['egg allergen']), 'sesame': ('Sesame allergen', ['sesame']),
}
TOPICS = {'vitk': 'vitamin k', 'oxalate-nuts': 'oxalate', 'oxalate-list': 'oxalate', 'grapefruit-meds': 'medicine', 'mercury-good': 'mercury',
          'temp-fish': 'cook', 'temp-poultry': 'cook', 'temp-meat': 'cook', 'temp-eggs': 'cook'}

def short_portion(portion):
    return portion.split(' (USDA')[0]


STATE_WORDS = ('raw', 'cooked', 'dried', 'dry', 'canned', 'roasted', 'baked', 'boiled', 'steamed', 'frozen',
               'smoked', 'pickled', 'fermented', 'sprouted')


def lead(f):
    """The food's name, with its preparation (cooked, raw, dried...) in brackets when the name doesn't say it."""
    low = f['name'].lower()
    for part in f['state'].split(','):
        for w in part.split():
            if w in STATE_WORDS and w not in low:
                return f"{f['name']} ({w})"
    return f['name']


def offers_text(f, keys, kcal):
    """Plain sentence built only from the recomputed numbers (no claims)."""
    bits = []
    for e in keys:
        name = 'fibre' if e['name'] == 'Fiber' else e['name'][0].lower() + e['name'][1:]
        if e.get('reference'):
            bits.append(f"{name} (about {e['reference'][0]['percent']}%)")
        elif e['name'] == 'Vitamin K':
            bits.append(f"{e['amount']} µg of vitamin K")
        else:
            bits.append(f"{e['amount']} {e['unit']} of {name}")
    base = f"{lead(f)}: {short_portion(f['portion'])} gives about {kcal} {'calorie' if kcal == 1 else 'calories'}"
    if not bits:
        return base + ' and supplies little of the vitamins and minerals tracked here.'
    pct = ' Percentages are of the NIH reference intake for adult women.' if any(e.get('reference') for e in keys) else ''
    return base + ', with ' + ', '.join(bits[:-1]) + (' and ' if len(bits) > 1 else '') + bits[-1] + '.' + pct


def cycle_text(f, keys):
    low = f['name'].lower()
    out = f"No cycle-phase claim is made for {low}."
    for e in keys:
        # Only when the serving supplies a meaningful share (10% or more) of the reference.
        if not e.get('reference') or e['reference'][0]['percent'] < 10:
            continue
        if e['name'] == 'Iron':
            out += f" Iron needs are higher for women aged 19 to 50 (18 mg a day, against 8 mg for men), partly because of menstrual blood loss (NIH ODS); this serving has about {e['amount']} mg."
        if e['name'] == 'Calcium':
            out += f" Calcium needs are 1,000 mg a day for women aged 19 to 50 (NIH ODS); this serving has about {e['amount']} mg."
    return out


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
    if f['offers'] == 'TBD':
        f['offers'] = offers_text(f, keys, rhu(amt('kcal')))
    if f['cycle'] == 'TBD':
        f['cycle'] = cycle_text(f, keys)
    assert all(f.get(x, '').strip() and f[x] != 'TBD' for x in ('offers', 'how', 'cycle')), f"{fid}: prose missing"
    names = list(f.get('cautions', []))
    # Vitamin K at 100 µg or more per 100 g carries the blood-thinner note.
    if f['per100'].get('vitk', 0) >= 100 and 'vitk' not in names:
        names.append('vitk')
    f['cautions'] = names
    # The app shows a profile's cautions INSTEAD of the catalogue's, so every
    # existing catalogue caution is carried over first, then the sourced ones
    # (unless the catalogue already covers that topic).
    existing = CATALOGUE[fid].get('cautions', [])
    cautions = [dict(text=t, source=EXISTING) for t in existing]
    for c in names:
        same = [x for x in cautions if TOPICS.get(c, c) in x['text'].lower()]
        if same:
            # Keep the existing wording; record the source that backs it.
            same[0]['source'] = CAUTIONS[c]['source'] + ' (supports the existing caution)'
            continue
        cautions.append(dict(text=CAUTIONS[c]['text'].format(n=f['name']), source=CAUTIONS[c]['source']))
    assert all(f.get(x, '').strip() for x in ('offers', 'how', 'cycle')), f"{fid}: prose missing"
    # Sodium: called out at 15% of the 2,300 mg daily limit or more (a catalogue "salt" caution is kept and sourced instead).
    sodium = rhu(amt('na')) if 'na' in f['per100'] else None
    if sodium is not None and sodium >= SODIUM_NOTE_MG:
        text = f"About {sodium:,} mg of sodium in this serving. The Dietary Guidelines for Americans advise adults to limit sodium to less than {SODIUM_LIMIT_MG:,} mg a day."
        same = [x for x in cautions if 'salt' in x['text'].lower() or 'sodium' in x['text'].lower()]
        if same:
            same[0]['source'] = SODIUM_SOURCE + ' (supports the existing caution)'
            same[0]['text'] = same[0]['text'].rstrip('.') + '. ' + text
        else:
            cautions.append(dict(text=text, source=SODIUM_SOURCE))
    # Allergen tags from the catalogue must be visible in the caution list too.
    allergens = list(CATALOGUE[fid].get('allergens', []))
    for a in allergens:
        label, words = ALLERGENS[a]
        if not any(w in ' '.join(x['text'].lower() for x in cautions) for w in words):
            cautions.append(dict(text=label, source=ALLERGEN_SOURCE))
    out['profiles'][fid] = {
        'catalogueId': fid, 'name': f['name'],
        'sections': {'whatItOffers': f['offers'], 'practicalServing': f['portion'], 'howToEatIt': f['how'], 'cycleRelevance': f['cycle']},
        'source': {'usdaFdcId': f['fdc'], 'usdaDescription': f['desc'], 'dataType': f['type'], 'published': f['published'],
                   'preparationState': f['state'], 'portionGrams': f['grams'], 'portion': f['portion'], 'per100g': f['per100']},
        'perServing': {'energyKcal': rhu(amt('kcal')), 'proteinG': rhu(amt('protein'), 1), 'fatG': rhu(amt('fat'), 1),
                       'carbohydrateG': rhu(amt('carb'), 1), 'fiberG': rhu(amt('fiber'), 1) if 'fiber' in f['per100'] else None,
                       'sodiumMg': sodium,
                       'keyNutrients': keys},
        'allergens': allergens, 'mayContainAllergens': list(CATALOGUE[fid].get('mayContainAllergens', [])),
        'cautions': cautions, 'evidence': f['evidence'],
        'review': {'composition': 'copied from USDA FoodData Central; recomputed by script', 'referenceIntakes': 'NIH ODS values',
                   'cautions': 'verified against the cited page' if cautions else 'none recorded',
                   'editorial': 'draft; awaiting editorial review', 'clinical': 'not clinically reviewed', 'publishable': False},
    }
json.dump(out, open(f'docs/food-profiles/draft-batch-{n}.json', 'w'), indent=2, ensure_ascii=False)
print(len(out['profiles']), 'draft profiles written')
