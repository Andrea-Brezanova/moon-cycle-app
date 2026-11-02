#!/usr/bin/env python3
"""Wave 1 "How to eat it" review: every suggestion read against the stated serving,
the preparation state of the USDA record and the profile's cautions.

    python3 docs/food-profiles/wave1_howto_review.py

Writes wave-1-howto-review.md and wave-1-review.html (one self-contained page, no network).
Read-only for the profiles: it publishes nothing and records no reviewer.

Two layers, kept separate on purpose:
  * AUTOMATED: rule checks that find candidates (serving state vs method, safety words,
    other allergens named in a suggestion).
  * HUMAN READING (FINDINGS below): every one of the 98 lines was read by Claude on
    2026-11-01; the entries below are the ones that need an owner/reviewer decision.
    This is an editorial first pass, not a clinical or dietetic sign-off.
"""
import html, json, re

R = 'docs/food-profiles/'
cand = json.load(open(R + 'wave-1-candidate.json'))['profiles']
foods = {f['id']: f for f in json.load(open('assets/content/foods.json'))['foods']}

# ---- Findings from reading each line (id -> (severity, issue, proposed wording or action)) ----
# severity: EDIT = wording should change before publishing; CHECK = needs a human fact check;
# NOTE = informational, no change needed unless the reviewer wants one.
FINDINGS = {
    'bean-sprouts': ('EDIT', 'Suggests raw sprouts in salads and spring rolls; the caution (FDA: avoid raw sprouts if at greater risk of foodborne illness) is separate and easy to miss.',
                     'Cook sprouts thoroughly if you are pregnant, older or have a weakened immune system. Add them to stir-fries and noodle dishes at the end of cooking, or to salads and spring rolls if you are not at greater risk.'),
    'green-pea': ('EDIT', '"or eat from the freezer, lightly cooked" is ambiguous and can read as eating frozen peas without cooking.',
                  'Replace with: "...or cook from frozen until hot through."'),
    'mackerel': ('EDIT', '"serve smoked in salads and on toast" suggests ready-to-eat smoked fish. Refrigerated smoked fish is a listeria concern for people at greater risk (FDA advice for pregnancy); the shown serving is cooked, not smoked.',
                 'Grill, bake or pan-fry with lemon. (Remove the smoked suggestion, or add that smoked fish is not advised if you are at greater risk of foodborne illness.)'),
    'haddock': ('EDIT', '"poach in milk" brings in milk, but the profile carries only the fish allergen caution.',
                'Bake or poach in stock or water, pan-fry, or use in fish pie and chowder. (If milk is kept, say "milk (dairy allergen)".)'),
    'blueberry': ('CHECK', '"Frozen berries work well in cooking and smoothies": frozen berries are a known hepatitis A source and some authorities advise heating them for people at greater risk. The FDA/CDC wording was not fetched in this pass.',
                  'Reviewer to confirm current official advice; either keep, or add "cook frozen berries if you are at greater risk of foodborne illness".'),
    'strawberry': ('CHECK', 'Same frozen-berry point as blueberry.', 'As blueberry.'),
    'mango': ('CHECK', '"Frozen mango works well for blending" (uncooked frozen fruit): same food-safety question as frozen berries; not verified.', 'As blueberry.'),
    'cabbage': ('NOTE', 'Shown serving is cooked; the first suggestion is raw (nutrient amounts are for cooked).', 'Optional: say "the figures are for cooked cabbage".'),
    'brussels-sprouts': ('NOTE', 'Shown serving is cooked; one suggestion is raw shredded.', 'As cabbage.'),
    'kale': ('NOTE', 'Shown serving is cooked; one suggestion is raw massaged leaves.', 'As cabbage.'),
    'beets': ('NOTE', 'Shown serving is cooked; one suggestion is grated raw.', 'As cabbage.'),
}

COOK = re.compile(r'\b(roast|bake|baked|simmer|boil|steam|braise|grill|stir-fry|saut[eé]|pan-fry|poach|stew|fry|toast)\b', re.I)
RAW = re.compile(r'\braw\b|\bfresh\b|\bwithout cooking\b', re.I)
ALLERGEN_WORDS = {
    'dairy': r'\b(milk|butter|cheese|yoghurt|yogurt|cream|sour cream|ghee)\b',
    'egg': r'\b(egg|eggs|mayonnaise)\b',
    'gluten': r'\b(bread|pasta|pizza|toast|noodle|noodles|muffins|pancakes|cakes|couscous|lasagne|tacos|burritos|wraps)\b',
    'fish': r'\b(anchov\w*|fish|sardine\w*)\b',
    'tree-nut': r'\b(nut|nuts|nut butter|almond|walnut|peanut|pesto)\b',
    'soy': r'\b(soy|tofu)\b',
}
SAFETY = re.compile(r'\b(raw|undercooked|rare|smoked|unpasteuri[sz]ed|frozen|sprout)\b', re.I)


def allergen_tags(fid):
    f = foods.get(fid, {})
    return {t.lower() for t in (f.get('allergens') or [])}


rows = []
for fid, p in cand.items():
    how = p['sections']['howToEatIt']
    src = p['source']
    prep = src['preparationState'].lower()
    cooked_serving = bool(re.search(r'cooked|boiled|roasted|baked|canned|dry roasted|drained', prep))
    auto = []
    if cooked_serving and RAW.search(how) and not re.search(r'frozen|canned', prep):
        auto.append('Serving is cooked; a suggestion is raw/fresh.')
    if (not cooked_serving) and COOK.search(how) and 'raw' in prep:
        auto.append('Serving is raw; a suggestion is cooked (figures are for raw).')
    sm = sorted(set(m.group(0).lower() for m in SAFETY.finditer(how)))
    if sm:
        auto.append('Safety word in suggestion: ' + ', '.join(sm))
    others = []
    tags = allergen_tags(fid)
    for label, rx in ALLERGEN_WORDS.items():
        if re.search(rx, how, re.I):
            if label not in tags and not (label == 'tree-nut' and 'peanut' in tags):
                others.append(label)
    if others:
        auto.append('Names another allergen: ' + ', '.join(others))
    sev, issue, prop = FINDINGS.get(fid, ('', '', ''))
    rows.append(dict(id=fid, name=p['name'], serving=src['portion'], prep=src['preparationState'], how=how,
                     cautions=[c['text'] for c in p['cautions']], auto=auto, sev=sev, issue=issue, prop=prop))

edit = [r for r in rows if r['sev'] == 'EDIT']
check = [r for r in rows if r['sev'] == 'CHECK']
note = [r for r in rows if r['sev'] == 'NOTE']
clean = [r for r in rows if not r['sev']]
cross = [r for r in rows if any(a.startswith('Names another allergen') for a in r['auto']) and not r['sev']]

md = ['# Wave 1: "How to eat it" review (98 profiles)', '',
      'Status: **unpublished, no reviewer recorded.** Generated by `wave1_howto_review.py` from `wave-1-candidate.json`.',
      'Every suggestion was read against the stated serving, the USDA preparation state and the profile cautions (2026-11-01, Claude). '
      'This is an editorial first pass for the human reviewer; it is not clinical or dietetic sign-off and names no reviewer.', '',
      f'**Result: {len(edit)} wording edits proposed, {len(check)} facts to confirm, {len(note)} notes, {len(clean)} with no finding.** '
      'No profile was changed by this pass.', '']
def table(title, items, cols):
    out = [f'## {title}', '']
    if not items:
        return out + ['None.', '']
    out += ['| Food | Issue | Proposed |', '|---|---|---|']
    for r in items:
        out.append(f"| {r['name']} (`{r['id']}`) | {r['issue']} | {r['prop']} |")
    return out + ['']
md += table('A. Proposed wording edits (reviewer decides)', edit, 3)
md += table('B. Facts to confirm before publishing', check, 3)
md += table('C. Notes (no change needed unless the reviewer wants one)', note, 3)
md += ['## D. Cross-allergen mentions (one policy decision, not 98 edits)', '',
       'Suggestions that name a pairing containing an allergen not tagged on that food (for example yoghurt on a fruit). '
       'These are optional pairings, but the app shows allergen warnings only for the food itself. Decision for the owner: keep as is, or add one line to the food-profile footer "Suggestions may include other allergens; check labels."', '',
       ', '.join(f"{r['name']}" for r in cross) or 'None.', '',
       '## E. What was checked on every profile', '',
       '- Suggestion vs serving quantity: no suggestion contradicts a stated amount (the only quantities named, "a third of a fruit" for avocado and "twice its volume of water" for quinoa, match the servings).',
       '- Suggestion vs preparation state: 4 foods show a cooked serving with a raw suggestion (C above) and raw-serving foods with cooked suggestions are normal variety; no nutrient figure is claimed for a different state.',
       '- Safety: dried kidney beans (soak and boil, no slow cooker), meat/poultry/fish temperatures, pasteurised cheese, raw sprouts, vitamin K, mercury, oxalate and allergens are all carried as cautions with a source. The gaps are in A and B.',
       '- Not checked: current official wording of external advice (B); a dietitian\'s view of portion realism.', '']
open(R + 'wave-1-howto-review.md', 'w').write('\n'.join(md))

# ---- compact HTML ----
def card(r):
    cls = {'EDIT': 'edit', 'CHECK': 'check', 'NOTE': 'note'}.get(r['sev'], 'ok')
    bits = [f"<h3>{html.escape(r['name'])} <span class='tag {cls}'>{r['sev'] or 'no finding'}</span></h3>",
            f"<p class='m'>Serving: {html.escape(r['serving'])} · {html.escape(r['prep'])}</p>",
            f"<p>{html.escape(r['how'])}</p>"]
    if r['cautions']:
        bits.append('<p class="m">Cautions: ' + html.escape(' · '.join(r['cautions'])) + '</p>')
    if r['issue']:
        bits.append(f"<p class='issue'><b>Issue:</b> {html.escape(r['issue'])}<br><b>Proposed:</b> {html.escape(r['prop'])}</p>")
    elif r['auto']:
        bits.append('<p class="m">Automated notes: ' + html.escape('; '.join(r['auto'])) + '</p>')
    return f"<article data-n='{html.escape((r['name']+' '+r['id']).lower())}'>" + ''.join(bits) + '</article>'

page = f"""<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Wave 1 review</title><style>
:root{{--bg:#faf7f2;--fg:#2b2530;--mut:#6d6573;--card:#fff;--ln:#e6dfd6;--edit:#b3261e;--check:#8a5a00;--note:#4a5d8a;--ok:#2e6b3f}}
@media(prefers-color-scheme:dark){{:root{{--bg:#1c1920;--fg:#efeaf2;--mut:#aaa2b0;--card:#26222b;--ln:#3a343f;--edit:#ff8a80;--check:#ffd180;--note:#9db4ff;--ok:#8fd19e}}}}
body{{margin:0;background:var(--bg);color:var(--fg);font:16px/1.45 system-ui,sans-serif;padding:16px;max-width:860px;margin-inline:auto}}
h1{{font-size:1.4rem}}h2{{font-size:1.1rem;margin-top:28px}}h3{{font-size:1rem;margin:0 0 4px}}
article{{background:var(--card);border:1px solid var(--ln);border-radius:12px;padding:12px 14px;margin:10px 0}}
.m{{color:var(--mut);font-size:.9rem;margin:4px 0}}.issue{{border-left:3px solid var(--edit);padding-left:10px;margin:8px 0 0}}
.tag{{font-size:.72rem;border:1px solid currentColor;border-radius:999px;padding:1px 8px;margin-left:6px}}
.edit{{color:var(--edit)}}.check{{color:var(--check)}}.note{{color:var(--note)}}.ok{{color:var(--ok)}}
input{{width:100%;box-sizing:border-box;padding:10px;font-size:1rem;border:1px solid var(--ln);border-radius:10px;background:var(--card);color:var(--fg)}}
</style></head><body>
<h1>Wave 1: "How to eat it" review</h1>
<p class="m">98 profiles · unpublished · no reviewer recorded. Editorial first pass, not clinical sign-off.<br>
{len(edit)} edits proposed · {len(check)} facts to confirm · {len(note)} notes · {len(clean)} no finding.</p>
<input id="q" placeholder="Filter by food name" aria-label="Filter by food name">
<h2>Flagged ({len(edit)+len(check)+len(note)})</h2>
{''.join(card(r) for r in edit+check+note)}
<h2>No finding ({len(clean)})</h2>
{''.join(card(r) for r in clean)}
<script>document.getElementById('q').addEventListener('input',function(e){{var v=e.target.value.toLowerCase();document.querySelectorAll('article').forEach(function(a){{a.style.display=a.dataset.n.indexOf(v)<0?'none':''}})}})</script>
</body></html>"""
open(R + 'wave-1-review.html', 'w').write(page)
print(len(rows), 'profiles;', len(edit), 'edit', len(check), 'check', len(note), 'note', len(clean), 'clean;', len(cross), 'cross-allergen')
