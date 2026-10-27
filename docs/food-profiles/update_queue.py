"""Marks every food that has a draft profile as drafted in work-queue.json.

Run from the repo root after building a batch: python3 docs/food-profiles/update_queue.py
Reads draft-batch-*.json (and batch-*.src.json for review notes); nothing is published.
"""
import glob, json, re

q = json.load(open('docs/food-profiles/work-queue.json'))
drafted = {}
for path in sorted(glob.glob('docs/food-profiles/draft-batch-*.json')):
    n = re.search(r'draft-batch-(\d+)\.json', path).group(1)
    src = {}
    try:
        src = json.load(open(f'docs/food-profiles/batch-{n}.src.json'))['foods']
    except FileNotFoundError:
        pass
    for fid, p in json.load(open(path))['profiles'].items():
        drafted[fid] = (n, p['source'], src.get(fid, {}).get('reviewNote'))
for i in q['items']:
    if i['foodId'] in drafted:
        n, s, note = drafted[i['foodId']]
        i['status'] = f'drafted (batch {n})'
        i['usdaFdcId'] = s['usdaFdcId']
        i['preparationState'] = s['preparationState']
        i['notes'] = f'Draft in draft-batch-{n}.json. Not published.' + (f' REVIEW: {note}' if note else '')
json.dump(q, open('docs/food-profiles/work-queue.json', 'w'), indent=1, ensure_ascii=False)
done = sum(1 for i in q['items'] if i['status'].startswith('drafted'))
print(f'{done} drafted, {len(q["items"]) - done} queued (of {len(q["items"])} phase-assigned foods without an approved profile)')
