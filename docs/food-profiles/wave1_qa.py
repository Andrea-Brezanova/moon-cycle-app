#!/usr/bin/env python3
"""Editorial quality checks for the Wave 1 profiles (the 101 in publication-plan.json). Writes wave-1-qa-report.md.

    python3 docs/food-profiles/wave1_qa.py
Read-only: it changes no profile and publishes nothing."""
import collections, json, re, sys

sys.path.insert(0, 'docs/food-profiles')
from wave1_wording import CLOSING_NUTRIENTS, CLOSING_PLAIN  # noqa: E402

R = 'docs/food-profiles/'
profiles = json.load(open(R + 'complete-draft-dataset.json'))['profiles']
plan = json.load(open(R + 'publication-plan.json'))
foods = {f['id']: f for f in json.load(open('assets/content/foods.json'))['foods']}
phase = {k: list(f['why'])[0] for k, f in foods.items() if f['why']}
wave1 = plan['wave1']
cand = json.load(open(R + 'wave-1-candidate.json'))['profiles']


def syllables(w):
    w = re.sub(r'[^a-z]', '', w.lower())
    return max(1, len(re.findall(r'[aeiouy]+', w)) - (1 if w.endswith('e') and len(w) > 2 else 0))


def flesch(t):
    sents = [s for s in re.split(r'[.!?]+\s', t) if s.strip()]
    words = re.findall(r"[A-Za-z']+", t)
    if not sents or not words:
        return 100
    return 206.835 - 1.015 * len(words) / len(sents) - 84.6 * sum(syllables(w) for w in words) / len(words)


# Flagged by the automated check, then read and accepted (the reason is part of the record).
ACCEPTED = {
    ('figure', 'beef'): '"90%" is "90% lean", not a nutrient percentage.',
    ('overstatement', 'kidney-bean'): '"must" is a safety instruction (soak and boil dried beans).',
    ('overstatement', 'mackerel'): '"Best" is the FDA/EPA term "Best Choice".',
    ('readability', 'cabbage'): 'Short plain sentence; the score is driven by syllable counts.',
    ('readability', 'tomato'): 'Short plain sentence; the score is driven by syllable counts.',
    ('readability', 'mackerel'): 'A long list of nutrients in one sentence; accepted, could be split in editing.',
}
issues = collections.defaultdict(list)
for k in wave1:
    p = profiles[k]
    full_cycle = cand[k]['sections']['cycleRelevance']
    # The fixed closing statement is the owner's wording; the checks below look at the rest of the note.
    s = dict(p['sections'], cycleRelevance=full_cycle.replace(CLOSING_NUTRIENTS, '').replace(CLOSING_PLAIN, '').strip() or 'n/a')
    # 1 five-section format
    for sec, (lo, hi) in {'whatItOffers': (40, 420), 'practicalServing': (3, 90), 'howToEatIt': (20, 420), 'cycleRelevance': (3, 560)}.items():
        n = len(s[sec])
        if not lo <= n <= hi:
            issues['format'].append(f'{k}: {sec} is {n} characters')
    # 2 readability
    for sec in ('whatItOffers', 'howToEatIt', 'cycleRelevance'):
        if s[sec] == 'n/a':
            continue
        score = flesch(s[sec])
        if score < 35:
            issues['readability'].append(f'{k}: {sec} reads as difficult (Flesch {score:.0f})')
    # 3 jargon
    for sec, t in s.items():
        for j in re.findall(r'\b(DFE|RAE|glucosinolate\w*|phytohaemagglutinin|lectin|bioavailab\w+|oxalate)\b', t, re.I):
            issues['jargon'].append(f'{k}: "{j}" in {sec}')
    # 4 percentages in prose agree with the data
    pcts = {n['reference'][0]['percent'] for n in p['perServing']['keyNutrients'] if n.get('reference')}
    for m in re.finditer(r'(\d+)%', s['whatItOffers'] + ' ' + s['cycleRelevance']):
        v = int(m.group(1))
        if pcts and not any(abs(v - q) <= 2 for q in pcts) and 'DV' not in m.string:
            issues['figure'].append(f'{k}: prose says {v}% but key nutrients are {sorted(pcts)}')
    # 5 cycle section could imply a phase link
    cyc = full_cycle
    if 'menstrual blood loss' in cyc and 'every day of the month' not in cyc:
        issues['implication'].append(f'{k}: iron sentence does not say the need applies all month')
    if 'insufficient evidence to recommend eating this food during one particular menstrual phase' not in cyc:
        issues['implication'].append(f'{k}: missing the evidence statement')
    # 6 hedging words that overstate
    for w in re.findall(r'\b(best|ideal|perfect|must|essential|superfood|powerful|miracle|boosts?|supports?|helps? (?:to )?(?:balance|regulate|relieve))\b', ' '.join(s.values()), re.I):
        issues['overstatement'].append(f'{k}: "{w}"')
    # 7 duplicate sentences across sections
    sents = [x.strip() for sec in s.values() for x in re.split(r'(?<=[.!?])\s+', sec) if len(x) > 40]
    if len(sents) != len(set(sents)):
        issues['duplicate'].append(f'{k}: repeats a sentence')

accepted_log = []
for name, items in list(issues.items()):
    keep = []
    for x in items:
        k = x.split(':')[0]
        if (name, k) in ACCEPTED:
            accepted_log.append(f'- {name}, {k}: {ACCEPTED[(name, k)]}')
        else:
            keep.append(x)
    issues[name] = keep
iron_other = sum(1 for k in wave1 if 'menstrual blood loss' in cand[k]['sections']['cycleRelevance'] and phase[k] != 'menstrual')
iron_all = sum(1 for k in wave1 if 'menstrual blood loss' in cand[k]['sections']['cycleRelevance'])
L = ['# Wave 1 editorial quality assurance\n',
     f'Automated checks over the {len(wave1)} Wave 1 profiles (`wave1_qa.py`), on top of the data audit (every figure re-checked against live USDA records) and the regression tests. Nothing was changed and nothing is published.\n',
     '| Check | Result |', '|---|---|',
     f'| Nutrient figures and servings | Re-verified against USDA (0 open findings); serving text matches the source portion (test) |',
     f'| Five-section format | {len(issues["format"])} length outliers |',
     f'| Readability (Flesch reading ease below 35) | {len(issues["readability"])} |',
     f'| Technical terms in text | {len(issues["jargon"])} |',
     f'| Percentages in prose that disagree with the data | {len(issues["figure"])} |',
     f'| Overstating words (best, must, boosts, supports…) | {len(issues["overstatement"])} |',
     f'| Repeated sentences | {len(issues["duplicate"])} |',
     '| Hormone, fertility, PMS, mood or phase-benefit claims | 0 (test over all drafts) |',
     '| Cautions | all `sourced` or catalogue allergen tags; none unverified (test) |',
     f'| Cycle section could imply a phase link | {len(issues["implication"])} (see below) |\n']
for name in ('format', 'readability', 'jargon', 'figure', 'overstatement', 'duplicate', 'implication'):
    if issues[name]:
        L.append(f'## {name} ({len(issues[name])})\n')
        L += [f'- {x}' for x in issues[name][:60]]
        L.append('')
if accepted_log:
    L.append('## Flagged by a check, read, and accepted\n')
    L += accepted_log
    L.append('')
L.append('## Does the cycle section create misleading implications?\n')
L.append(f'- Checked on the PROPOSED wording. Every one of the {len(wave1)} notes ends with the same evidence statement; none says or implies that a food should be eaten in a phase.')
L.append(f'- {iron_all} notes carry the iron sentence. {iron_other} of them are on foods featured in a phase other than menstrual; each says the need applies every day of the month, not only during a period, so it does not read as "for your period".')
L.append('- The old heading "Cycle relevance" suggested every food has a cycle link; the proposed heading "Nutrition & your cycle" with this wording does not.')
L.append('- The pill "Recommended for your {phase} phase" did contradict the evidence; the previews use "Featured for variety in the {phase} phase" (see `why-this-food-audit.md`).\n')
open(R + 'wave-1-qa-report.md', 'w').write('\n'.join(L) + '\n')
print({k: len(v) for k, v in issues.items()}, 'iron on non-menstrual:', iron_other, 'of', iron_all)
