# Development progress

One report, kept current. **Stage** means exactly one of: 1 Mockup, 2 Documentation,
3 Unmerged Flutter code, 4 Merged into `main`, 5 Installed on the iPhone. A feature is
only "done" at the stage stated; documentation and previews are not features.

Last updated: 25 Oct 2026. `main` at the time of writing: see the About screen on the
phone (Me › Settings › About) for what is installed.

## Done and merged

| Feature | PR | CI | Stage |
|---|---|---|---|
| Me page (four rows), Settings and Account & Plus pages | #31 | green | 4 merged; 5 installed |
| My Collections (landing, My Recipes, My Workouts, My Spa, saved links, details, filters; schema v9) | #19, #23, #27, #30 | green | 4 merged; 5 installed |
| My Recipes filter dropdown; Add a recipe with an Add a link tab | #32 | green | 4 merged; 5 installed |
| Home "Your space", Today's Focus text and headlines, MoonCycle name and icon | #20, #21, #22, #29 | green | 4 merged; 5 installed |
| About screen (version, build number, commit, build date, flavor) | #34 | green | 4 merged; 5 installed (shows 4ec4471 when installed) |
| Meal Builder free for everyone, production builds included | #35 | green | 4 merged (5eeb813); 5 installed from tool/build_ios.sh |
| Dev-only Premium test switch (`DEV_PREMIUM`) | #24 | green | 4 merged; testing aid only |

## In progress

| Feature | PR | CI | Stage |
|---|---|---|---|
| Food Detail profiles for the five reference foods (spinach, lentils, pumpkin seeds, broccoli, orange) | this PR | see PR | 3 unmerged Flutter code until merged |

## Open PRs (reviewed)

| PR | What it is | Stage | In `main`? | Decision |
|---|---|---|---|---|
| #28 | Food content audit and the five reference profiles (documents) | 2 documentation | no; its content is carried into the profiles PR | keep open for final editorial review |
| #33 | Draft preview of a profile inside Food Detail | 3 draft code | superseded by the profiles PR (same code) | keep as a draft; not merged |
| #25 | Food photo manifest | 2 documentation | **yes** (carried in by #26's stacked branch) | content already in main; left open, not closed |
| #16 | iPhone install workflow, V2 status, TestFlight readiness | 2 documentation | partly (feature-status covers the install workflow) | left open |

## Needs your approval

- Anything needing a new migration (Spa sub-categories, workout metadata), new content
  (workouts, meditations, audio), image licensing or any further profile beyond the five.
- Final editorial review of #28.

## Not implemented (do not expect on the phone)

Food photography beyond the 3 original photos (manifest only); Move and Relax hubs
(placeholders; proposal merged); profiles for the other 137 foods.
