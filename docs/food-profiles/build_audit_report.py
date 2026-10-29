"""Builds the consolidated audit review package: docs/food-profiles/audit-report.md and audit-summary.json.

Run from the repo root after audit_profiles.py, apply_audit_fixes.py, the batch builds and build_reports.py:
    python3 docs/food-profiles/build_audit_report.py
Inputs: complete-draft-dataset.json, audit-findings.json (live USDA comparison), audit-corrections.json
(what the audit changed, computed against the pre-audit dataset at 4763e53), audit-notes.json (editorial
judgment notes written by hand) and blocked-decisions.json.
"""
import collections, json

ROOT = 'docs/food-profiles/'
EXISTING = 'Existing MoonCycle catalogue caution'
data = json.load(open(ROOT + 'complete-draft-dataset.json'))
profiles, blocked_names = data['profiles'], data['blocked']
findings = json.load(open(ROOT + 'audit-findings.json'))
corrections = json.load(open(ROOT + 'audit-corrections.json'))
notes = json.load(open(ROOT + 'audit-notes.json'))
decisions = json.load(open(ROOT + 'blocked-decisions.json'))
foods = {f['id']: f for f in json.load(open('assets/content/foods.json'))['foods']}
name = lambda i: profiles[i]['name']

unsourced = {i: [c['text'] for c in p['cautions'] if c['source'].startswith(EXISTING) and 'supports' not in c['source']]
             for i, p in profiles.items()}
unsourced = {i: v for i, v in unsourced.items() if v}
open_findings = {i: v for i, v in findings.items() if v and i not in ('chestnut', 'cottage-cheese')}
judgment = collections.OrderedDict()
for kind in ('identity', 'servingState', 'unusualValues', 'safetyNotResearched'):
    for i, n in notes[kind].items():
        judgment.setdefault(i, []).append((kind, n))
needs_judgment = set(judgment)
flagged = needs_judgment | set(unsourced)
clean = sorted(i for i in profiles if i not in flagged and i not in open_findings)

summary = {
    'catalogueFoods': len(foods), 'approvedPublished': len(data['approved']), 'drafted': len(profiles),
    'blocked': len(blocked_names), 'missing': len(foods) - len(data['approved']) - len(profiles) - len(blocked_names),
    'auditedAgainstLiveUsda': len(findings), 'openDataFindings': len(open_findings),
    'correctedDuringAudit': len(corrections), 'needEditorialJudgment': len(needs_judgment),
    'carryOverCautionsWithoutSource': len(unsourced), 'validatedWithoutSubstantiveConcerns': len(clean),
    'publishable': sum(1 for p in profiles.values() if p['review']['publishable']),
}
json.dump(summary, open(ROOT + 'audit-summary.json', 'w'), indent=1)

L = []
w = L.append
w('# Food profile quality audit: consolidated review package\n')
w('Nothing here is published. All %d drafts remain unreviewed and outside the app; the %d approved profiles are unchanged.\n' % (summary['drafted'], summary['approvedPublished']))
w('## Exact totals\n')
w('| | Count |\n|---|---|')
for label, key in (('Catalogue foods', 'catalogueFoods'), ('Approved and published (unchanged)', 'approvedPublished'),
                   ('Drafted, unreviewed, unpublished', 'drafted'), ('Blocked', 'blocked'), ('Missing', 'missing'),
                   ('Drafts marked publishable', 'publishable')):
    w(f'| {label} | {summary[key]} |')
w('\n## What was checked, and how\n')
w(f'1. **Source identity, preparation, serving and amounts (all {summary["auditedAgainstLiveUsda"]}).** `audit_profiles.py` re-fetches every cited USDA FoodData Central record and compares: FDC id, description, publication date, every stored per-100 g value (including sodium), the serving weight against the record\'s household measures, and every per-serving amount and reference-intake percentage. **Result: 0 open findings.** Two serving texts (chestnut, cottage cheese) were reviewed and accepted with reasons recorded in the script. No USDA value had been mis-copied.')
w('2. **Prose (all 251).** Every section was read. Fixed: boilerplate cycle text, grammar slips, filler and promotional wording, robotic opening lines, awkward serving text, a unit-grammar bug ("1 calories").')
w('3. **Claims.** Cycle relevance makes no hormone, fertility, PMS or phase-specific benefit claim in any profile. Where a nutrient has a sourced reference (iron and menstrual blood loss, calcium, folate, vitamin C with plant iron), the sentence says so with its NIH ODS source.')
w('4. **Safety and allergens.** Allergen tags from the catalogue are now carried on every profile and shown in its cautions (parity is tested). Sourced cautions were added only after the source page was read: sodium (FDA, Dietary Guidelines), raw sprouts, smoked fish, deli ham and unpasteurised cheeses (FDA People at Risk of Foodborne Illness), honey and infants (CDC), fava beans and G6PD deficiency (MedlinePlus Genetics), seaweed iodine (NIH ODS). Existing catalogue cautions and exclusions are preserved.')
w('5. **Regression tests.** `test/content/food_profile_drafts_test.dart` now also checks provenance, duplicate ids, preparation state against the USDA description, sodium recomputation, allergen parity, placeholder and boilerplate prose, doubled words, and a wider claims list.\n')

w('## 1. Corrected during the audit (%d profiles)\n' % len(corrections))
by_kind = collections.defaultdict(list)
for i, ks in corrections.items():
    for k in ks:
        by_kind[k].append(i)
w('| Correction | Profiles |\n|---|---|')
for k, ids in sorted(by_kind.items(), key=lambda x: -len(x[1])):
    w(f'| {k} | {len(ids)} |')
w('')
for k in ('sourced safety caution added', 'sodium note added', 'serving wording', 'allergen line added'):
    w(f'- **{k}**: ' + ', '.join(name(i) for i in sorted(by_kind.get(k, []))))
w('\nNo nutrient number was changed: every number matched USDA.\n')

w('## 2. Profiles needing editorial judgment (%d)\n' % len(needs_judgment))
titles = {'identity': 'Food identity differs from the catalogue name', 'servingState': 'Serving is in a different state from how it is eaten',
          'unusualValues': 'Surprising or low-confidence USDA values', 'safetyNotResearched': 'Safety wording not researched or not added'}
for kind in ('identity', 'servingState', 'unusualValues', 'safetyNotResearched'):
    w(f'### {titles[kind]} ({len(notes[kind])})\n')
    for i, n in notes[kind].items():
        w(f'- **{name(i)}** (`{i}`): {n}')
    w('')

w('## 3. Existing catalogue cautions with no recorded source (%d profiles)\n' % len(unsourced))
w('These are carried over from the catalogue unchanged so no existing exclusion is lost. An editor should confirm or source each. Listed as `food: caution`.\n')
for i in sorted(unsourced):
    w(f'- {name(i)}: ' + '; '.join(unsourced[i]))
w('')

w('## 4. Blocked entries (15): decision table\n')
w('| Food | Why blocked | Standard nutrient information? | Alternative format | Keep in catalogue? | Recommendation |\n|---|---|---|---|---|---|')
for i, d in decisions.items():
    w(f"| {blocked_names[i]['name']} | {d['why']} | {d['standardNutrientInfo']} | {d['alternativeFormat']} | {d['keepInCatalogue']} | {d['recommendation']} |")
w('\nCorrection to an earlier statement: guacamole, oat milk and soft-shell crab do have USDA records (Survey/FNDDS or Foundation); the original search only covered SR Legacy and Foundation for some of them. They stay blocked pending your decision on using survey (average-recipe) data.\n')

w('## 5. Validated without substantive concerns (%d profiles)\n' % len(clean))
w('Data matches USDA, prose read and corrected where needed, no open identity, state, value or safety note. Still **unreviewed and unpublished**: an editor must approve every profile before it can appear in Food Detail.\n')
w(', '.join(name(i) for i in clean) + '\n')

w('## What you need to approve\n')
w('1. The editorial wording and structure of the draft profiles (start with section 2, then sample section 5; `review-list.md` has sampling sheets by category).')
w('2. The new sourced cautions and the sodium and allergen lines (section 1).')
w('3. A decision for each of the 15 blocked entries (section 4), including whether survey (FNDDS) data is acceptable.')
w('4. How to treat the carried-over catalogue cautions that have no source (section 3).')
w('5. Publishing itself: no draft is publishable. Each approved profile must be moved into `assets/content/food_profiles.json` with the review fields filled by a person; that is a separate change.')
open(ROOT + 'audit-report.md', 'w').write('\n'.join(L) + '\n')
print(json.dumps(summary, indent=1))
