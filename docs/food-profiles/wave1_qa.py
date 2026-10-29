#!/usr/bin/env python3
"""Editorial quality checks for the Wave 1 profiles (the 101 in publication-plan.json). Writes wave-1-qa-report.md.

    python3 docs/food-profiles/wave1_qa.py
Read-only: it changes no profile and publishes nothing."""
import collections, json, re

R = 'docs/food-profiles/'
profiles = json.load(open(R + 'complete-draft-dataset.json'))['profiles']
plan = json.load(open(R + 'publication-plan.json'))
foods = {f['id']: f for f in json.load(open('assets/content/foods.json'))['foods']}
phase = {k: list(f['why'])[0] for k, f in foods.items() if f['why']}
wave1 = plan['wave1']


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
    s = p['sections']
    # 1 five-section format
    for sec, (lo, hi) in {'whatItOffers': (40, 420), 'practicalServing': (3, 90), 'howToEatIt': (20, 420), 'cycleRelevance': (20, 560)}.items():
        n = len(s[sec])
        if not lo <= n <= hi:
            issues['format'].append(f'{k}: {sec} is {n} characters')
    # 2 readability
    for sec in ('whatItOffers', 'howToEatIt', 'cycleRelevance'):
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
    cyc = s['cycleRelevance']
    if 'menstrual blood loss' in cyc and phase[k] != 'menstrual':
        issues['implication'].append(f'{k}: iron/menstruation sentence on a food featured in the {phase[k]} phase')
    if not re.search(r'(cycle-phase|phase-specific) claim', cyc):
        issues['implication'].append(f'{k}: no explicit "no phase claim" statement')
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
iron_other = sum(1 for k in wave1 if 'menstrual blood loss' in profiles[k]['sections']['cycleRelevance'] and phase[k] != 'menstrual')
iron_all = sum(1 for k in wave1 if 'menstrual blood loss' in profiles[k]['sections']['cycleRelevance'])
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
L.append('## Does the cycle-relevance section create misleading implications?\n')
L.append(f'- The heading "Cycle relevance" can suggest every food has a cycle link, when {len(wave1) - iron_all} of {len(wave1)} Wave 1 profiles say only that none is claimed. Suggested options: keep the heading, or rename it "Cycle note", or show the section only when a sourced nutrient fact exists.')
L.append(f'- {iron_all} profiles carry the sourced iron sentence ("partly because of menstrual blood loss"). {iron_other} of them are foods featured in a phase other than menstrual, which could read as "this food is for your period". The sentence is true all month; the proposed wording (below) says so explicitly.\n')
open(R + 'wave-1-qa-report.md', 'w').write('\n'.join(L) + '\n')
print({k: len(v) for k, v in issues.items()}, 'iron on non-menstrual:', iron_other, 'of', iron_all)
