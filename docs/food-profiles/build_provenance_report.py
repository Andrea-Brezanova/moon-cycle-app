#!/usr/bin/env python3
"""Builds the public phase-assignment provenance summary from the matrix (numbers are never typed by hand).
Run after phase_provenance_audit.py:  python3 docs/food-profiles/build_provenance_report.py"""
import json

R = 'docs/food-profiles/'
S = json.load(open(R + 'phase-assignment-provenance-summary.json'))
st = S['stages']
cc = S['classificationCounts']
L = []
w = L.append
w('# Food-to-phase assignments: provenance summary and limits\n')
w('**Documentation only. No phase mapping, catalogue entry or app behaviour was changed.** Machine-readable detail: `phase-assignment-provenance-matrix.json`.\n')
w('## What this document does and does not say\n')
w('- It records **when** each of the 142 food-to-phase assignments entered this repository and how it changed, from Git history.')
w('- It does **not** establish where the assignments originally came from. The earliest list pre-dates this repository and its source is not established here.')
w('- It does **not** say the assignments are independently sourced, legally cleared or scientifically validated. **None of those three is true of the current assignments**: no assignment has a documented independent source; no legal review has been done; and no reliable research shows that any food needs to be eaten in a particular phase.')
w('- The featured phase is an editorial suggestion for variety (the app says: "These are suggestions, not rules"), not a nutritional requirement.')
w('- The evidence base is this repository only. Other records exist outside it and are not reproduced here.\n')
w('## Timeline from Git\n')
w('| Date | Commit | Stage | Foods with a phase | Menstrual / follicular / ovulatory / luteal |\n|---|---|---|---|---|')
for c in ('56e981d', '8828f98', 'b2c071f', 'f9c0241', 'HEAD'):
    s = st[c]
    pp = s['perPhase']
    w(f'| {s["date"]} | `{s["commit"]}` | {s["label"]} | {s["assignedFoods"]} | {pp.get("menstrual")} / {pp.get("follicular")} / {pp.get("ovulatory")} / {pp.get("luteal")} |')
w('')
w('The current catalogue is identical to `f9c0241`. Later nutrient research (USDA and NIH) added descriptions only and changed no assignment.\n')
w('## The 142 current assignments\n')
w('| Group | Foods | Meaning |\n|---|---|---|')
w(f'| Kept from the earlier list | {cc["B"]} | Same phase as the earliest list in this repository. **Not independently established**: a later revision that kept them is not a second source. |')
w(f'| Changed from the earlier list | {cc["E"]} | Moved to a different phase. The reason is not recorded here. |')
w(f'| Not in the earlier list | {cc["D"]} | Added later. No rationale is recorded here. |')
w('| Independently documented | 0 | None. |\n')
w(f'{S["baselineFoodsNoLongerAssignedCount"]} foods in the earliest list no longer have a phase.\n')
w('## Scientific support\n')
w('For no food did I find reliable research showing a phase-specific nutritional requirement. What exists is general nutrition (for example, higher iron needs for people who menstruate, which apply all month) and some traditional or theoretical associations that have no clinical support. USDA nutrient composition alone is never treated as evidence for a phase.\n')
w('## Next steps\n')
w('1. An independent, documented method for deciding which foods to feature in which phase (proposed in a separate document for approval).')
w('2. Until that is approved, the existing mappings stay as they are and should be described to users only as suggestions.')
w('3. Anything about the origin of the earlier list is for the owner and, if wanted, a qualified adviser.\n')
open(R + 'phase-assignment-provenance-audit.md', 'w').write('\n'.join(L) + '\n')
print('written', len(L), 'lines')
