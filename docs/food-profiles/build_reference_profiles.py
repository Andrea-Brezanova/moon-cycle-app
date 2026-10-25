"""Builds reference-profiles.json from the verified USDA and NIH ODS values below.

Run from the repo root: python3 docs/food-profiles/build_reference_profiles.py
It writes the review copy (docs/food-profiles/reference-profiles.json, not publishable)
and the app bundle (assets/content/food_profiles.json, the five reviewed profiles).
Every number is either copied from the USDA FoodData Central record named in the
entry (per 100 g, read on fdc.nal.usda.gov on 2026-10-25) or computed from it for
the stated portion. Reference intakes are NIH ODS values (same date).
"""
import json

# Reference intakes (NIH ODS). Each nutrient lists the age groups of adult women
# it applies to; magnesium differs between 19-30 and 31-50, so both are shown.
REF = {
    'iron': ('mg', [('19–50 y', 18)], 'RDA', 'Iron'),
    'folate': ('µg DFE', [('19–50 y', 400)], 'RDA', 'Folate'),
    'vitc': ('mg', [('19–50 y', 75)], 'RDA', 'Vitamin C'),
    'vitk': ('µg', [('19–50 y', 90)], 'AI', 'Vitamin K'),
    'mg': ('mg', [('19–30 y', 310), ('31–50 y', 320)], 'RDA', 'Magnesium'),
    'zn': ('mg', [('19–50 y', 8)], 'RDA', 'Zinc'),
    'k': ('mg', [('19–50 y', 2600)], 'AI', 'Potassium'),
    'vita': ('µg RAE', [('19–50 y', 700)], 'RDA', 'Vitamin A'),
}

# Records. kcal is "Energy" for SR Legacy and "Energy (Atwater Specific Factors)"
# for Foundation. Each entry is ONE preparation state: nothing raw and cooked mixed.
FOODS = {
    'spinach': dict(
        name='Spinach', fdc=168463, type='SR Legacy', published='4/1/2019',
        desc='Spinach, cooked, boiled, drained, without salt', state='cooked, boiled, drained, no salt',
        grams=90, portion='½ cup cooked (USDA: 1 cup = 180 g)',
        per100=dict(kcal=23, protein=2.97, fat=0.26, carb=3.75, fiber=2.4, iron=3.57, folate=146, vitk=494, mg=87, k=466, vita=524),
        why_record='USDA has no cooked-spinach Foundation record (only raw baby and mature); the SR Legacy cooked record is the current cooked one and matches the way spinach is usually eaten and the existing catalogue wording.',
        keys=[('iron', 1), ('folate', 0), ('mg', 0), ('vita', 0), ('vitk', 0)],
        offers='Spinach is a leafy green that cooks down to a small, soft portion with folate, magnesium and vitamin A, and some plant iron.',
        how='Wilt it into soups, stews, omelettes or pasta, or stir it through warm lentils. Squeeze lemon over it or add a piece of orange to the meal: vitamin C helps your body absorb the iron.',
        cycle='Iron needs are higher for women aged 19 to 50 (18 mg a day, against 8 mg for men), partly because menstrual blood loss increases iron losses (NIH ODS). Spinach adds plant iron, which is absorbed less readily than iron from meat; vitamin C eaten with it helps. If your periods are heavy, it is worth talking to a health professional.',
        evidence='Iron requirement, menstrual loss and absorption: NIH ODS Iron. No spinach-specific cycle trial was used.',
        cautions=[
            dict(text='Spinach is high in oxalate. If you have had calcium oxalate kidney stones, ask a health professional how much to eat.', source='NIDDK, Eating, Diet & Nutrition for Kidney Stones (lists spinach among foods to avoid after calcium oxalate stones)'),
            dict(text='Spinach is high in vitamin K. If you take warfarin or a similar blood thinner, keep your intake steady and tell your clinician.', source='NIH ODS Vitamin K (interaction with warfarin and other anticoagulants)'),
        ]),
    'green-lentil': dict(
        name='Lentils', fdc=172421, type='SR Legacy', published='4/1/2019',
        desc='Lentils, mature seeds, cooked, boiled, without salt', state='cooked, boiled, no salt',
        grams=99, portion='½ cup cooked (USDA: 1 cup = 198 g)',
        per100=dict(kcal=116, protein=9.02, fat=0.38, carb=20.1, fiber=7.9, iron=3.33, folate=181, vitk=1.7, mg=36, k=369, vita=0, zn=1.27),
        why_record='USDA has only a dry lentil Foundation record; the SR Legacy cooked record is the cooked one, and it has household measures.',
        keys=[('iron', 1), ('folate', 0), ('zn', 1), ('k', 0)],
        offers='Lentils are a filling, budget-friendly pulse with protein, fibre, folate and iron in one bowl.',
        how='Simmer into soups and dals, cool for salads, or fold into grain bowls. Serve with something rich in vitamin C, such as peppers, tomatoes or citrus: beans contain phytate, which makes minerals harder to absorb, and vitamin C works the other way.',
        cycle='Like spinach, lentils add plant iron (see Spinach for why iron matters to people who menstruate), and they are also a source of folate, a nutrient some women of childbearing age do not get enough of (NIH ODS).',
        evidence='Iron absorption and folate intake statements: NIH ODS Iron and Folate. No lentil-specific cycle trial was used.',
        cautions=[]),
    'pumpkin-seeds': dict(
        name='Pumpkin seeds', fdc=170556, type='SR Legacy', published='4/1/2019',
        desc='Seeds, pumpkin and squash seed kernels, dried', state='dried edible kernels (hulled), unsalted',
        grams=28.35, portion='1 ounce (28 g) of kernels (USDA: 1 cup = 129 g)',
        per100=dict(kcal=559, protein=30.2, fat=49, carb=10.7, fiber=6, iron=8.82, mg=592, zn=7.81, k=809),
        why_record='The USDA record for the edible seed kernel (the hulled pepita), with an ounce household measure. The Foundation raw-pepitas record gives only a 30 g reference amount, so this record is the clearer match for the serving shown.',
        keys=[('mg', 0), ('zn', 1), ('iron', 1)],
        offers='Pumpkin seeds (pepitas) are a crunchy, energy-dense source of magnesium, zinc, iron and plant protein.',
        how='Scatter over porridge, yoghurt, soups or salads, or blend into a dressing or pesto. A little goes a long way: they are rich in fat and energy.',
        cycle='We found no reliable evidence linking pumpkin seeds to a cycle phase or to period symptoms. They are here as one source of magnesium and zinc, as part of a varied diet.',
        evidence='Nutrient amounts and reference intakes only. No cycle-specific claim is made.',
        cautions=[]),
    'broccoli': dict(
        name='Broccoli', fdc=169967, type='SR Legacy', published='4/1/2019',
        desc='Broccoli, cooked, boiled, drained, without salt', state='cooked, boiled, drained, no salt',
        grams=78, portion='½ cup chopped, cooked (78 g)',
        per100=dict(kcal=35, protein=2.38, fat=0.41, carb=7.18, fiber=3.3, iron=0.67, folate=108, vitk=141, mg=21, k=293, vita=77, vitc=64.9, zn=0.45),
        why_record='The cooked record, as broccoli is usually eaten and as NIH ODS lists it (cooked, ½ cup). USDA has no cooked-broccoli Foundation record. The raw Foundation record (747447) is not mixed in: all amounts here are cooked.',
        keys=[('vitc', 0), ('vitk', 0), ('folate', 0), ('k', 0)],
        offers='Broccoli is a green vegetable with plenty of vitamin C and vitamin K, plus folate and fibre.',
        how='Steam, roast or stir-fry it until just tender. Serve it with beans, lentils or other plant iron foods: its vitamin C helps your body absorb the iron from them.',
        cycle='We found no evidence tying broccoli to a particular phase. Its vitamin C helps your body absorb plant iron from the same meal (NIH ODS), a useful pairing for anyone who menstruates.',
        evidence='Absorption statement: NIH ODS Vitamin C and Iron. No broccoli-specific cycle trial was used.',
        cautions=[
            dict(text='Broccoli contains vitamin K. If you take warfarin or a similar blood thinner, keep your intake steady and tell your clinician.', source='NIH ODS Vitamin K (interaction with warfarin and other anticoagulants)'),
        ]),
    'orange': dict(
        name='Orange', fdc=746771, type='Foundation', published='12/16/2019',
        desc='Oranges, raw, navels', state='raw, flesh only',
        grams=140, portion='1 orange (about 2⅞ in across, 140 g)',
        per100=dict(kcal=47, protein=0.91, fat=0.15, carb=11.8, fiber=2.0, iron=0.33, folate=25, mg=10.7, k=166, vitc=59.1, zn=0.11),
        why_record='The current Foundation record for an orange (navel, raw) with a household measure; it replaces the generic SR Legacy "all commercial varieties" record.',
        keys=[('vitc', 0), ('folate', 0), ('k', 0)],
        offers='An orange is a juicy, portable fruit that is an excellent source of vitamin C, with some folate and fibre.',
        how='Eat it whole or in segments, add to salads, or squeeze over cooked greens and lentils. Having one with an iron-rich plant meal helps your body absorb the iron.',
        cycle='We found no evidence tying oranges to a particular phase. Vitamin C improves the absorption of plant iron (NIH ODS), so an orange pairs well with lentils or spinach.',
        evidence='Absorption statement: NIH ODS Vitamin C and Iron. No orange-specific cycle trial was used.',
        cautions=[]),
}

def amount(f, key):
    return f['per100'][key] * f['grams'] / 100

names = {'iron': 'Iron', 'folate': 'Folate', 'vitc': 'Vitamin C', 'vitk': 'Vitamin K', 'mg': 'Magnesium', 'zn': 'Zinc', 'k': 'Potassium', 'vita': 'Vitamin A'}
out = {
    '_status': 'REFERENCE DRAFT for editorial approval. Not production content. Nothing here is bundled in the app.',
    '_sources': {
        'usda': 'USDA FoodData Central, https://fdc.nal.usda.gov/ (records named in each entry), read 2026-10-25',
        'nihOds': 'NIH Office of Dietary Supplements fact sheets (Iron, Folate, Vitamin C, Vitamin K, Magnesium, Zinc, Potassium, Vitamin A), https://ods.od.nih.gov/factsheets/list-all/, read 2026-10-25',
        'niddk': 'NIDDK, Eating, Diet & Nutrition for Kidney Stones, https://www.niddk.nih.gov/health-information/urologic-diseases/kidney-stones/eating-diet-nutrition, read 2026-10-25',
    },
    '_referenceNote': 'Percentages compare ONE serving with the daily reference intake for the NUTRIENT for adult women of the stated age group (RDA, or AI where noted). They are not a recommended portion of the food and not an individual target. Vitamin K is shown as an amount only.',
    '_reviewLabel': 'Nutrition values checked against USDA and NIH sources; not clinically reviewed.',
    'profiles': {},
}
for fid, f in FOODS.items():
    keys = []
    for key, dec in f['keys']:
        unit, groups, kind, nm = REF[key]
        v = amount(f, key)
        entry = {'name': nm, 'amount': round(v, dec) if dec else round(v), 'unit': unit}
        if key != 'vitk':  # large vitamin K percentages are not shown
            entry['reference'] = [{'group': g, 'kind': kind, 'value': val, 'unit': unit, 'percent': round(100 * v / val)} for g, val in groups]
        else:
            entry['referenceNote'] = f'Adequate intake for women 19 and over is 90 µg; shown as an amount only. See the note on blood thinners.'
        keys.append(entry)
    out['profiles'][fid] = {
        'catalogueId': fid, 'name': f['name'],
        'sections': {'whatItOffers': f['offers'], 'practicalServing': f['portion'], 'howToEatIt': f['how'], 'cycleRelevance': f['cycle']},
        'source': {'usdaFdcId': f['fdc'], 'usdaDescription': f['desc'], 'dataType': f['type'], 'published': f['published'],
                   'preparationState': f['state'], 'portionGrams': f['grams'], 'portion': f['portion'], 'whyThisRecord': f['why_record'], 'per100g': f['per100']},
        'perServing': {'energyKcal': round(amount(f, 'kcal')), 'proteinG': round(amount(f, 'protein'), 1), 'fatG': round(amount(f, 'fat'), 1),
                       'carbohydrateG': round(amount(f, 'carb'), 1), 'fiberG': round(amount(f, 'fiber'), 1), 'keyNutrients': keys},
        'cautions': f['cautions'], 'evidence': f['evidence'],
        'review': {'composition': 'verified against USDA FoodData Central', 'referenceIntakes': 'verified against NIH ODS',
                   'cautions': 'verified against NIH ODS / NIDDK' if f['cautions'] else 'none recorded',
                   'editorial': 'revised after owner review; pending approval', 'clinical': 'not clinically reviewed', 'publishable': False},
    }
json.dump(out, open('docs/food-profiles/reference-profiles.json', 'w'), indent=2, ensure_ascii=False)
for fid, p in out['profiles'].items():
    print(fid, p['perServing']['energyKcal'], [(k['name'], k['amount'], [r['percent'] for r in k.get('reference', [])]) for k in p['perServing']['keyNutrients']])

# The app bundle: the same five reviewed profiles, marked publishable.
import copy
bundle = {
    'version': 1,
    'reviewLabel': out['_reviewLabel'],
    'referenceNote': out['_referenceNote'],
    'sources': out['_sources'],
    'profiles': {},
}
for fid, pr in out['profiles'].items():
    b = copy.deepcopy(pr)
    b['review']['editorial'] = 'wording and preparations approved by the owner (five reference profiles)'
    b['review']['publishable'] = True
    bundle['profiles'][fid] = b
json.dump(bundle, open('assets/content/food_profiles.json', 'w'), indent=2, ensure_ascii=False)
