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
ARSENIC = 'FDA, What You Can Do to Limit Exposure to Arsenic (content current as of 04/27/2022; read 2026-10-28)'
BAD_BUG = 'FDA, Bad Bug Book, 2nd edition: Phytohaemagglutinin (kidney bean lectin) (read 2026-10-29)'
NATURAL_TOXINS = 'FDA, Natural Toxins in Food (content current as of 09/26/2024; read 2026-10-28)'
FDA_ALLERGENS = 'FDA, Food Allergies (the nine major food allergens; content current as of 03/11/2026; read 2026-10-28)'
NIDDK_CELIAC = 'NIDDK, Celiac Disease: Eating, Diet & Nutrition (last reviewed October 2020; read 2026-10-28)'
ODS_IODINE = 'NIH ODS, Iodine fact sheet for health professionals (updated 5 November 2024; read 2026-10-28)'
ODS_SELENIUM = 'NIH ODS, Selenium fact sheet for health professionals (updated 4 September 2025; read 2026-10-28)'
FDA_FISH = 'FDA and EPA, Advice about Eating Fish (lists read 2026-10-27; content current as of 03/05/2024)'
FDA_PRODUCE = 'FDA, Selecting and Serving Produce Safely (content current as of 03/05/2024; read 2026-10-28)'
MEDLINE_RHUBARB = 'NIH MedlinePlus, Rhubarb poisoning (review date 10/14/2025; read 2026-10-28)'
FDA_LABEL = 'FDA, How to Understand and Use the Nutrition Facts Label (5% DV or less is low, 20% DV or more is high; content current as of 03/05/2024; read 2026-10-28)'
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
    'rice-arsenic': dict(text='Rice tends to absorb more arsenic than other crops. The FDA says people can still eat rice as part of a well-balanced diet.',
                         source=ARSENIC),
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
# Inherited catalogue cautions whose wording an authoritative page read this session supports.
# 'sourced' = the page supports the caution; 'partly-sourced' = it supports the topic but not every detail.
VERIFIED = {
    'Tree-nut allergen': (FDA_ALLERGENS, 'sourced'), 'Fish allergen': (FDA_ALLERGENS, 'sourced'),
    'Soy allergen': (FDA_ALLERGENS, 'sourced'), 'Dairy allergen': (FDA_ALLERGENS, 'sourced'),
    'Egg allergen': (FDA_ALLERGENS, 'sourced'), 'Sesame allergen': (FDA_ALLERGENS, 'sourced'),
    'Crustacean allergen': (FDA_ALLERGENS, 'sourced'),
    'Tree-nut or peanut allergen, depending on type': (FDA_ALLERGENS, 'sourced'),
    'Contains gluten': (NIDDK_CELIAC, 'sourced'), 'Contains wheat (gluten)': (NIDDK_CELIAC, 'sourced'),
    'Choose certified gluten-free oats if avoiding gluten.': (NIDDK_CELIAC, 'sourced'),
    'High in salt': (FDA_LABEL, 'partly-sourced'),
    'Mercury: prefer light/skipjack': (FDA_FISH, 'sourced'),
    'Vary grains (arsenic in rice)': (ARSENIC, 'partly-sourced'),
    'Wash the rind before cutting': (FDA_PRODUCE, 'sourced'),
    'Leaves are poisonous: stalks only': (MEDLINE_RHUBARB, 'sourced'),
    'Limit to 1–2 nuts a day': (ODS_SELENIUM, 'partly-sourced'),
    'Can exceed the safe iodine limit': (ODS_IODINE, 'sourced'),
    'Thyroid conditions: check with a doctor': (ODS_IODINE, 'sourced'),
    'Iodine: normal portions': (ODS_IODINE, 'partly-sourced'),
    'Raw sprouts: food-safety risk': (FDA_RISK, 'sourced'),
    'Dried kidney beans contain a natural toxin that raw or undercooked beans can release. Soak them for at least 5 hours, pour the water away, then boil in fresh water for at least 30 minutes.': (NATURAL_TOXINS + '; ' + BAD_BUG, 'sourced'),
    'Do not cook dried kidney beans in a slow cooker: it may not get hot enough to destroy the toxin.': (BAD_BUG, 'sourced'),
    'Canned kidney beans are already cooked and contain only low levels of the toxin.': (NATURAL_TOXINS, 'sourced'),
    'Raw oysters: food-safety risk': (FDA_RISK, 'partly-sourced'),
}
AUDIT_NOTES = json.load(open('docs/food-profiles/audit-notes.json'))
SODIUM_HIGH_MG = 460   # 20% of the 2,300 mg Daily Value: the FDA's "high" line
TOPICS = {'vitk': 'vitamin k', 'oxalate-nuts': 'oxalate', 'oxalate-list': 'oxalate', 'grapefruit-meds': 'medicine', 'mercury-good': 'mercury',
          'temp-fish': 'cook', 'temp-poultry': 'cook', 'temp-meat': 'cook', 'temp-eggs': 'cook'}

def short_portion(portion):
    return portion.split(' (USDA')[0]


STATE_WORDS = ('raw', 'cooked', 'dried', 'dry', 'canned', 'roasted', 'baked', 'boiled', 'steamed', 'frozen',
               'smoked', 'pickled', 'fermented', 'sprouted')


def lead(f):
    """The food's name, with its preparation (cooked, raw, dried...) in brackets when the name doesn't say it."""
    if f.get('lead'):
        return f['lead']
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
        # Key nutrients the audit left out because the USDA value looks unreliable for this food.
        f['keys'] = [k for k in f['keys'] if k[0] not in f.get('dropKeys', [])]
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
    cautions = []
    for t in existing:
        if t in VERIFIED:
            cautions.append(dict(text=t, source=VERIFIED[t][0] + ' (supports the existing caution)', status=VERIFIED[t][1]))
        else:
            cautions.append(dict(text=t, source=EXISTING, status='unverified-inherited'))
    for c in names:
        same = [x for x in cautions if TOPICS.get(c, c) in x['text'].lower()]
        if same:
            # Keep the existing wording; record the source that backs it.
            same[0]['source'] = CAUTIONS[c]['source'] + ' (supports the existing caution)'
            same[0]['status'] = 'sourced'
            continue
        cautions.append(dict(text=CAUTIONS[c]['text'].format(n=f['name']), source=CAUTIONS[c]['source'], status='sourced'))
    assert all(f.get(x, '').strip() for x in ('offers', 'how', 'cycle')), f"{fid}: prose missing"
    # Sodium is always recorded as data. It becomes a plain nutrition note (not a caution) only at the
    # FDA's "high" line of 20% of the Daily Value, and is worded calmly.
    sodium = rhu(amt('na')) if 'na' in f['per100'] else None
    notes = []
    if sodium is not None and sodium >= SODIUM_HIGH_MG:
        notes.append(dict(text=f"This serving has about {sodium:,} mg of sodium, {rhu(100 * sodium / SODIUM_LIMIT_MG)}% of the {SODIUM_LIMIT_MG:,} mg Daily Value. The FDA treats 20% or more of the Daily Value as high.",
                          source=FDA_LABEL))
    # Allergen tags from the catalogue must be visible in the caution list too.
    allergens = list(CATALOGUE[fid].get('allergens', []))
    for a in allergens:
        label, words = ALLERGENS[a]
        if not any(w in ' '.join(x['text'].lower() for x in cautions) for w in words):
            cautions.append(dict(text=label, source=ALLERGEN_SOURCE, status='catalogue-tag'))
    unverified = sum(1 for c in cautions if c['status'] == 'unverified-inherited')
    record_notes = [dict(kind=k, text=AUDIT_NOTES[k][fid]) for k in ('identity', 'servingState', 'resolved', 'unusualValues') if fid in AUDIT_NOTES.get(k, {})]
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
        'cautions': cautions, 'nutritionNotes': notes, 'recordNotes': record_notes, 'evidence': f['evidence'],
        'review': {'composition': 'copied from USDA FoodData Central; recomputed by script', 'referenceIntakes': 'NIH ODS values',
                   'cautions': ('none recorded' if not cautions else 'all cautions sourced or catalogue tags' if not unverified else f'{unverified} inherited caution(s) without a verified source'),
                   'editorial': 'draft; awaiting editorial review', 'clinical': 'not clinically reviewed', 'publishable': False},
    }
json.dump(out, open(f'docs/food-profiles/draft-batch-{n}.json', 'w'), indent=2, ensure_ascii=False)
print(len(out['profiles']), 'draft profiles written')
