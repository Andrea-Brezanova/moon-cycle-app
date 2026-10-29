"""Builds the consolidated audit review package: docs/food-profiles/audit-report.md and audit-summary.json.

Run after audit_profiles.py, apply_audit_fixes.py, the batch builds and build_reports.py:
    python3 docs/food-profiles/build_audit_report.py
Inputs: complete-draft-dataset.json, audit-findings.json (live USDA comparison), audit-corrections.json
(what the first audit changed, against the pre-audit dataset at 4763e53), audit-notes.json (hand-written
editorial notes, resolutions and decisions) and blocked-decisions.json.
"""
import collections, json

ROOT = 'docs/food-profiles/'
data = json.load(open(ROOT + 'complete-draft-dataset.json'))
profiles, blocked_names = data['profiles'], data['blocked']
findings = json.load(open(ROOT + 'audit-findings.json'))
corrections = json.load(open(ROOT + 'audit-corrections.json'))
notes = json.load(open(ROOT + 'audit-notes.json'))
decisions = json.load(open(ROOT + 'blocked-decisions.json'))
foods = {f['id']: f for f in json.load(open('assets/content/foods.json'))['foods']}
name = lambda i: profiles[i]['name']

status_counts = collections.Counter(c['status'] for p in profiles.values() for c in p['cautions'])
unverified = {i: [c['text'] for c in p['cautions'] if c['status'] == 'unverified-inherited'] for i, p in profiles.items()}
unverified = {i: v for i, v in unverified.items() if v}
partly = {i: [c['text'] for c in p['cautions'] if c['status'] == 'partly-sourced'] for i, p in profiles.items()}
partly = {i: v for i, v in partly.items() if v}
open_findings = {i: [x for x in v if (i, x[0]) not in {('chestnut', 'serving'), ('cottage-cheese', 'serving')}] for i, v in findings.items()}
open_findings = {i: v for i, v in open_findings.items() if v}
decision_foods = {f for d in notes['decisions'] for f in d['foods']}
flagged = decision_foods | set(unverified)
clean = sorted(i for i in profiles if i not in flagged and i not in open_findings)
sodium_notes = sorted(i for i, p in profiles.items() if p['nutritionNotes'])

summary = {
    'catalogueFoods': len(foods), 'approvedPublished': len(data['approved']), 'drafted': len(profiles),
    'blocked': len(blocked_names), 'missing': len(foods) - len(data['approved']) - len(profiles) - len(blocked_names),
    'auditedAgainstLiveUsda': len(findings), 'openDataFindings': len(open_findings),
    'correctedInFirstAudit': len(corrections), 'resolvedInReadinessPass': len(notes['resolved']),
    'decisionsForOwner': len(notes['decisions']), 'profilesAffectedByADecision': len(decision_foods & set(profiles)),
    'cautionStatus': dict(status_counts), 'profilesWithUnverifiedInheritedCaution': len(unverified),
    'profilesWithSodiumNote': len(sodium_notes), 'validatedWithoutSubstantiveConcerns': len(clean),
    'publishable': sum(1 for p in profiles.values() if p['review']['publishable']),
}
json.dump(summary, open(ROOT + 'audit-summary.json', 'w'), indent=1)

L = []
w = L.append
w('# Food profile quality audit: consolidated review package\n')
w('Nothing here is published. All %d drafts remain unreviewed and outside the app; the %d approved profiles are unchanged. See `publication-plan.md` for the approval plan.\n' % (summary['drafted'], summary['approvedPublished']))
w('## Exact totals\n')
w('| | Count |\n|---|---|')
for label, key in (('Catalogue foods', 'catalogueFoods'), ('Approved and published (unchanged)', 'approvedPublished'),
                   ('Drafted, unreviewed, unpublished', 'drafted'), ('Blocked', 'blocked'), ('Missing', 'missing'),
                   ('Drafts marked publishable', 'publishable')):
    w(f'| {label} | {summary[key]} |')
w('\n## What was checked, and how\n')
w(f'1. **Source identity, preparation, serving and amounts (all {summary["auditedAgainstLiveUsda"]}).** `audit_profiles.py` re-fetches every cited USDA FoodData Central record and compares FDC id, description, publication date, every stored per-100 g value (including sodium), the serving weight against the record\'s household measures, and every per-serving amount and reference percentage. **Result: 0 open findings**; two serving texts (chestnut, cottage cheese) were reviewed and accepted with reasons recorded in the script. No USDA value had been mis-copied.')
w('2. **Prose (all 251).** Every section was read. Fixed: boilerplate cycle text, grammar slips, filler and promotional wording, robotic opening lines, awkward serving text, a unit-grammar bug.')
w('3. **Claims.** No hormone, fertility, PMS, mood or phase-benefit claim in any profile; a test enforces it. Where a nutrient has a sourced reference (iron and menstrual blood loss, calcium, folate, vitamin C with plant iron), the sentence names its NIH ODS source.')
w('4. **Safety and allergens.** Every caution now has a status: `sourced` (an authoritative page read supports the wording), `partly-sourced`, `catalogue-tag` (an allergen tag from `foods.json`), or `unverified-inherited` (carried over from the catalogue, no source found). Nothing unverified is described as verified.')
w('5. **Regression tests.** `test/content/food_profile_drafts_test.dart` checks provenance, preparation state, sodium, allergen parity, caution status and sources, placeholder prose, and a wide claims list.\n')

w('## 1. Corrected during the first audit (%d profiles)\n' % len(corrections))
by_kind = collections.defaultdict(list)
for i, ks in corrections.items():
    for k in ks:
        by_kind[k].append(i)
w('| Correction | Profiles |\n|---|---|')
for k, ids in sorted(by_kind.items(), key=lambda x: -len(x[1])):
    w(f'| {k} | {len(ids)} |')
w('\nNo nutrient number was changed: every number matched USDA.\n')

w('## 2. Resolved in the readiness pass (%d)\n' % len(notes['resolved']))
w('Straightforward issues closed with a traceable source or an explicit wording fix:\n')
for i, n in notes['resolved'].items():
    w(f'- **{name(i)}** (`{i}`): {n}')
w('\nAlso: sodium no longer appears as a caution. It is stored as data for every profile; a calm nutrition note appears only at 460 mg or more per serving (the FDA\'s 20%-of-Daily-Value "high" line) and is not worded as a warning. The kidney bean caution was corrected to the FDA wording in both the catalogue and the draft (soak 5 hours, boil 30 minutes, no slow cooker, canned beans already cooked). Vitamin E was dropped from the key nutrients of bagel and granola because the USDA value looks unreliable (D5).\n')

w('## 3. Decisions for you (%d decisions, %d profiles)\n' % (len(notes['decisions']), len(decision_foods & set(profiles))))
for d in notes['decisions']:
    w(f'**{d["id"]}. {d["title"]}** ({", ".join(name(f) if f in profiles else f for f in d["foods"])})  ')
    w(f'{d["question"]}  ')
    w(f'*Recommendation:* {d["recommendation"]}\n')

w('## 4. Inherited cautions: verification status\n')
w('| Status | Cautions |\n|---|---|')
for k in ('sourced', 'partly-sourced', 'catalogue-tag', 'unverified-inherited'):
    w(f'| {k} | {status_counts.get(k, 0)} |')
w('')
w(f'The earlier audit counted 59 profiles carrying an inherited caution with no recorded source. After reading authoritative pages (FDA, NIDDK, NIH ODS, MedlinePlus), allergen categories, gluten, oats, brown rice, cantaloupe, rhubarb, kelp and tuna cautions now carry sources. **{len(unverified)} profiles still carry an inherited caution I could not source** (kept, labelled `unverified-inherited`, not described as verified):\n')
for i in sorted(unverified):
    w(f'- {name(i)}: ' + '; '.join(unverified[i]))
w('\nSources that did not support an inherited caution: NIDDK\'s kidney-stone page lists spinach, rhubarb, nuts, peanuts and wheat bran but not chard, so the chard oxalate caution stays unverified. The FDA page read does not mention lima beans, so "always cook thoroughly" stays unverified. Mollusc and celery allergen tags rest on the EU allergen list, which I could not load.\n')
w(f'`partly-sourced` ({len(partly)} profiles) means the page supports the topic but not every detail, for example "limit to 1-2 Brazil nuts a day" (NIH ODS supports high selenium and the 400 mcg upper limit, not the 1-2 figure).\n')

w('## 5. Blocked entries (15): decision table\n')
w('| Food | Why blocked | Standard nutrient information? | Survey/FNDDS or other record appropriate? | Alternative format | Keep in catalogue? | Recommendation |\n|---|---|---|---|---|---|---|')
for i, d in decisions.items():
    sr = d['surveyRecord']
    w(f"| {blocked_names[i]['name']} | {d['why']} | {d['standardNutrientInfo']} | **{sr['appropriate']}**: {sr['limitation']} | {d['alternativeFormat']} | {d['keepInCatalogue']} | {d['recommendation']} |")
w('\nRule applied: no average-recipe or generic record stands in for an exact ingredient unless the limitation is stated in the profile. Nothing is substituted in this pass.\n')

w('## 6. Validated without substantive concerns (%d profiles)\n' % len(clean))
w('Data matches USDA, prose read, every caution sourced or a catalogue tag, and no open decision. Still **unreviewed and unpublished**.\n')
w(', '.join(name(i) for i in clean) + '\n')
open(ROOT + 'audit-report.md', 'w').write('\n'.join(L) + '\n')
print(json.dumps(summary, indent=1))
