# Development progress

One report, kept current. **Stage** means exactly one of: 1 Mockup, 2 Documentation,
3 Unmerged Flutter code, 4 Merged into `main`, 5 Installed on the iPhone. Bugs carry a
second, separate status: **Implemented, awaiting device verification** (passes automated
tests, not yet checked by a person on the phone) or **Verified on device**. Nothing below is
"Verified on device" yet.

Last updated: 29 Oct 2026. App code on `main` last changed in `20e0dee` (PR #65, the kidney bean safety correction). **Installed on the iPhone: `20e0dee`**, built with `tool/build_ios.sh` and installed in place with `devicectl` (data kept). The phone screen was not inspected by me. Development builds are signed for 7 days from when the signing profile is created; the profile in this build still expires on **4 Nov 2026 (01:24 UTC)**, so the app must be reinstalled on or after about 3 Nov to get a fresh profile.

## Bugs and corrections

| Bug | Failing test before the fix | Fix | Regression tests | PR / merge commit | Installed | Device verification |
|---|---|---|---|---|---|---|
| **Cook with disappears when the ingredient is cleared (All phases)** | Yes, run on unfixed code | Field always shown; in All phases the sheet lists every food that has a recipe | choose / clear / choose repeatedly, Change, meal type kept, empty result recovers | #46 `e3d9d3d` | Yes | **Awaiting** |
| **3 Plants a Day ignores the day the cycle wheel is on** | Yes, run on unfixed code | Plants follow the wheel's day (preview only, writes nothing) | same day = same plants, phase boundary, restart, irregular cycles, no stored-data change | #48 `4afe667` | Yes | **Awaiting** |
| **Collection tiles uneven; counts and status text** | Layout change; new tests assert what the old layout could not satisfy | One shared tile: titles only | equal size and title offset, no counts, 320 pt and large text | #45 `90655f0` | Yes | **Awaiting** |
| **Kidney bean warning said 'boil 10 minutes'** | Yes: new `kidney_bean_safety_test.dart` fails on the old wording | Catalogue now gives the FDA instructions: soak at least 5 hours, boil in fresh water at least 30 minutes; no slow cookers; canned beans are already cooked | 4 data checks and a Food Detail widget check; old wording absent from every content file and draft | #65 `20e0dee` | Yes | **Awaiting** |
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

PRs: #63 (food-to-phase provenance audit) is **open and not merged**: it holds findings that need your editorial and legal review, and the repository is public. Wave 1 (98 profiles after holding the three seed foods back) editorial approval package: `docs/food-profiles/wave-1-approval-summary.md` (short), `wave-1-review-package.md` and `wave-1-qa-report.md`. Wave 1 stays unpublished.

| Item | Status |
|---|---|
| Food Detail profiles | **5 approved and published (unchanged).** **251 drafted**, all audited (below), **unreviewed and not in the app**. **15 blocked**, each with a decision-table entry (`docs/food-profiles/blocked-decisions.json`). Missing: 0. Files: `coverage-report.md`, `complete-draft-dataset.json`, `editorial-review-report.md`, `review-list.md` and the audit package `audit-report.md` (`audit-summary.json`). No profile is "clinically reviewed"; **drafted is not implemented**. |
| Food profile quality audit and publication readiness | All 251 drafts re-compared with live USDA records: **0 open data findings, no number needed correcting**. Prose of all 251 read and corrected (193 profiles in the first audit). Readiness pass: caution statuses (`sourced` 120, `partly-sourced` 10, `catalogue-tag` 56, `unverified-inherited` 19 cautions on 18 profiles; nothing unverified is called verified), allergen lines from the catalogue, sodium kept as data with a calm note only at the FDA 'high' line (460 mg), 15 flagged items resolved with sources, and **13 decisions for the owner** (`audit-report.md` section 3). Safety correction: the kidney bean caution said 'boil 10 minutes'; the FDA (Natural Toxins in Food; Bad Bug Book) says soak at least 5 hours and boil at least 30 minutes, no slow cookers, canned beans already cooked. **Corrected in the app catalogue and the draft; regression tests added.** **Publication plan** (`publication-plan.md`): Wave 1 of 98 profiles recommended for approval, 96 more ready, 8 need source work, 49 need a decision, 15 blocked. `wave-1-candidate.json` is a docs-only candidate with `publishable: false`. **Nothing is published; no profile is in the app.** |
| Move and Relax content | 13 original draft items in `docs/content-drafts/` (not bundled); need professional or editorial review. |
| Sounds | Concepts only. **Blocked**: no audio with confirmed rights and no audio plugin. |
| Food photography | **Blocked, not started**: no authorised image source in this environment. Manifest in `docs/food-photo-manifest.json`. |

## Needs your approval or input

1. Food profiles: decide the Wave 1 approvals and the 13 decisions in `docs/food-profiles/publication-plan.md` and `audit-report.md`. Also the Move and Relax drafts.
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

## Independent methodology, filtering audit, privacy audit and signing (29 Oct 2026)

- **Independent phase methodology** (`docs/food-profiles/independent-phase-methodology.md`, PR #67, merged): four evidence classes, evidence matrix with sources read, suggestion algorithm and explanation templates, unresolved questions, responsible use of the 142 assignments. **No phase mapping changed.** Per-food assessment: `phase-independent-assessment.md`.
- **Build a Meal and filtering audit** (PR #68): fixed a vegan-filter data defect (egg noodles and naan carried no animal source); added whole-catalogue diet and allergen property tests. Recommendation logic, UI and flow unchanged. Legumes appear in both Protein and Base sections (documented, not changed).
- **Privacy audit** (`docs/privacy-and-data-audit.md`, PR #69): no demonstrated defect; posture locked by tests; proposals for discreet reminders, temp-file hardening and app-switcher blur await approval.
- **iOS signing:** the development provisioning profile was renewed on 29 Oct (new profile created 2026-10-29 03:17 UTC, expires 2026-11-05 03:17 UTC; certificate valid to 2027-10-13). Free-account profiles last 7 days: renew again before 5 Nov by removing the cached profile in `~/Library/Developer/Xcode/UserData/Provisioning Profiles` (keep a copy) and rebuilding with `tool/build_ios.sh`, then install in place with `devicectl` (never `flutter install`).

## Decisions of 29 Oct 2026 and what followed

- **PR #63 closed without merging** (branch kept; nothing deleted or rewritten). The private audit, original evidence and SHA-256 manifest are unchanged in `~/projects/moon-cycle-private-provenance/`. A repository content audit (credentials, private records, third-party material) is held there too, unpublished.
- **Methodology adopted for internal editorial use** (four evidence classes with uncertainty labels). No phase assignment is represented as clinically established or independently validated; the mapping is unchanged.
- **Wave 1 (98 profiles) stays unpublished.** Heading chosen: "Nutrition & your cycle" (previews only; the app still shows "Cycle relevance"). Clarified iron wording (the need applies every day of the month). Seed foods held. Exact wording, six rendered Food Detail previews (`docs/food-profiles/wave-1-screens/`) and `wave-1-candidate.json` (now carrying the proposed text, `publishable: false`) await approval. No credential is assigned to the reviewer.
- **Discreet reminders** (PR #71): neutral notification text by default; details are an explicit opt-in. Stale export files are deleted at start-up. SQLite temp files assessed (nothing demonstrated; optional hardening listed) and the app-switcher blur remains a proposal.
- **iOS signing:** `tool/renew_ios_signing.sh` and `docs/ios-signing.md` document a repeatable check/renew/install-in-place procedure.

## 30 Oct: third-party fixtures and privacy shield
- PR #75: recipe-provider test fixtures replaced with synthetic, deterministic data (`tool/make_synthetic_fixtures.py`); scenarios preserved; four goldens re-recorded. Git history is not rewritten. The full inventory is kept privately.
- Privacy shield (opt-in, off by default): Settings › Privacy & Data › "Hide app in app switcher". iOS cover on `willResignActive`; Android `FLAG_SECURE`. Simulator-verified (on = blank card, off = visible, same page after return). Awaiting a physical-iPhone test before merge.
