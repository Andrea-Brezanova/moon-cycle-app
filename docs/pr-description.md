# Draft PR: title and description

**Compare URL (create as a DRAFT):**
https://github.com/Andrea-Brezanova/moon-cycle-app/compare/main...feature/home-choices-food-detail?expand=1

**Title:** Home, Eat and navigation redesign; My Diary with symptoms (schema 6); meal reuse; recipe providers; CI

**Description (paste below):**

---

## Summary
A long-running feature branch (about 75 commits, ~670 files) brought into `main`
in one reviewed step. Nothing here deploys anything; providers and Premium
features stay off or gated as before.

### Home and navigation
- Home below "Your focus" rebuilt as the approved Editorial layout: **3 plants a day** (square photo tiles, curated Broccoli/Avocado/Blueberry photos, emoji
  fallback for the other plants, daily pick unchanged), **Build a meal** card, and **Go to** cards (Shopping list, Log diary).
- Tabs are now **Home · Eat · Move · Relax · More**. Eat combines Foods and Recipes
  (state kept when switching) with a phase pill and a "Browse by phase" sheet and
  a floating Build a meal button. Move and Relax are "Coming soon" pages.
  More holds My Diary, Shopping list, settings and **Credits & Sources**.
- Routes moved under `/eat` and `/more`; recipe and food detail keep working.

### My Diary and symptoms
- Approved My Diary: date bar with phase and cycle day, Meals / Symptoms tabs,
  Log a meal and Log symptoms forms, edit, delete with confirmation, history.
- Symptoms: energy, moods, body symptoms with optional strength (bleeding has its
  own scale), sleep, note; closed vocabulary, no interpretation or scoring.
- **Basic diary is Free** (entitlement change); Premium infrastructure and Build a
  meal's Premium rule are unchanged.

### Meal discovery and reuse
- "Recently logged" (a view of the diary history, nothing new stored), "Browse all
  foods" (every category, all phases, search) and ranked search across the whole
  catalogue, recipes and typed meals, tolerant of one typo and of synonyms
  ("Romaine lettuce" finds Lettuce).

### Recipe integrations (all off by default)
- Multi-provider discovery: TheMealDB (development builds only), Recipe API
  adapter (corrected against real responses, not enabled), dedupe, budgets and
  rate limits, saved references. Ingredient vocabulary with allergen and diet
  safeguards (unidentified ingredients never assumed safe). Local-only Supabase
  proxy and migration; no hosted change.
- Wheat flour now carries the gluten allergen.

### Shopping list
- Food detail's button reflects the stored list ("Add" / "Remove from shopping
  list"), including after reopening and restart.

### Accessibility
- Large-text fixes on Home, the diary forms and the Meals/Symptoms switch;
  saved toast at the top; stacked form header at large text.

## Database migration (schema 5 to 6, local only)
Additive: nullable `diary_entries.note`, a `custom` meal kind, and a new
`symptom_checkins` table with a unique live index. Migrations now run step by
step against versioned schemas. Verified with a populated v5 database
(`test/core/database/diary_v6_migration_test.dart`) and every older version
upgrade. See `docs/diary-schema-v6.md`.

## Tests (last full local run, then targeted runs since)
- Non-golden: 939 passed (before the final meal-discovery work; since then the
  affected suites pass: diary, home, foods, recipes, entitlements).
- Golden: 135 passed locally.
- `flutter analyze`, `dart format --set-exit-if-changed .` and
  `tool/check_layers.dart` clean.
- GitHub Actions: see the checks on this PR (the golden job is advisory, below).

## Known limitations
- **Golden job on GitHub is advisory and currently fails** on every image by
  10 to 33 pixels because the references were recorded on macOS 15 and the runner
  was macOS 26 (`docs/golden-ci-diagnosis.md`). The job is now pinned to
  `macos-15`; a manual "Update goldens" workflow records proposals for review.
- Recipe API: a handful of free list calls only; coverage looks thin
  (`docs/external-recipe-api-evaluation.md`). TheMealDB production licensing is
  unresolved (`docs/themealdb-production-licensing.md`).
- Only 3 of 94 plant foods have photos (inventory in `docs/food-photo-inventory.md`).
- Move and Relax are placeholders.
- Past-day phase labels in the diary are estimates from the current cycle length.
- Hosted Supabase was never touched; nothing is deployed.

## Remaining before merge
1. The required checks green on this PR (format, analyze, layers, tests; Android).
2. Decide on the golden check (re-record on `macos-15` through the manual
   workflow, then make it required) or keep it advisory.
3. Your review of this PR.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
