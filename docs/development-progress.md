# Development progress

One report, kept current. **Stage** means exactly one of: 1 Mockup, 2 Documentation,
3 Unmerged Flutter code, 4 Merged into `main`, 5 Installed on the iPhone. A feature is
only "done" at the stage stated; documentation and previews are not features.

Last updated: 26 Oct 2026. `main` was at 3700800 (PR #41) when the Stage 1-8 work below was
merged. The commit actually installed is shown on Me › About.

## Done and merged

| Feature | PR | CI | Stage |
|---|---|---|---|
| Me page: four sections (Your space / Your app / Your account / Support); My Cycle, Food Preferences and Allergies under Personalization; Delete my data under Privacy & Data (Stage 1) | #39 | green | 4 merged (0a61edf); 5 installed |
| My Collections: four equal square tiles (My Recipes, My Workouts, My Spa, My Routines) (Stage 2); My Routines page is an honest "not available yet" until the migration is approved | #40 | green | 4 merged (f99e9e6); 5 installed (f99e9e6, built 26 Oct 2026 22:24 UTC) |
| Move hub (Exercises, Workouts, Build Your Routine, My Workouts) and Relax hub (Meditations, Sounds, Spa, My Spa): navigation, library and item pages, safety note, source attribution, Save to My Workouts / My Spa for verified links; **no approved content yet** (Stages 6, 7) | #41 | green | 4 merged (3700800); 5 installed (3700800, built 26 Oct 2026 22:51 UTC; the binary contains that commit; the phone screen was not inspected by me) |
| My Collections (landing, My Recipes, My Workouts, My Spa, saved links, details, filters; schema v9) | #19, #23, #27, #30 | green | 4 merged; 5 installed |
| My Recipes filter dropdown; Add a recipe with an Add a link tab | #32 | green | 4 merged; 5 installed |
| Home "Your space", Today's Focus text and headlines, MoonCycle name and icon | #20, #21, #22, #29 | green | 4 merged; 5 installed |
| About screen (version, build number, commit, build date, flavor) | #34 | green | 4 merged; 5 installed (shows 4ec4471 when installed) |
| Meal Builder free for everyone, production builds included | #35 | green | 4 merged (5eeb813); 5 installed from tool/build_ios.sh |
| Dev-only Premium test switch (`DEV_PREMIUM`) | #24 | green | 4 merged; testing aid only |

## Also merged and installed

| Feature | PR | CI | Stage |
|---|---|---|---|
| Food Detail profiles for the five reference foods (spinach cooked, lentils cooked, pumpkin seed kernels dried, broccoli cooked, orange raw) | #36 | green | 4 merged (5c25667); 5 installed (built 25 Oct 2026 23:00 UTC with tool/build_ios.sh; check Me › Settings › About) |

## Stage results (autonomous run, 26 Oct 2026)

| Stage | Result |
|---|---|
| 1 Me page | Done, merged (#39). |
| 2 My Collections | Four equal tiles merged (#40). **My Routines storage is blocked on your approval**: proposal in `docs/my-routines-migration-proposal.md`; implementation is **draft PR #42** (schema v10, migration test, repository), not merged. No My Routines screens until approved. |
| 3 Bugs | Verified on `main`, no code change needed, no PR opened: recipe delete (trash on your own recipe cards, with confirmation; un-favoriting never deletes), Home bottom spacing, Meal Builder free and needs only one food (no mandatory protein/base/plant step, search first), 3 Plants rotation (tests cover day boundary, phase change, 24/28/35-day cycles, late period, exclusions, determinism, no consecutive repeats; not reproducible). Please tell me dates if you still see repeats. |
| 4 Photography | **Blocked: no authorised image-generation or licensed-asset tool in this environment**, so no image was made or added. Ready: `docs/food-photo-manifest.json` (161 foods in batches of 12 with briefs, file names = food ids, 1200 px square JPEG), `docs/food-photo-audit-v2.md`. Integration after you supply reviewed images: add the file under `assets/images/foods/`, add the id to `plant_photos.dart`, add credit. |
| 5 Food Detail profiles | The five approved profiles are unchanged (their values are recomputed from USDA records by tests). The other 137 foods are queued in `docs/food-profiles/work-queue.json` (status `queued`); none researched or published yet. Needs your editorial review of any draft before it can be bundled. |
| 6 Move | Hub merged (#41). Libraries are empty by design until content is approved; draft proposals (not bundled) in `docs/content-drafts/hub-content-drafts.json` need professional/editorial review. |
| 7 Relax | Hub merged (#41); no audio or content published; drafts as above (spa rituals carry no detox/hormone claims). |
| 8 QA | CI green on every merged PR (format/analyze/layers/tests, goldens on macOS, Android build). Not done: a full manual pass on the phone, and testing with real data (no destructive tests were run against the phone's data). |

## Open PRs (reviewed 26 Oct 2026)

| PR | What it is | Stage | State against `main` | Decision |
|---|---|---|---|---|
| #42 | My Routines schema v10, migration test, repository | 3 draft code | draft, not merged | **waiting for your migration approval** |
| #38 | Draft Move/Relax hubs (saved items and Save a Link only) | 3 draft code | superseded by #41 (merged), which has the full hub architecture | left open as a draft, not merged, not closed |
| #28 | Food content audit and the five reference profiles (documents) | 2 documentation | **Already merged as a side effect**: GitHub marked it merged when #36's merge brought all its commits into `main` (not merged on purpose; docs only, no app change) | nothing to do; its final editorial review is covered by the approved five profiles |
| #33 | Draft preview of a profile inside Food Detail | 3 draft code | superseded: its code and goldens are in `main` through #36 | left open as a draft, not merged, not closed |
| #25 | Food photo manifest | 2 documentation | identical files are already in `main` (carried in by #26) | redundant; left open, not closed |
| #16 | iPhone install workflow, V2 status, TestFlight readiness | 2 documentation | 88 commits behind; its roadmap edits and TestFlight notes are stale (TestFlight is deferred; the install workflow now lives in `docs/feature-status.md` and `tool/build_ios.sh`) | **not merged**; left open for you to decide |

## Needs your approval

- **Schema v10 for My Routines (draft #42).**
- Anything else needing a new migration (Spa sub-categories, workout metadata), new content
  (workouts, meditations, audio), image licensing or any further profile beyond the five.
- Whether to close the superseded PRs (#16, #25, #33); I have not closed or deleted anything.

## Not implemented (do not expect on the phone)

Food photography beyond the 3 original photos (blocked, manifest only); any Move or Relax
content (libraries are empty until reviewed); My Routines screens (waiting on migration
approval, draft #42); profiles for the other 137 foods.
