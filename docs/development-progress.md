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

## Also merged and installed

| Feature | PR | CI | Stage |
|---|---|---|---|
| Food Detail profiles for the five reference foods (spinach cooked, lentils cooked, pumpkin seed kernels dried, broccoli cooked, orange raw) | #36 | green | 4 merged (5c25667); 5 installed (built 25 Oct 2026 23:00 UTC with tool/build_ios.sh; check Me › Settings › About) |

## Open PRs (reviewed 25 Oct 2026)

| PR | What it is | Stage | State against `main` | Decision |
|---|---|---|---|---|
| #28 | Food content audit and the five reference profiles (documents) | 2 documentation | **Already merged as a side effect**: GitHub marked it merged when #36's merge brought all its commits into `main` (not merged on purpose; docs only, no app change) | nothing to do; its final editorial review is covered by the approved five profiles |
| #33 | Draft preview of a profile inside Food Detail | 3 draft code | superseded: its code and goldens are in `main` through #36 | left open as a draft, not merged, not closed |
| #25 | Food photo manifest | 2 documentation | identical files are already in `main` (carried in by #26) | redundant; left open, not closed |
| #16 | iPhone install workflow, V2 status, TestFlight readiness | 2 documentation | 88 commits behind; its roadmap edits and TestFlight notes are stale (TestFlight is deferred; the install workflow now lives in `docs/feature-status.md` and `tool/build_ios.sh`) | **not merged**; left open for you to decide |

## Needs your approval

- Anything needing a new migration (Spa sub-categories, workout metadata), new content
  (workouts, meditations, audio), image licensing or any further profile beyond the five.
- Whether to close the superseded PRs (#16, #25, #33); I have not closed or deleted anything.

## Not implemented (do not expect on the phone)

Food photography beyond the 3 original photos (manifest only); Move and Relax hubs
(placeholders; proposal merged); profiles for the other 137 foods.
