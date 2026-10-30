"""Builds wave-1-review-package.md: the concise package for the owner's editorial approval of Wave 1.

Run after build_publication_plan.py:  python3 docs/food-profiles/build_wave1_review_package.py
Nothing here publishes anything; wave-1-candidate.json stays unpublished (publishable: false).
"""
import collections, json, re

ROOT = 'docs/food-profiles/'
data = json.load(open(ROOT + 'complete-draft-dataset.json'))
profiles = data['profiles']
plan = json.load(open(ROOT + 'publication-plan.json'))
notes = json.load(open(ROOT + 'audit-notes.json'))
foods = {f['id']: f for f in json.load(open('assets/content/foods.json'))['foods']}
phase = {k: list(f['why'])[0] for k, f in foods.items() if f['why']}
approved_meta = json.load(open('assets/content/food_profiles.json'))
wave1 = plan['wave1']
sample = plan['sampleSheet']
name = lambda i: profiles[i]['name']

L = []
w = L.append
w('# Wave 1 editorial review package\n')
w('> **Superseded for the cycle wording:** the cycle text in this longer package is the earlier draft. The final proposed wording, heading and previews are in `wave-1-approval-summary.md`.\n')
w(f'**Status: for your review. Nothing is published.** `wave-1-candidate.json` ({len(wave1)} profiles) stays unpublished with `publishable: false`; none is in `assets/content/food_profiles.json` or unlocked in Food Detail, and the 15 blocked foods stay blocked. Approval of this package is not approval to publish.\n')
w('How to read it: part 1 shows twelve complete profiles; parts 2 to 5 give the exact wording of every repeated element; part 6 lists what is still open. Nutritional facts (sourced) are kept apart from the editorial "featured phase" (no phase-specific evidence) throughout.\n')

# ---- 1. twelve complete profiles
w('## 1. Twelve complete representative profiles\n')
w('Chosen to span the four phases and the main food groups. Each shows exactly what a reader would see, plus the audit trail.\n')
for k in sample:
    p = profiles[k]
    s = p['sections']
    src = p['source']
    ps = p['perServing']
    w(f'### {p["name"]} (`{k}`)\n')
    w(f'*Featured phase in the catalogue:* {phase[k]} (editorial; see part 5).  *Category:* {foods[k]["category"]}.\n')
    w('**Nutritional facts (sourced)**\n')
    w(f'- Record: USDA FoodData Central {src["usdaFdcId"]}, "{src["usdaDescription"]}" ({src["dataType"]}, {src["published"]}); preparation: {src["preparationState"]}')
    w(f'- Serving: {src["portion"]}')
    nutr = ', '.join(f'{n["name"]} {n["amount"]} {n["unit"]}' + (f' ({n["reference"][0]["percent"]}% of the reference)' if n.get('reference') else '') for n in ps['keyNutrients'])
    w(f'- Per serving: {ps["energyKcal"]} kcal, protein {ps["proteinG"]} g, fat {ps["fatG"]} g, carbohydrate {ps["carbohydrateG"]} g' + (f', fibre {ps["fiberG"]} g' if ps.get('fiberG') is not None else '') + f'. Key nutrients: {nutr}.')
    w(f'- Allergens (catalogue tags): {", ".join(p["allergens"]) or "none tagged"}\n')
    w('**Five-part text**\n')
    w(f'1. *What this food offers:* {s["whatItOffers"]}')
    w(f'2. *A practical serving:* {s["practicalServing"]}')
    w(f'3. *How to eat it:* {s["howToEatIt"]}')
    w(f'4. *Cycle relevance:* {s["cycleRelevance"]}')
    w(f'5. *Good to know (cautions):* ' + (' / '.join(f'{c["text"]} [{c["status"]}]' for c in p['cautions']) or 'none'))
    w('')

# ---- 2. cycle relevance wording
def mask(p):
    t = p['sections']['cycleRelevance'].replace(p['name'].lower(), '{food}').replace(p['name'], '{food}')
    return re.sub(r'\d[\d,.]*', '#', t)

templates = collections.defaultdict(list)
for k in wave1:
    templates[mask(profiles[k])].append(k)
w('## 2. The exact wording used for cycle relevance\n')
w(f'Across the {len(wave1)} Wave 1 profiles the cycle-relevance text falls into {len(templates)} wordings once numbers and food names are masked (`#`, `{{food}}`), which group into the kinds below. Every one says that no cycle-phase claim is made; none claims a hormone, fertility, PMS, mood or phase benefit (a test enforces this).\n')
def kind(t):
    if 'menstrual blood loss (NIH ODS)' in t:
        return 'Iron: a nutrient fact for people who menstruate, sourced to NIH ODS. True all month; not a phase claim.'
    if 'Calcium needs are' in t:
        return 'Calcium: a nutrient fact, sourced to NIH ODS.'
    if 'Folate is a nutrient' in t:
        return 'Folate: a nutrient fact, sourced to NIH ODS.'
    if 'Vitamin C helps' in t or 'Vitamin C improves' in t or 'Plant iron is absorbed' in t or 'vitamin C helps iron' in t:
        return 'Vitamin C and plant-iron absorption: a nutrient fact, sourced to NIH ODS.'
    if re.fullmatch(r'No cycle-phase claim is made for \{food\}(s|es)?\.', t):
        return 'Only the statement that no claim is made.'
    return 'Other food-specific fact (for example vitamin D, a mercury or gluten note, a short description); see the profile.'


groups = collections.OrderedDict()
for t, ks in templates.items():
    groups.setdefault(kind(t), []).append((t, ks))
w('| Kind | Profiles | Example wording |\n|---|---|---|')
for kd, items in sorted(groups.items(), key=lambda x: -sum(len(k) for _, k in x[1])):
    n = sum(len(k) for _, k in items)
    ex = max(items, key=lambda x: len(x[1]))[0]
    w(f'| {kd} | {n} | {ex} |')
w('')
w('Every wording ends with, or consists of, a statement that no cycle-phase (or phase-specific) claim is made. The full text of any profile is in `wave-1-candidate.json`.\n')

# ---- 3. cautions
cautions = collections.defaultdict(list)
for k in wave1:
    for c in profiles[k]['cautions']:
        cautions[(c['text'], c['status'], c['source'])].append(k)
w('## 3. Representative food-safety and allergen cautions\n')
w(f'Wave 1 carries {len(cautions)} distinct caution texts. Every one is `sourced` (an authoritative page named in the profile) or a `catalogue-tag` allergen line taken from the catalogue. None is `unverified-inherited`; none is a sodium warning.\n')
w('| Profiles | Caution | Status | Source |\n|---|---|---|---|')
for (t, st, so), ks in sorted(cautions.items(), key=lambda x: -len(x[1]))[:40]:
    w(f'| {len(ks)} | {t} | {st} | {so} |')
if len(cautions) > 40:
    w(f'\n(+ {len(cautions) - 40} more distinct texts, each on one profile, in `wave-1-candidate.json`.)')
w('')

# ---- 4. labels
w('## 4. Proposed review and attribution labels\n')
w('| Label | Proposed wording | Note |\n|---|---|---|')
w(f'| Review label (shown on every profile) | "{approved_meta["reviewLabel"]}" | Same label the five approved profiles use. |')
w(f'| Reference note | "{approved_meta["referenceNote"]}" | Explains that percentages compare a serving with a nutrient reference, not a recommended portion. |')
w('| Data attribution | "Nutrient amounts: USDA FoodData Central (record and date shown). Reference intakes: NIH Office of Dietary Supplements." | Each profile already carries the record id, description, data type and publication date. |')
w('| Caution attribution | Each caution names its source page. Allergen lines read "Allergen tag from the MoonCycle catalogue" in the data and need no external source. | |')
w('| Editorial status | "Editorial review: approved by <name>, <date>" | Filled in by you. Until then `publishable` stays false. |')
w('| Clinical review | **"Not clinically reviewed."** | No profile may be described as clinically reviewed unless a qualified professional has actually reviewed it and is named. None has. |\n')

# ---- 5. evidence for phase-specific statements
w('## 5. Evidence for each phase-specific statement\n')
w('**There are no phase-specific statements in the Wave 1 profile text.** The profiles describe what a food provides and, in some, a nutrient fact for people who menstruate. The only phase element is the catalogue\'s "featured phase" for each food, which is editorial:\n')
w('- The product principle (`docs` in the research project, and the in-app note) is that a featured phase is where Moon Cycle chooses to introduce a food for nutritional fit, meal style and monthly variety, "not a claim that the food should only be eaten during that phase".')
w('- I found **no** phase-specific nutritional requirement for any Wave 1 food. The design review rated almost all original phase links "editorial", and even its strongest case (iron) says eating iron-rich food during the period "hasn\'t been shown to matter more than at other times".')
w('- Where origin is concerned, see the provenance audit (PR #63): the original phase lists have no identified independent source.')
phase_counts = collections.Counter(phase[k] for k in wave1)
w(f'- Wave 1 foods by featured phase: ' + ', '.join(f'{p} {phase_counts[p]}' for p in ('menstrual', 'follicular', 'ovulatory', 'luteal')) + '.\n')
w('| Kind of statement | Where it appears | Evidence |\n|---|---|---|')
w('| Nutrient amounts per serving | every profile | USDA FoodData Central, recomputed by script and test; re-checked against the live record |')
w('| Reference percentages | profiles with key nutrients | NIH ODS RDA/AI for adult women |')
w('| Iron needs are higher for people who menstruate | profiles with 10% or more of the iron reference | NIH ODS Iron fact sheet |')
w('| Calcium, folate, vitamin C and iron absorption sentences | as listed in part 2 | NIH ODS fact sheets |')
w('| Featured phase | catalogue only, not in profile text | None (editorial) |')
w('| Traditional or theoretical phase associations | **none in the profiles** | not used |\n')

# ---- 6. open questions
w('## 6. Remaining substantive questions\n')
w('1. **Approve or amend the cycle-relevance wording** (part 2). Two points to consider: it says "women aged 19 to 50" because the NIH references are for adult women; and it names menstrual blood loss, which applies to anyone who menstruates.')
w('2. **Featured phase and provenance.** Wave 1 profiles belong to foods whose featured phase has no independent source (PR #63). Do you want profiles published before the phase lists are re-derived, given the profile text itself makes no phase claim?')
w('3. **Allergen lines.** They come from catalogue tags (conservative). Keep them all as written (recommended) or refine with an allergist or label source (decision D12).')
w('4. **Sodium** is data only; Food Detail has no place for a note (decision D11). No Wave 1 profile has a sodium note.')
w('5. **"If your periods are heavy…"-style advice** is not used in Wave 1 text; the five approved profiles use a version of it. Confirm that is intended.')
w('6. **Reviewer and date** to record on each approved profile.')
w('7. **Publishing step**: after your approval a separate change moves the approved profiles into `assets/content/food_profiles.json`, runs CI, and I rebuild the iPhone app. Nothing happens until you say so.\n')
w(f'The other open decisions (D1 to D12, `audit-report.md` section 3) affect profiles outside Wave 1 and do not block it.\n')
open(ROOT + 'wave-1-review-package.md', 'w').write('\n'.join(L) + '\n')
print('written', len(L), 'lines;', len(templates), 'cycle wordings;', len(cautions), 'distinct cautions')
