"""Marks every food that has a draft profile as drafted in work-queue.json.

Run from the repo root after building a batch: python3 docs/food-profiles/update_queue.py
Reads draft-batch-*.json (and batch-*.src.json for review notes); nothing is published.
"""
import glob, json, re

q = json.load(open('docs/food-profiles/work-queue.json'))
# Every catalogue food without an approved profile is tracked, phase-assigned or not.
approved = set(json.load(open('assets/content/food_profiles.json'))['profiles'])
have = {i['foodId'] for i in q['items']}
for f in json.load(open('assets/content/foods.json'))['foods']:
    if f['id'] not in approved and f['id'] not in have:
        q['items'].append({'foodId': f['id'], 'name': f['name'], 'phase': None, 'match': 'not phase-assigned', 'category': f.get('category'),
                           'status': 'queued', 'usdaFdcId': None, 'preparationState': None,
                           'notes': 'Not in the 142 phase-assigned foods; researched after them.'})
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
blocked = json.load(open('docs/food-profiles/blocked.json'))
for i in q['items']:
    if i['foodId'] in blocked:
        assert not i['status'].startswith('drafted'), i['foodId']
        i['status'] = 'blocked'
        i['notes'] = 'BLOCKED: ' + blocked[i['foodId']]
json.dump(q, open('docs/food-profiles/work-queue.json', 'w'), indent=1, ensure_ascii=False)
done = sum(1 for i in q['items'] if i['status'].startswith('drafted'))
nb = sum(1 for i in q['items'] if i['status'] == 'blocked')
print(f'{done} drafted, {nb} blocked, {len(q["items"]) - done - nb} still queued (of {len(q["items"])} catalogue foods without an approved profile)')
