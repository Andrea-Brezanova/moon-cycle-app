#!/usr/bin/env python3
"""Applies the nine owner-approved "Why this food?" rewrites to assets/content/foods.json (1 Nov 2026).

Replaces the exact old sentence in `short` and `detail` of exactly nine entries and nothing else; phase assignments
(the `why` keys and each food's `featuredPhases`) are untouched. Writes why-this-food-rewrites.json, the permanent
before/after record. Run once from the repo root, after audit_why_this_food.py has run against the OLD catalogue."""
import json, re

R = 'docs/food-profiles/'
audit = json.load(open(R + 'why-this-food-audit.json'))['foods']
rows = [r for r in audit if r['needsChange']]
assert len(rows) == 9, len(rows)
text = open('assets/content/foods.json').read()
foods = {f['id']: f for f in json.loads(text)['foods']}
TAIL = {'anchovies': ' A few go a long way in pasta, salads or on toast.'}
record = []
for r in rows:
    w = foods[r['id']]['why'][r['phase']]
    new_short = r['proposedReplacement']
    new_detail = new_short + TAIL.get(r['id'], '')
    assert w['short'] == r['text'], r['id']
    for old, new in ((w['detail'], new_detail), (w['short'], new_short)):
        old_j, new_j = json.dumps(old, ensure_ascii=False), json.dumps(new, ensure_ascii=False)
        if old_j in text:
            text = text.replace(old_j, new_j)
    record.append(dict(id=r['id'], phase=r['phase'], shortBefore=w['short'], shortAfter=new_short, detailBefore=w['detail'], detailAfter=new_detail))
open('assets/content/foods.json', 'w').write(text)
after = {f['id']: f for f in json.loads(text)['foods']}
for rec in record:
    w = after[rec['id']]['why'][rec['phase']]
    assert w['short'] == rec['shortAfter'] and w['detail'] == rec['detailAfter'], rec['id']
json.dump(dict(_about='Before/after of the nine "Why this food?" lines changed on 1 Nov 2026 (owner-approved direction). Phase assignments unchanged.', rewrites=record),
          open(R + 'why-this-food-rewrites.json', 'w'), indent=1, ensure_ascii=False)
print('applied', len(record))
