# Development progress

One report, kept current. **Stage** means exactly one of: 1 Mockup, 2 Documentation,
3 Unmerged Flutter code, 4 Merged into `main`, 5 Installed on the iPhone. Bugs carry a
second, separate status: **Implemented, awaiting device verification** (passes automated
tests, not yet checked by a person on the phone) or **Verified on device**. Nothing below is
"Verified on device" yet.

Last updated: 28 Oct 2026. App code on `main` last changed in `4763e53` (PR #60); later merges
(#61, and the audit PR) change only CI, tools and docs. **Installed on the iPhone: `4763e53`**, built with `tool/build_ios.sh` and installed in place with
`devicectl` (data kept); Me › My App › About shows the commit. The phone screen was not
inspected by me. Development builds are signed for 7 days; the current one stops opening on
4 Nov 2026 until it is reinstalled.

## Bugs and corrections

| Bug | Failing test before the fix | Fix | Regression tests | PR / merge commit | Installed | Device verification |
|---|---|---|---|---|---|---|
| **Cook with disappears when the ingredient is cleared (All phases)** | Yes, run on unfixed code | Field always shown; in All phases the sheet lists every food that has a recipe | choose / clear / choose repeatedly, Change, meal type kept, empty result recovers | #46 `e3d9d3d` | Yes | **Awaiting** |
| **3 Plants a Day ignores the day the cycle wheel is on** | Yes, run on unfixed code | Plants follow the wheel's day (preview only, writes nothing) | same day = same plants, phase boundary, restart, irregular cycles, no stored-data change | #48 `4afe667` | Yes | **Awaiting** |
| **Collection tiles uneven; counts and status text** | Layout change; new tests assert what the old layout could not satisfy | One shared tile: titles only | equal size and title offset, no counts, 320 pt and large text | #45 `90655f0` | Yes | **Awaiting** |
| **Home shortcuts show counts; "Why these foods" in phase info** | Old tests asserted the text; they now assert it is absent | Headlines only | titles only, no WHY THESE FOODS | #47 `f1a88ac` | Yes | **Awaiting** |
| **Collection tile title and arrow not on one line** | New test asserts the same centre line in all four tiles | Title and arrow share one row | title/arrow centre line, same picture height | #58 `90952c4` | Yes | **Awaiting** |
| **Diary and Shopping List shortcut title and arrow misaligned on Home** | Alignment assertions added | Shared alignment, no counts | title/arrow alignment, large text | #57 `ede267b` | Yes | **Awaiting** |

## Changes asked for (all merged and installed in `4763e53`; device verification awaiting)

| Feature | PR / merge commit | Notes |
|---|---|---|
| Me: four destinations (My Collections, My Diary, My Shopping List, My App) | #44 `274bc85` | |
| Me: customizable hero image | #59 `839f4e9` | Choose a bundled MoonCycle picture, a photo from the library, or a camera photo; restore the default. The chosen image is stored on the phone, is included in Delete my data, and is never uploaded. Permission refusal and a missing file fall back to the default with a calm message. |
| My App: compact rows; logo and version footer at the bottom, below Delete my data | #56 `cfe3517` | |
| My Collections: four equal titles-only tiles, long-press drag to reorder (saved on the phone), Move earlier / later actions for accessibility | #45, #58 | Real drag is a hand check. |
| My Routines (schema v10) | #42 `5b133f4`, #51 `d0d6f74` | Included in Export; removed by Delete my data. |
| Eat, Move, Relax look alike | #49 `2912a0d` | Move and Relax heroes use images already in the app as stand-ins; request in `docs/hero-image-requests.md`. |
| Move: "My Workouts" card removed; Relax: "My Spa" card removed; "Meal Builder" renamed "Build a Meal" (stays free) | #55 `37c16a0` | |
| Build Your Workout, **Save to My Workouts** (schema v11, `kind` column on routines) | #54 `bcc35cf` | Saved workouts are separate from My Routines and appear under My Collections › My Workouts. Migration tested. |
| Move and Relax hubs, libraries, item pages | #41 | No approved content yet: libraries are empty by design. |

## Content and research (nothing new is published)

| Item | Status |
|---|---|
| Food Detail profiles | **5 approved and published (unchanged).** **251 drafted**, all audited (below), **unreviewed and not in the app**. **15 blocked**, each with a decision-table entry (`docs/food-profiles/blocked-decisions.json`). Missing: 0. Files: `coverage-report.md`, `complete-draft-dataset.json`, `editorial-review-report.md`, `review-list.md` and the audit package `audit-report.md` (`audit-summary.json`). No profile is "clinically reviewed"; **drafted is not implemented**. |
| Food profile quality audit | Every one of the 251 drafts was re-compared with its live USDA FoodData Central record (`audit_profiles.py`): FDC id, description, date, every per-100 g value, serving weight, every per-serving amount and percentage. **0 open data findings; no number needed correcting.** Prose of all 251 was read: 193 profiles had wording, safety or allergen lines corrected; 43 need an editor's judgment (identity, serving state, surprising USDA values, safety not researched); 164 have no substantive concerns (still unapproved). Added: sodium per serving, allergen lines from the catalogue tags, and sourced cautions (raw sprouts, smoked fish, deli ham, unpasteurised cheeses, honey and infants, fava beans and G6PD, seaweed iodine) after reading each source page. New regression tests cover provenance, preparation state, sodium, allergen parity, placeholder prose and claims. 59 profiles still carry a catalogue caution with no recorded source. |
| Move and Relax content | 13 original draft items in `docs/content-drafts/` (not bundled); need professional or editorial review. |
| Sounds | Concepts only. **Blocked**: no audio with confirmed rights and no audio plugin. |
| Food photography | **Blocked, not started**: no authorised image source in this environment. Manifest in `docs/food-photo-manifest.json`. |

## Needs your approval or input

1. Editorial approval of the 251 food-profile drafts: start with `docs/food-profiles/audit-report.md` (what to approve is at its end), then `review-list.md` for sampling sheets. Also the Move and Relax drafts.
2. Decisions on the 15 blocked foods.
3. Hero photographs for Move, Relax and Eat; food photographs.
4. Audio with confirmed rights if you want Sounds.
5. A paid Apple Developer account if you want builds that do not expire every 7 days.

## Not implemented (do not expect on the phone)

Any food photograph beyond the original 3; any Move or Relax library content; Sounds; profiles for foods other than the five approved.

## Workflow notes

`main` requires three checks (Format, analyze, layers, tests; Golden screenshots (macOS);
Android build (dev, debug)) and an up-to-date branch. Run `tool/precheck.sh` before pushing;
see the CI section of the pull request that added it for what changed.
