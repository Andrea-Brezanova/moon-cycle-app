# App quality, accessibility, data-integrity and privacy audit (1 Nov 2026)

Method: code reading of the current `main` (80ada44 plus later merges), the existing 1,100+ tests and goldens, new automated checks (below), and a live walk through Eat › Foods › Food Detail on the iOS Simulator. **Implemented** = merged or in an open PR; **Proposal** = needs your decision; **Not verified** = not checked here.

## 1. Defects found and corrected
| Finding | Where | Action |
|---|---|---|
| Four "Why this food?" lines stated iron percentages that did not match the verified serving (oyster 37% vs 21%, sardine 11% vs 15%, quinoa 12% vs 8%, anchovies 22% vs 5%) and five tied a food to a phase | `foods.json` | **Implemented** (PR #79): rewritten, each figure verified against the live USDA record; guard tests. |
| The phase pill said "Recommended for your {phase} phase" on every featured food | `taxonomy.json` | **Implemented** (PR #79): "Explore this food". |
| The Wave 1 checker could not catch a regex precedence bug and a rounding artifact | my own new script | Fixed before use; mutation-tested. |
No other reproducible functional defect was found in the audited flows. **Not verified:** a full manual VoiceOver pass, long-running soak behaviour, and every dark-mode screen.

## 2. Confusing or unsupported claims still in the UI (Proposal, not changed)
These are production microcopy; they read as phase-support claims. Proposed neutral wording keeps the brand voice.
| Text | File | Proposed |
|---|---|---|
| "Seasonal foods, simple recipes and meal ideas to support your current phase." | `eat_page.dart` | "…meal ideas featured for your current phase." |
| "Three plants chosen for your phase today." | `home_page.dart` | "Three plants featured in your phase today." |
| "Browse foods by phase and benefit." | `eat_page.dart` | "Browse foods by phase and category." |
| "How to eat this phase" (a cooking-style note) | `phase_intro.dart` | "Cooking ideas for this phase" |
| Phase taglines "energising", "restorative" | `phases.json` | Keep or soften (editorial mood words, no nutrition claim). |
| Detailed reminder: "See the foods for this phase in Moon Cycle." | `reminder_copy.dart` | Acceptable; it only points to featured foods. |
Also: `proteinIdeasProvider` demotes "heavy meats" in the follicular and ovulatory phases and lists featured foods first, and `RecipeMatcher` adds a phase bonus. Neither shows a claim, but both order food by phase with no research behind it (see `docs/build-a-meal-2.md`, section 7).

## 3. Accessibility
Existing and new automated checks (iOS tap targets, labelled targets, text contrast, 320 pt at 1.5× text) now cover **40+ screens** including Food Detail with and without a reviewed profile, Foods, Build a Meal, Eat recipes, the collections and the diary sub-pages (PR #82). No defects. Reduced motion: the app has no looping or auto-playing animation (a toggle and a press-fade only), so exposure is minimal. **Proposals / not verified:** a manual VoiceOver and Dynamic Type pass on the phone; dark-mode contrast tests per screen; the Food Detail page is long at large text sizes (consider section jump links); the Home orbit hero's semantic description should be checked by a screen-reader user.

## 4. Data and content integrity
Existing tests already check: unique food ids, recipe foods resolve to ship-ready foods, allergen/aisle/diet metadata validity, conditional allergens, recipe/food links. **Added** (PR #81): staged profiles link to real ship-ready foods with matching names; catalogue allergens appear in profile cautions; every caution has a source; staged figures equal the draft dataset (no stale copy); table percentages follow the shown amounts; animal source and allergen tags agree across all 271 foods; plus the offline exception report (`wave-1-exception-report.md`, **no unresolved problems**). **Proposals:** a test that user data (shopping items, saved recipes, diary items) survives a removed catalogue id (the code handles a missing food as null in the shopping, diary and recipes screens, but no test pins it); recipe ingredient lines without a food id are ignored by Build a Meal matching (known limit).

## 5. Privacy and security
Verified by tests (existing plus PR #82): no backups on Android; exact permission list; only two iOS prompts; env files git-ignored; allow-listed network code; cloud generation unwired; external recipe lookups debug-only; crash settings scrubbed; export cleanup; no logging of user content; **shield defaults off, opaque cover, one channel, `FLAG_SECURE` scope, reset on Delete my data, no new permission or SDK**. The database is SQLCipher with a random 256-bit key in the Keychain (`first_unlock`: readable after first unlock for reminders; it can move to a new iPhone only inside an encrypted backup). Detailed reminders can show the phase or an estimated period date on a lock screen when the user turns them on. SQLite temp-store left unchanged (no exposure shown). **Proposal:** `first_unlock_this_device` if you prefer the key never to leave the phone (a backup restore would then need re-setup: data loss risk, so owner decision). **Not verified:** a live check of Delete my data on the phone.

## 6. Tests added in this session
PR #79 guard tests (why-copy, heading, pill, credits, phases), `test/features/meal_balance/` (19), `test/content/wave1_staging_integrity_test.dart` (5), `test/a11y/coverage_accessibility_test.dart` (30), `test/privacy/privacy_shield_posture_test.dart` (7), `test/features/credits/credits_page_test.dart` (1).
