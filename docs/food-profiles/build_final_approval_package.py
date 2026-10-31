"""Builds FINAL-APPROVAL-PACKAGE.md: one short page for the owner's decision. Run from the repo root."""
import json

R = 'docs/food-profiles/'
audit = json.load(open(R + 'why-this-food-audit.json'))['foods']
rows = [r for r in audit if r['needsChange']]
assert len(rows) == 9, len(rows)

L = ['# Wave 1: final editorial approval package\n',
     '**Nothing is published.** 98 profiles stay unpublished (`wave-1-candidate.json`, `publishable: false`); flax, sesame and sunflower seed stay on hold; no phase assignment changes. Details if you want them: `wave-1-approval-summary.md`, `wave-1-qa-report.md`, `why-this-food-audit.md`.\n',
     '## 1. Proposed wording (exact)\n',
     '- **Heading:** Nutrition & your cycle',
     '- **Iron (only where a serving gives 10% or more):** "Women aged 19 to 50 need 18 mg of iron a day (men: 8 mg), partly because of menstrual blood loss (NIH ODS). That need applies every day of the month, not only during a period. A serving of this food has about {x} mg."',
     '- **Closing (always; first sentence only where a serving gives a meaningful amount of a nutrient):** "This food provides nutrients that support general health. There is currently insufficient evidence to recommend eating this food during one particular menstrual phase."',
     '- **Badge:** "Featured for variety in the {phase} phase" instead of "Recommended for your {phase} phase".',
     '- **Label on every profile:** "Nutrition values checked against USDA and NIH sources; not clinically reviewed."\n',
     '## 2. Food Detail screenshots (real app rendering, unpublished)\n',
     '| Beef | Kale | Almond |', '|---|---|---|',
     '| ![Beef](wave-1-screens/beef.png) | ![Kale](wave-1-screens/kale.png) | ![Almond](wave-1-screens/almond.png) |',
     '| **Arugula** | **Sardine** | **Strawberry** |',
     '| ![Arugula](wave-1-screens/arugula.png) | ![Sardine](wave-1-screens/sardine.png) | ![Strawberry](wave-1-screens/strawberry.png) |\n',
     '## 3. The nine "Why this food?" rewrites (production copy today, phase assignments unchanged)\n',
     'Every figure was recomputed from the verified USDA serving (iron ÷ 18 mg reference). Each rewrite now names its serving.\n',
     '| Food (phase) | Today | Proposed | Why |', '|---|---|---|---|']
for r in rows:
    why = ('phase link removed' if r['kind'] == 'phase-link' else '"cooling" is a traditional claim' if r['kind'] == 'traditional' else 'tied to a phase')
    c = r['figureCheck']
    if c and not c['agrees']:
        why += f"; stated {c['statedPercent']}% but the serving ({c['profileServing']}) gives {c['profileIronPercent']}%"
    if r['id'] == 'banana':
        why = '"during the luteal phase" had no basis'
    L.append(f"| {r['name']} ({r['phase']}) | {r['text']} | {r['proposedReplacement']} | {why} |")
L += ['',
      '## 4. What a reviewer must still do',
      '- A real person reads the 98 profiles (or a sample you choose) and the nine rewrites against the cited sources.',
      '- Record **their real name and the actual date** in `review.approval` in `wave-1-candidate.json`. No credential is assigned or implied by me; a professional credential is recorded only if that person actually holds one and states it.',
      '- The label stays "not clinically reviewed" unless a qualified clinician actually reviews and says so.',
      '- Nothing is published until you say so.\n',
      '## 5. Your decisions (exact)',
      '1. Approve the wording in section 1, or amend it. Use the plainer closing ("There isn\'t enough evidence to recommend eating this food in one particular phase of your cycle.")? yes / no.',
      '2. Approve the badge change to "Featured for variety in the {phase} phase" (a production UI change plus golden updates at publication)? yes / no.',
      '3. Approve the nine rewrites in section 3 for production? yes / no / amend.',
      '4. Soften the phase copy in `phases.json` as listed in `why-this-food-audit.md`? yes / no.',
      '5. Who is the real reviewer, and on what date will the review take place or did it take place?',
      '6. Publish the 98 profiles (seed foods stay on hold)? Only on your explicit "publish".']
open(R + 'FINAL-APPROVAL-PACKAGE.md', 'w').write('\n'.join(L) + '\n')
print('written', len(rows), 'rewrites')
