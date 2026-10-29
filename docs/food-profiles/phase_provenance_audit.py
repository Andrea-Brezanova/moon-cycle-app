#!/usr/bin/env python3
"""Reconstructs where the food-to-phase assignments came from, from Git history only.

Run from the repo root:  python3 docs/food-profiles/phase_provenance_audit.py
Writes docs/food-profiles/phase-assignment-provenance-matrix.json and
phase-assignment-provenance-summary.json (the report is phase-assignment-provenance-audit.md).
It reads history with `git show`; it never changes assets/content or the app.
"""
import collections, json, subprocess

ROOT = 'docs/food-profiles/'


def sh(*a):
    return subprocess.run(a, capture_output=True, text=True, check=True).stdout


def foods_at(commit):
    out = {}
    for f in json.loads(sh('git', 'show', f'{commit}:assets/content/foods.json'))['foods']:
        for ph in (f.get('why') or {}):
            out.setdefault(f['id'], []).append(ph)
    return out


# The stages, oldest first. Dates and subjects are read from Git, not typed.
STAGES = [('56e981d', 'design/content/ingredients.json', 'Design package: Emergent baseline, "placement preserved exactly"'),
          ('8828f98', 'assets/content/foods.json', 'First bundled catalogue, "verbatim from the handoff"'),
          ('b2c071f', 'assets/content/foods.json', 'Foods v2 integration (25 foods per phase)'),
          ('f9c0241', 'assets/content/foods.json', 'Foods v2 frozen: 142 featured foods'),
          ('HEAD', 'assets/content/foods.json', 'Current main')]
design = json.loads(sh('git', 'show', '56e981d:design/content/ingredients.json'))
by_stage = {'56e981d': {i['id']: list(i['recommendedPhases']) for i in design['ingredients'] if i['recommendedPhases']}}
for c in ('8828f98', 'b2c071f', 'f9c0241', 'HEAD'):
    by_stage[c] = foods_at(c)
stage_info = {}
for c, path, label in STAGES:
    date, subject = sh('git', 'log', '-1', '--format=%ad|%s', '--date=short', c).strip().split('|', 1)
    stage_info[c] = dict(commit=sh('git', 'rev-parse', '--short', c).strip(), date=date, subject=subject, file=path, label=label,
                         assignedFoods=len(by_stage[c]),
                         perPhase=dict(collections.Counter(p for v in by_stage[c].values() for p in v)))

head_foods = {f['id']: f for f in json.load(open('assets/content/foods.json'))['foods']}
audit = {i['id']: i for i in design['ingredients']}
drafts = json.load(open(ROOT + 'complete-draft-dataset.json'))['profiles']
approved = json.load(open('assets/content/food_profiles.json'))['profiles']
SEEDS = {'sesame-seeds', 'sunflower-seeds', 'flaxseeds', 'pumpkin-seeds'}  # named "seed-cycling convention" in the design package
EMERGENT = ('Emergent app export: private repo Andrea-Brezanova/moon-cycle, frontend/src/data/phases.ts @374f27f '
            '(the recipe data in that file is labelled "SAMPLE CONTENT"), as copied into design/content/ingredients.json (56e981d). Origin of that list: UNKNOWN.')
V2 = ('Foods v2 "production candidate (Moon Cycle Research)", chosen by the owner (b2c071f commit message, docs/decisions.md). '
      'Its rationale labels and USDA provenance live in a research project that is not in this repository: UNKNOWN.')


def cycle_text(fid):
    if fid in drafts:
        return drafts[fid]['sections']['cycleRelevance']
    return approved.get(fid, {}).get('sections', {}).get('cycleRelevance', '')


LABELS = {'B': 'Retained from the original list; underlying sources not identified (not independently established)',
          'D': 'Source unknown: not in the original list, no rationale in this repository',
          'E': 'Changed after the original list; reason not documented in this repository'}
matrix, counts = [], collections.Counter()
for fid, ph in sorted(by_stage['HEAD'].items(), key=lambda x: (x[1][0], x[0])):
    cur = ph[0]
    hist = [dict(stage=c, commit=stage_info[c]['commit'], phases=by_stage[c].get(fid)) for c, _, _ in STAGES]
    base = by_stage['56e981d'].get(fid)
    first = next(h for h in hist if h['phases'] and cur in h['phases'])
    a = audit.get(fid, {}).get('audit', {})
    link = a.get(cur, {})
    if base is None:
        cls, origin, conf = 'D', V2, 'Low'
    elif cur not in base:
        cls, origin, conf = 'E', EMERGENT + ' Phase later changed in Foods v2.', 'Low'
    else:
        cls, origin, conf = 'B', EMERGENT + ' Retained in Foods v2 owner curation.', 'Medium'
    changes = []
    seq = [(h['commit'], h['phases']) for h in hist]
    for (c0, p0), (c1, p1) in zip(seq, seq[1:]):
        if p0 != p1:
            changes.append(f'{c0}: {p0 or "not assigned"} -> {c1}: {p1 or "not assigned"}')
    iron = 'menstrual blood loss (NIH ODS)' in cycle_text(fid) or ('iron' in cycle_text(fid).lower() and fid in approved)
    phase_relevant = link.get('phaseLink') == 'phase-relevant'
    if fid in SEEDS:
        support = 'traditional-or-theoretical'
    elif phase_relevant and cur == 'menstrual':
        support = 'menstruating-adult-nutrient'
    elif phase_relevant:
        support = 'menstruating-adult-nutrient-limited'
    elif iron and cur == 'menstrual':
        support = 'menstruating-adult-nutrient'
    elif link or fid in drafts or fid in approved:
        support = 'general-nutrition-only'
    else:
        support = 'not-assessed'
    review = 'high' if cls in ('D', 'E') or fid in SEEDS else 'medium' if not phase_relevant else 'low'
    counts[cls] += 1
    matrix.append(dict(
        id=fid, name=head_foods[fid]['name'], currentPhase=cur, classification=cls,
        firstIdentifiableCommit=dict(commit=first['commit'], date=stage_info[first['stage']]['date'], file=stage_info[first['stage']]['file']),
        documentedOriginalSource=origin,
        baselinePhases=base, phaseHistory=hist, subsequentChanges=changes,
        supportingResearchInRepo=dict(
            designAuditSources=link.get('sources', []), designAuditPhaseLink=link.get('phaseLink'),
            designAuditNote=link.get('phaseLinkNote'), draftProfileCycleSentence=cycle_text(fid)[:220] or None),
        scientificSupport=dict(
            primaryClass=support,
            generalNutritionalBenefit=bool(link or fid in drafts or fid in approved),
            menstruatingAdultNutrientConsideration=support.startswith('menstruating-adult-nutrient') or iron,
            phaseSpecificRequirementEvidence='none identified',
            traditionalOrTheoreticalAssociation=fid in SEEDS,
            noReliablePhaseSpecificEvidence=True),
        independentlyJustified='no',
        provenanceConfidence=conf,
        conventionLinked=fid in SEEDS,
        classificationLabel=LABELS[cls],
        provenanceEstablished=False,  # no class here means the underlying source of a placement is identified
        furtherReviewRequired=True, reviewPriority=review))

dropped = sorted(k for k in by_stage['56e981d'] if k not in by_stage['HEAD'])
summary = dict(
    stages=stage_info, phaseAssignedFoodsNow=len(matrix),
    classificationCounts=dict(sorted(counts.items())) | {'A': counts.get('A', 0), 'C': counts.get('C', 0)},
    scientificSupportCounts=dict(collections.Counter(m['scientificSupport']['primaryClass'] for m in matrix)),
    reviewPriorityCounts=dict(collections.Counter(m['reviewPriority'] for m in matrix)),
    perPhaseNow=dict(collections.Counter(m['currentPhase'] for m in matrix)),
    perPhaseByClass={p: dict(collections.Counter(m['classification'] for m in matrix if m['currentPhase'] == p)) for p in ('menstrual', 'follicular', 'ovulatory', 'luteal')},
    baselineFoodsNoLongerPhaseAssigned=dropped, baselineFoodsNoLongerAssignedCount=len(dropped),
    conventionLinked=sorted(SEEDS))
json.dump(dict(_about='Provenance matrix for the 142 phase-assigned foods. Generated by phase_provenance_audit.py from Git history. Nothing here changes the app.', foods=matrix),
          open(ROOT + 'phase-assignment-provenance-matrix.json', 'w'), indent=1, ensure_ascii=False)
json.dump(summary, open(ROOT + 'phase-assignment-provenance-summary.json', 'w'), indent=1, ensure_ascii=False)
print(json.dumps({k: summary[k] for k in ('classificationCounts', 'scientificSupportCounts', 'reviewPriorityCounts', 'perPhaseByClass', 'baselineFoodsNoLongerAssignedCount')}, indent=1))
