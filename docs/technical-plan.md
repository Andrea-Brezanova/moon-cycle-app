# Moon Cycle: Flutter rebuild technical plan

**Status:** approved 11 October 2026 (see Decisions). Milestone 1 implemented in `moon-cycle-flutter`.
**Date:** 11 October 2026
**Scope:** a production Flutter app for iOS and Android that rebuilds Moon Cycle from scratch. The approved Editorial design is the visual source of truth; the Emergent app is the functional reference.

---

## Decisions (confirmed 11 October 2026)
- **v1.0 is local-only:** no account, no sign-in. Supabase Auth and Supabase Postgres with RLS arrive in v1.1.
- **Stack:** Drift with encrypted local storage from the start; Riverpod 3; go_router; Sentry for crash reporting; no Firebase in v1.
- **Subscriptions:** feature-gated architecture, but no RevenueCat yet. A **fixed launch-free period** (one end date for everyone), not 90 days from install.
- **No sign-in design or implementation yet.**
- **UI source:** the Editorial direction (cream, plum and ochre) only. Handoff v3: `handoff-editorial/`.
- **App identity:** `app.mooncycle.mobile` on iOS and Android (domain `mooncycle.app`, owned via Cloudflare). Test builds: `.dev` and `.stg` suffixes.
- **Repository:** `/Users/andreasmacbookpro/projects/moon-cycle-flutter` → `github.com/Andrea-Brezanova/moon-cycle-app`. The folder structure is approved by you before it is created; nothing is committed or pushed without your explicit request.
- **Recipe data:** recovered from the Emergent repository (`content-model/recovered/`); open content flags are in `content-model/RECIPE-DATA-NEEDED.md`.
- **Flavours (Milestone 1 approval):** only `dev` and `prod` in v1. `stg` is added with Supabase in v1.1. Where this plan mentions three flavours or a staging build, read dev/prod for v1.
- **Design reference in the repo:** the Editorial v3 handoff is copied into `design/` (including the screen PNGs) as an immutable reference; it is not regenerated or edited during normal development.
- **Baseline:** Flutter 3.47.7 stable with Dart 3.13.5.
- **Docs:** one `docs/decisions.md` instead of separate ADR files; no architecture tooling beyond `tool/check_layers.dart`.

---

## 0. Recommendations at a glance

| Decision | Recommendation | Section |
|---|---|---|
| Client | **Flutter** (stable channel), phones only, portrait | 2 |
| Backend | **Supabase**: Postgres + Row Level Security + Auth + Edge Functions. Storage only when content goes remote | 2 |
| Auth | **Option A: Supabase Auth**, with Sign in with Apple, Google and email one-time code | 3 |
| Firebase | **Not in v1.** Reminders are local notifications, so no push service is needed. Crash reporting with Sentry (EU region). Add FCM only if server-sent push becomes a real need | 2 |
| Local database | **Drift** (SQLite), encrypted with SQLCipher | 11 |
| State management | **Riverpod 3**, written by hand (no provider code generation at first) | 13 |
| Routing | **go_router** with `StatefulShellRoute` for the five tabs | 14 |
| Architecture | Feature-first folders; each feature split into `presentation / application / domain / data`; pure-Dart domain | 4, 15 |
| Data strategy | **Local-first.** The app is fully usable with no account. An account turns on backup and sync | 11 |
| Content | One versioned `content/` source in the repo generates both the app's bundled content and the Supabase seed | 8 |
| Entitlements | Feature-gate abstraction from day one. Launch promo = everyone gets Plus; RevenueCat plugs in later | 10 |
| Release train | **v1.0 local-only** (no account), then **v1.1 accounts and sync**, then subscriptions. See section 18 | 18 |

---

## 1. What I inspected, and what is missing

**Inspected:**
- **Editorial design handoff** (`handoff-editorial/`): spec v2, `theme.ts`, `cycle.ts`, 23 screen PNGs, assets, fonts, content JSON.
- **Canvas artifact, version 80**: newer than the handoff. It changes the Home hero to an off-white base with a faint phase wash, gives dark mode one night-plum hero with a phase glow and marker ring, rebuilds onboarding step 5 with the moon, and adds "Day x of y in cycle" to the hero.
- **PRD** (`handoff/PRD (1).md`): written for the superseded Sorbet design, but its behaviour sections (cycle logic, shopping, filters, tabs) are still the best functional description.
- **Content model** (`content-model/`):
  - `ingredients.json`: 157 foods, short and detail copy per phase, `shipReady`, 26 flags.
  - `recipe-classification.json`.
  - `source-emergent-export.md`.

**Missing. These block parts of the build:**
1. **The Emergent repository itself is not on this machine.** I could not inspect its code, its cycle logic, its shopping behaviour, or `frontend/src/data/phases.ts`. Please export it from Emergent (GitHub) and add it beside this folder.
2. **Recipe details.** The export only has recipe names, categories and ingredient *tags*. Quantities, method steps, intro, servings, minutes and images are `null` in every handoff file. Recipe detail and shopping-quantity merging can't be built faithfully without them.
3. **Diet and allergen metadata per food and per recipe line.** It doesn't exist anywhere. Food-preference filtering and allergy exclusion depend on it, and allergy data is safety-relevant (section 19).
4. **Aisle per food.** Shop groups by aisle (Produce, Protein, Grains, Fermented, Dairy & alternatives, Pantry, Other). Food categories are a different list, so every food needs an aisle assignment.
5. **Undrawn screens** (section 5.7). The brief asks for an exact reproduction with no independent design decisions, so these need design boards before they are built.
6. **Handoff v3.** The handoff files are older than canvas version 80. Regenerate them before the design-tokens milestone.

---

## 2. Stack evaluation

### Flutter: yes
- **For:**
  - Flutter draws every pixel itself, so the editorial layout renders the same on iOS and Android.
  - `CustomPainter` is the right tool for the moon and orbit.
  - Typography, letter-spacing and line height are fully controllable.
  - The testing story is strong (unit, widget and golden tests in one toolchain).
  - Dart is quick to learn for someone maintaining the app with an AI assistant.
- **Against:**
  - None of the Emergent TypeScript code is reused. In practice that is only about 200 lines of logic (`cycle.ts`, merge rules), which are re-specified in this plan anyway.
  - The app's look is custom rather than native, which is what this design wants.
- **The alternative I considered:** keeping React Native/Expo. It would reuse `theme.ts` and `cycle.ts` directly. For a clean rebuild that must reproduce a custom editorial design, Flutter's single rendering engine is the better fit.

### Supabase Postgres: yes
- The content is relational: foods ↔ phases ↔ categories, recipes ↔ ingredients. Postgres and foreign keys suit it better than Firestore documents.
- RLS gives a clear, testable per-user security model, and Postgres makes export and deletion straightforward.
- **Region:** choose the EU (Frankfurt) if you expect EU users. Cycle data is "special category" health data under GDPR.

### Supabase Storage: later
- v1 ships its 12 recipes and their images **inside the app**: offline, versioned and reviewable.
- Storage (with CDN caching) is useful once content updates without an app release are wanted.

### Firebase: drop it for v1
| Service | Verdict | Why |
|---|---|---|
| Cloud Messaging | **Not needed for v1** | Phase-change and period reminders can be computed on the device from local cycle data, so use local notifications. That also keeps cycle data off any server. Add FCM later only for server-sent pushes (for example "new recipes"). |
| Crashlytics | **Replace with Sentry** (or keep, see below) | One vendor fewer and no per-flavour `GoogleService-Info.plist` / `google-services.json`. Sentry has an EU data region, handles Dart obfuscation symbols, and `sendDefaultPii` can stay off. Crashlytics is a fine free alternative if you prefer Google. |
| Analytics | **None at launch, or a privacy-first tool** | Firebase Analytics collects device identifiers by default and must be declared in the App Store privacy labels and Play Data safety form. Cycle apps are under heavy privacy scrutiny. If you need product analytics, use PostHog (EU) or TelemetryDeck, with a rule that **no event may contain cycle, phase, diet or allergy data**. |

Net result: **Supabase + Sentry**, with RevenueCat later. Three vendors instead of two overlapping platforms.

---

## 3. Auth: option A vs option B

| | **A. Supabase Auth + Supabase DB/RLS** | **B. Firebase Auth + Supabase DB/RLS** |
|---|---|---|
| RLS | `auth.uid()` works natively | Needs Supabase's third-party-auth setup; policies read `auth.jwt()->>'sub'` (a text id, not a uuid) |
| Foreign keys | User tables reference `auth.users(id)` with `on delete cascade` | No `auth.users` row, so no FK and no cascade. You must add your own user table and keep it in step |
| Account deletion | One Edge Function deletes the auth user; the cascade removes all rows | Delete in Firebase *and* Supabase, with partial-failure handling |
| Apple / Google sign-in | Native `signInWithIdToken` (with nonce) | Native, mature |
| Anonymous → registered | Built in (anonymous users, identity linking) | Built in |
| Vendors, consoles, environments | 1 | 2 (×3 environments) |
| Learning load | One SDK and one mental model | Two token lifecycles to reason about |

**Recommendation: A.** Option B only makes sense if you already depend on Firebase for something else, and this plan removes that dependency.

**Sign-in methods:**
- Sign in with Apple, Google, and email one-time code (no passwords to store or reset).
- App Store guideline 4.8 requires Sign in with Apple, or an equivalent privacy-focused option, whenever Google sign-in is offered.

**Anonymous Supabase users: no.** The app stays fully local until the user chooses to create an account. That is the minimum-data choice: most users' cycle data never leaves the phone. Section 11 covers how local data moves to an account.

---

## 4. Architecture

### 4.1 Layers inside each feature
```
presentation  → widgets, pages, sheets. Reads application state, sends user intents.
application   → Riverpod providers/notifiers. Orchestrates use cases, holds screen state.
domain        → pure Dart: entities, value objects, rules (cycle calculator, shopping merger,
                feature gates). No Flutter, Riverpod, Drift or Supabase imports.
data          → repositories (interfaces live in domain or data; implementations in data),
                local (Drift) and remote (Supabase) data sources, DTO ↔ entity mapping.
```

### 4.2 Dependency rules
- `presentation → application → domain ← data`. Domain depends on nothing.
- A feature may use another feature's `domain` and `application`, never its `presentation`. The exception is navigation, which goes through the router.
- Shared design components live in `core/design` and must not know about features.
- Time is injected through a `Clock` (package `clock`), never read with `DateTime.now()` inside domain code. This makes every cycle test deterministic.
- **Enforcement:** a short CI check (`tool/check_layers.dart`) fails the build if a `domain/` file imports `package:flutter`, `riverpod`, `drift` or `supabase`.

### 4.3 Data flow
```
UI ──intent──▶ Notifier (application) ──▶ Repository (data) ──▶ Drift (local, source of truth for the UI)
 ▲                                                                  │
 └──────── Stream / AsyncValue ◀── watch query ◀───────────────────┘
                                   SyncEngine (later) ⇄ Supabase
```
The UI only ever reads **local** data. Sync runs in the background and writes into Drift, and Drift's watch queries update the UI. This makes offline mode the default rather than a special case.

---

## 5. Design implementation (exact Editorial design)

### 5.1 Fidelity process
1. **Source of truth:** handoff v3 (spec, tokens, PNGs at 390 × 844) plus the canvas.
2. **Tokens are ported once.** Colours, phase sets, hero palettes, type scale, spacing, radii and sizes go into Dart in `core/design/`. A test asserts every text/background pair meets the documented contrast ratio.
3. **A design-overlay debug tool.** In debug builds, a toggle lays the handoff PNG for the current screen over the live screen at 50% opacity, with a slider. This is the most effective way to get spacing exactly right.
4. **Golden tests** for every design-system component and every screen in light and dark mode at 390 × 844. They catch regressions after a screen is approved. Comparison against the handoff PNG is a visual sign-off, not a pixel diff, because Chrome and Flutter rasterise fonts differently.
5. **Rule:** if something can't be reproduced exactly, or reproducing it hurts accessibility, it's flagged in a `docs/design-deviations.md` log and agreed **before** any change.

### 5.2 Typography
- **Bundle the static TTFs from the handoff;** no runtime font download. Families:
  - `Fraunces72` (Light, Regular, Italic): 40 pt and up.
  - `Fraunces24` (Regular, Medium, Italic, MediumItalic): below 40 pt.
  - `DMSans` (Regular, Medium, SemiBold, Bold).
  - Gwendolyn Bold, kept only as a fallback; the wordmark ships as outlined SVG.
- **Match CSS line-height:** set `TextLeadingDistribution.even` app-wide, because CSS puts half the leading above the text and half below. Convert line heights to Flutter `height` multipliers and em-tracking to logical-pixel `letterSpacing`.
- **Italic accent words** ("Fresh, light and *energising*") are `Text.rich` spans using the matching italic family. A small `EditorialHeading` widget parses a `*word*` marker in the content.
- **Dynamic Type:** scale text with the system setting, clamped to 1.3× for headings and 1.5× for body, as the spec says. Layouts must reflow without clipping; this is checked in golden tests at 1.0× and the maximum.

### 5.3 Components to build (`core/design/widgets/`)
- **Buttons:** primary (ochre), secondary (plum/inverse), ghost, text link.
  - Flutter's underline can't take a custom offset or thickness, so the "2 pt ochre underline, offset 4" link is a custom widget that paints the underline itself.
- Phase selector (4 columns), pill chip (3 states), round checkbox (26 pt with a 44 pt hit area), list row, section head, overline, stepper, month calendar.
- Bottom-sheet scaffold (top radius 32, handle), recipe photo / tinted placeholder, Undo toast.
- Custom tab bar (88 pt including the home indicator, ochre active dot).
- Wordmark: outlined SVG via `flutter_svg`, precompiled with `vector_graphics_compiler`.
- Icons: SVG with `currentColor`, coloured through `SvgTheme`.
- **Feature-specific widgets live inside their feature:** food row and count badge in Foods, shop row in Shopping.

### 5.4 Theming
- `ThemeData` covers the basics.
- A `ThemeExtension<MoonColors>` holds the semantic tokens (`bg`, `raised`, `sand`, `line`, `text`, `textMuted`, `inverseBg`, `ochre`, …) and a `PhasePalette` per phase.
- Light/dark follows the system (`ThemeMode.system`); an optional override can go in Settings › App.
- **Widgets never use raw hex values.**
- **Edge-to-edge** on both platforms; the Home hero runs under the status bar. Android 15+ enforces edge-to-edge anyway. Status bar icons switch with the hero and theme.

### 5.5 Home moon and orbit (native, `CustomPainter`)
The design coordinate space is **300 × 300** (centre 150). The painter scales it to the available width: `side = min(300, screenWidth − 2 × 45)`, so it renders at 300 on 375–430 pt phones and shrinks proportionally on 320 pt devices.

| Element | Implementation |
|---|---|
| Moon disc | Circle, radius 108. `Paint.shader` = `RadialGradient(center: Alignment(-0.2, -0.28), radius: 0.7)` over the disc's bounds. That is the SVG's `cx 40% cy 36% r 70%` converted to Flutter alignment. Stops come from the theme ochre (light and dark sets). |
| Four phase segments | `canvas.drawArc` with radius 136, stroke 12, `StrokeCap.butt`. Angles start at −π/2 (12 o'clock) and run clockwise. Segment *i* spans `(start−1)/L + gap → end/L − gap`, with `gap = 0.0035` of a turn. Lengths come from the user's own phase ranges (section 6). |
| Active phase | Phase `accent`; the other three use their `tint`. Light and dark (night) palettes come from tokens. |
| Today marker | A halo circle (r = 0.95 × stroke) filled with the hero background, then a dot (r = 0.72 × stroke): plum in light, cream in dark. **Dark only:** a 2.6 pt ring in the phase accent around the dot. |
| Dark phase glow | Dark only. A radial gradient circle (r 150) in the phase accent, opacity 0.30 at 68% fading to 0 at 100%, painted under the moon. |
| Centre text | **Real `Text` widgets** in a `Stack` over the painter ("DAY" overline and the Fraunces Light day number), not painted text. This gives correct font rendering, Dynamic Type and screen-reader support. |
| Hero background | **Light:** off-white with the phase wash (one tint per phase). **Dark:** one night-plum gradient for every phase. Solid until 64 pt above the bottom, then a 64 pt fade into the page. Built as a `Stack` of a solid fill plus a 64 pt gradient strip, so it doesn't depend on the hero's height. |
| Animation | The marker moves along the arc with a 250 ms ease-out tween on the day fraction. Segment and background colours cross-fade when the phase changes. Everything is skipped when the system "reduce motion" setting is on. |
| Drag preview | A pan gesture converts the angle to a day (`dayFromAngle`), with a selection haptic each time the day changes. The preview is local to Home and shows "Back to today". Content below the hero stays on today's phase (PRD 7). |
| Accessibility | `Semantics` label: "Cycle day 7 of 28, follicular phase, day 2 of 6". It is an *adjustable* control (increase/decrease actions), so drag preview works with VoiceOver and TalkBack too. |
| Performance | `shouldRepaint` compares an immutable `OrbitSpec` value object; wrapped in a `RepaintBoundary`. |
| Tests | Golden tests: 4 phases × light/dark, the late-period state, a 21-day cycle, a 45-day cycle, and the 320 pt width. Unit tests: angle↔day conversion. |

The onboarding reveal (step 5) uses the **same** `MoonOrbit` widget and the same hero background as Home (canvas version 80).

### 5.6 Responsive rules
- Phones only, portrait-locked for v1 (no iPad layouts, no extra store screenshots).
- Gutters stay at 24 pt. Content stretches between 320 and 430 pt.
- Food rows stay two-column down to 360 pt; below that, decide with design (section 20).
- Respect safe areas and Android gesture-navigation insets; the tab bar height includes the bottom inset.

### 5.7 Screens and states that are not drawn yet (need design before building)
1. Recipe detail. It is only described in prose in spec §9.
2. Ingredient sheet and Cook with… sheet. Also prose only.
3. Settings sub-screens: My Cycle (including period log and history), Food Preferences, Allergies / Foods to Avoid, Notifications, Account, Subscription, Privacy & Data, Help, Delete Account confirmation.
4. Sign-in / create account, and the "this account already has data" merge prompt.
5. **Late-period state** on Home: what "Day 32 of 28" looks like, and the "Has your period started?" prompt.
6. Empty states: an empty shopping list; the Recipes filter with no results (Snacks is empty in every phase today); a food with zero recipes.
7. Loading and error states (rare, since everything is local).
8. The onboarding reveal for the other three phases (only Follicular is drawn); the Foods "browsing another phase" helper line.
9. Notification permission priming screen; the launch-promo / "Plus" explanation.

**Proposal:** I can draw these on the canvas in the Editorial system before their milestones start.

---

## 6. Cycle domain (pure Dart, `features/cycle/domain`)

### 6.1 Types
- `LocalDate`: a calendar date with no time or timezone. **All cycle maths uses calendar days**, so DST and time-zone travel can't shift a day. "Today" = `LocalDate.fromDateTime(clock.now())` in the device's local timezone.
- `Phase`: menstrual, follicular, ovulatory, luteal. It lives in `core/domain/phase.dart` because every feature uses it.
- `PeriodLog { id, startDate, endDate?, source }`: history; the latest `startDate` is "last period start".
- `CycleProfile { typicalCycleLength (21–45, default 28), typicalPeriodLength (2–10, default 5), lutealLength? (10–16, default 14), useHistoryAverages }`.
- `PhaseRange { phase, start, end, length }`.
- `CycleState`, the derived result:
  - `cycleDay`, `cycleLength`, `phase`, `phaseDay`, `phaseLength`, `ranges`
  - `isLate`, `daysLate`
  - `nextPeriodDate`, `nextPhase`, `daysToNextPhase`
  - `markerFraction`, `dataQuality` (`typical` | `averaged`)

### 6.2 Rules
- **Phase ranges** port the handoff `cycle.ts` exactly:
  - `ovulationDay = cycle − luteal`
  - `ovStart = max(ovulationDay − 2, period + 2)`, which guarantees at least one follicular day
  - `ovEnd = min(ovStart + 3, cycle − 1)`
  - Menstrual = 1 to `period`. Follicular = `period + 1` to `ovStart − 1`. Ovulatory = `ovStart` to `ovEnd`. Luteal = `ovEnd + 1` to `cycle`.
  - 28/5 gives 1–5, 6–11, 12–15, 16–28.
- **Effective lengths:**
  - With `useHistoryAverages` on and **at least 3 completed cycles**: the rounded average of the last up-to-6 cycle lengths (gaps between consecutive starts). Gaps outside 21–45 are excluded as outliers but kept in history.
  - Period length works the same way, from logs that have an `endDate`.
  - Otherwise, use the typical values.
- **Late period** (`cycleDay > cycleLength`, no new log): the phase stays luteal, the marker is pinned at the end, and `cycleDay` keeps counting. Product decisions are needed for how this looks and when to prompt (section 20).
- **Logging a new period** restarts at day 1. Logging a start date that matches an existing log edits it instead of duplicating it.
- **Validation:**
  - No future start dates.
  - The start date can't be earlier than the previous log's start + 10 days.
  - Values are clamped to the ranges above.
- **Configurable defaults** (luteal length, ranges) are passed in as a `CycleConfig`. Later they can come from a remote `app_config` row without touching the domain.

### 6.3 Where things live
| On the device (always) | In Supabase (only with an account, for backup and sync) |
|---|---|
| Period logs, cycle profile | `period_logs`, `cycle_profiles` (the same data, encrypted in transit, RLS-protected) |
| **All derived values** (phase, cycle day, ranges, predictions) | **Never stored.** Always recomputed on the device |
| Reminder schedule | Nothing (reminders are local notifications) |

### 6.4 Tests (essential)
- 28/5, 21/2, 21/10 (follicular squeezed to its 1-day minimum), 45/10 and 35/7.
- Luteal 10 and 16.
- Day 1, the last day of each phase, the first day of each phase.
- Late by 1, 7 and 60 days. "Today" is the start date. A start date in the future is rejected.
- A DST transition and a timezone change around midnight.
- Averaging: fewer than 3 cycles; exactly 3; 6+; with outliers.
- Phase-boundary snapshots across a 120-day calendar walk.
- `daysToNextPhase` in luteal = days to the next period.

---

## 7. Onboarding

### 7.1 Flow (from the design)
1. Welcome.
2. Last period. A calendar with future dates disabled; "I'm not sure" = today − 7, flagged `startDateEstimated`.
3. Cycle and period length steppers (21–45 / 2–10).
4. Food preferences: diet (single choice) and avoidances (multi-select plus "Add another").
5. Reveal: the computed current phase.

### 7.2 State and persistence
- An `OnboardingDraft` (in memory, Riverpod notifier) holds the answers while the user moves back and forth. Validation runs per step; Continue stays disabled until the step is valid.
- **Nothing is written until step 4 completes.** Then one Drift transaction writes:
  - `period_logs` (one row, source `onboarding`)
  - `cycle_profile`
  - `preferences` (diet)
  - `food_avoidances`
  - `app_state.onboardingCompletedAt`
- If the app is killed mid-flow, the draft is lost by design. The questions are short, and this avoids half-saved state.

### 7.3 First-launch handling
- The router's redirect sends any route to `/onboarding` while `onboardingCompletedAt` is null.
- On iOS the Keychain survives an uninstall. A first-run flag in app preferences clears stale secure-storage entries (database key, any old session) on a fresh install.

### 7.4 Editing later (Settings › My Cycle, Food Preferences, Allergies)
- These screens reuse the **same step widgets** (calendar, steppers, diet pills, avoidance chips) in an "edit" mode that saves on confirm.
- My Cycle also shows the history list, the next period and the next phase, and has "Log a period". Its design is still to be drawn.

### 7.5 Syncing later
These rows are ordinary user tables, so they sync like everything else (section 11). Onboarding itself never talks to the network.

---

## 8. Content and data model

### 8.1 Content pipeline (no rewriting, no invention)
- `content/` in the repo is the **single source**, as reviewed JSON files:
  - `phases.json`, `food_categories.json`, `aisles.json`, `foods.json`
  - `phase_foods.json` (placement + why-copy)
  - `recipes.json`, `allergens.json`
- It is assembled mechanically from the Emergent export, `ingredients.json` and the Emergent repository's recipe data. Every value is traceable to a source.
- `tool/validate_content.dart` (runs in CI) checks:
  - IDs are unique; every reference resolves; every phase has categories in the stored order.
  - No `shipReady: false` item is published.
  - Every food has an aisle; every recipe tag resolves to a food.
- `tool/build_content.dart` generates:
  1. `assets/content/content.json`, the app's bundled, read-only catalogue (v1);
  2. `supabase/seed/content.sql`, for the backend content tables (later; used for remote updates and server features).
- **IDs are permanent slugs** (`buckwheat`, `green-lentil`), because user data (shopping items, avoidances) references them. If a food is retired, user rows keep their stored display name and still render.
- Audit metadata (evidence confidence, sources, notes) stays in the content repo and does **not** ship in the app.

### 8.2 Content entities (read-only in the app; public read in Supabase)

| Entity | Fields | Notes |
|---|---|---|
| **Phase** | `id` (menstrual…), `sortOrder`, `season`, `tagline`, `homeDescription`, `focusBody`, `cookingTip` | Copy exactly as exported |
| **FoodCategory** | `id` (grains…), `name`, `sortOrder` | Grains, Vegetables, Fruit, Legumes, Nuts & seeds, Meat, Seafood, Other |
| **Aisle** | `id`, `name`, `sortOrder` | Produce, Protein, Grains, Fermented, Dairy & alternatives, Pantry, Other |
| **Food** | `id`, `name` (as exported), `displayName`, `qualifier` (e.g. "Bibb, Boston, romaine"), `aisleId`, `synonyms[]`, `animalSource` (none, dairy, egg, seafood, meat, honey), `shipReady` | `displayName`/`qualifier` are split mechanically from `name` and reviewed. `animalSource` needs authoring (section 1) |
| **IngredientPhaseRecommendation** | `phaseId`, `foodId`, `categoryId`, `sortOrder`, `whyShort`, `whyDetail` | Primary key (phase, food). **Category sits here** so per-phase placement is preserved exactly (Lychee stays under Nuts & seeds until approved). 4 foods appear in two phases |
| **Allergen** | `id` (gluten, peanut, tree-nut, sesame, soy, fish, crustacean, mollusc, egg, milk, mustard, celery, lupin, sulphites) | EU 14 / US 9 superset |
| **FoodAllergen** | `foodId`, `allergenId` | Needs authoring and a safety review |
| **RecipeCategory** | `id` (breakfast, lunch, dinner, snack), `displayGroup` (breakfast, meals, snacks) | Stored categories stay unchanged; lunch and dinner display as **Meals** |
| **Recipe** | `id`, `name`, `categoryId`, `minutes`, `serves`, `intro`, `imageAsset?`, `shipReady` | From the Emergent repository |
| **RecipePhase** | `recipeId`, `phaseId` | Many-to-many (single-phase today) |
| **RecipeIngredient** | `id`, `recipeId`, `foodId?`, `label`, `amount?`, `unit?`, `qtyText?`, `aisleId`, `isKey` (drives Cook with… and the recipe counts), `sortOrder`, `optional` | Non-catalogue lines (oil, salt) have no `foodId` but still need an aisle and allergens |
| **RecipeIngredientAllergen** | `recipeIngredientId`, `allergenId` | Only for non-catalogue lines |
| **RecipeStep** | `recipeId`, `stepNo`, `text` | |

### 8.3 User entities (local Drift tables; Supabase tables with RLS once there's an account)

Every user table has:
- `id uuid`, generated on the client;
- `created_at`, `updated_at` (client clock, used for conflict resolution);
- `deleted_at` (a tombstone, so deletions can sync).

On the server there is also `user_id` (FK → `auth.users` with cascade delete) and `server_updated_at` (set by a trigger; used as the sync cursor).

| Entity | Fields |
|---|---|
| **CycleProfile** (1 per user) | `typicalCycleLength`, `typicalPeriodLength`, `lutealLength?`, `useHistoryAverages`, `startDateEstimated` |
| **PeriodLog** | `startDate` (date), `endDate?`, `source` (onboarding, manual, health). Unique per user and `startDate` among non-deleted rows |
| **UserPreference** (1 per user) | `diet` (omnivore, pescatarian, vegetarian, vegan), `themeOverride?`, `reminderPrefs` (master, phaseChange, period, time) |
| **FoodAvoidance** | `kind` (allergen, food, custom), `allergenId?`, `foodId?`, `customLabel?` |
| **ShoppingItem** | `key`, `foodId?`, `name`, `aisleId`, `done`, `doneAt?`, `sortOrder?` |
| **ShoppingSource** | `itemId`, `type` (phaseFood, recipe, manual), `phaseId?`, `recipeId?`, `amount?`, `unit?`, `qtyText?` |
| **Entitlement** (server-written only) | `entitlement` (plus, …), `source` (promo, revenuecat, grant), `startsAt`, `expiresAt?` |
| **AppState** (local only, never synced) | `onboardingCompletedAt`, `lastPulledAt`, `firstSeenAt`, `contentVersion` |

**Why quantities sit on the source rows:** the item's displayed quantity is *derived* from its sources. Merging then means adding a source, never rewriting a number. Removing one recipe's contribution later stays possible, and undo is trivial.

### 8.4 Preference and allergy filtering (domain rule)
- **Diet:**
  - vegan excludes `animalSource ≠ none`;
  - vegetarian excludes meat and seafood;
  - pescatarian excludes meat.
- **Avoidances** exclude foods that carry an avoided allergen, foods avoided directly, and any recipe with an excluded food or ingredient line.
- **Recipe → Shop:** avoided ingredients are skipped, and the helper copy names them (PRD 9).
- **Foods screen:** should avoided foods be hidden or shown marked? The design doesn't say (section 20).

---

## 9. Shopping list

### 9.1 Keys and deduplication
- `key = "food:<foodId>"` for catalogue foods and recipe lines that link to a food.
- For typed text and non-catalogue lines: normalise (lower-case, trim, collapse spaces, strip punctuation), then look it up against the catalogue's `displayName` and `synonyms`. A match becomes the `food:` key; otherwise `key = "text:<normalised>"`.
- There is no automatic singular/plural guessing in v1. It is too error-prone; use synonyms instead.

### 9.2 Merge algorithm (pure function `ShoppingMerger.add(list, request) → result`)
```
1. k = key(request)
2. item = live item with key k (not deleted)
3. no item  → create item { name from catalogue or the request, aisle from the food, recipe line,
               or "Other" for typed text, done = false } with one source
4. item exists:
   a. if a source with the same identity (type + recipeId/phaseId) already exists → no change
      (adding the same recipe twice never doubles quantities; the UI also disables the button)
   b. otherwise append the new source
   c. if item.done → done = false (moves back to To buy)
5. return the new list plus a description of the change (created / merged / unchanged),
   for UI feedback and tests
```
- **Displayed quantity:**
  - Group source quantities by canonical unit: g/kg → g, ml/l → ml; tsp, tbsp, cup and pieces are kept as their own groups.
  - Sum within a group; text-only quantities are listed as text.
  - Join groups with " + ".
  - Volume and mass are **never** converted into each other.
- **"Merged" tag:** shown when the item has more than one source.
- **Remove (×):** tombstone immediately (no undo; this matches the spec).
- **Toggle:** flips `done` and `doneAt`.
- **Clear all:** tombstones every Done item and keeps their IDs for an **8-second undo**, which restores them.
- **Grouping:** To buy is grouped by aisle in the fixed order; empty aisles are hidden. Done is collapsed by default.
- **Recipe add:** one call per ingredient line, inside one transaction.
- **Sync duplicates:** two devices may each add "chicken" offline. After a pull, a dedupe pass merges same-key live items into the older one (earliest `created_at`, then lowest `id`), moves the sources across, and tombstones the newer item. The result is deterministic on every device.

### 9.3 Essential tests
- New food, same food twice, the same food from a phase *and* a recipe.
- The same recipe added twice; a Done item re-added (back to To buy).
- Unit merging (200 g + 1 kg = 1.2 kg; 1 tbsp + 100 g → "1 tbsp + 100 g"); text quantities.
- Typed text matching a synonym; typed text with no match → Other.
- Avoided ingredient skipped.
- Clear all then undo within 8 s; undo after 8 s is not possible.
- The two-device duplicate merge.

---

## 10. Free / Plus entitlements

- **Domain:**
  - `enum Tier { free, plus, premium }`.
  - `enum Feature { … }`, e.g. all phases browsing, recipe detail, unlimited shopping list, cloud sync. **Which features are Plus is a product decision** (section 20).
  - `FeatureGate.canUse(Feature, EntitlementState)`: the only place the UI asks "is this allowed?". **The UI never checks tier names.**
- **Sources** (`EntitlementSource` interface, combined by taking the highest tier that is still valid):
  1. `LaunchPromoSource`: Plus for everyone until a date in remote config (or a per-user window from `firstSeenAt`). Before the backend exists, the date is bundled.
  2. `ServerGrantSource`: a row in `entitlements` (support grants, grandfathering).
  3. `RevenueCatSource`: added later; the SDK's customer info maps to tiers.
- **Behaviour:** every feature that will ever be gated is wrapped in a gate from the start, with all gates returning true during the promo. Adding subscriptions later only adds a source and a paywall screen; no feature code is restructured.
- **Later RevenueCat integration:**
  - The app user id is the Supabase user id (anonymous RevenueCat id before sign-in, then `logIn`).
  - A webhook goes to a Supabase Edge Function that writes `entitlements`, so the server knows a user's tier too.
  - Restore Purchases sits in Settings › Subscription.
- **Note:** "free for about three months" could also be an App Store / Play **introductory free trial** once subscriptions exist. That's a pricing question for later.

---

## 11. Local-first storage and sync

### 11.1 Local database: Drift
- Typed SQL with compile-time-checked queries.
- **Reactive `watch()` streams**, which feed Riverpod directly.
- Real schema migrations with migration tests.
- An in-memory database for tests.
- Tables map 1:1 to Postgres, which makes sync straightforward.

**Alternatives rejected:**
- `shared_preferences`: not a database.
- Hive / Isar: their original maintainers stepped back, and they now rely on community forks.
- ObjectBox: a different data model from Postgres.
- PowerSync: a strong turnkey Supabase sync engine, but it adds a service and cost that this data volume (one user, kilobytes) doesn't justify. Revisit if real-time shared lists ever arrive.

**Encryption at rest:** SQLCipher (via `sqlcipher_flutter_libs`), with a random key in `flutter_secure_storage` (Keychain / Android Keystore). Turning encryption on later means migrating every existing install, so do it from the start.

### 11.2 Sync (milestone 18; local-only before that)
- **Design:**
  - The local database has **no user id**; it is a single-user store. `user_id` is added when rows are pushed.
  - Every write to a user table also writes an **outbox** entry (table, row id) in the same transaction.
- **Push** (on write, debounced; on app resume; on reconnect):
  - Upsert the changed rows, tombstones included.
  - A server trigger applies **last-write-wins per row by client `updated_at`**: an older write leaves the newer row in place.
  - Clear the outbox entries that were accepted.
- **Pull:** select rows where `server_updated_at > lastPulledAt` (the server sets this clock, so device clock skew can't break the cursor), apply them to Drift, then run the shopping dedupe pass.
- **Why last-write-wins is enough here:** the data is one person's, on at most a couple of devices, with low edit frequency. Shopping-item `done` toggles and profile edits are naturally row-level, and period logs merge on their natural key (`startDate`).
- **Realtime subscriptions:** not needed. Pull on resume, after writes, and on pull-to-refresh.

### 11.3 No account → account
1. The user signs in for the first time. The server account is empty, so **upload everything local**. The local data was already complete.
2. The server account already has data (reinstall or second device): show a choice (to be designed):
   - **Keep account data:** replace local with server.
   - **Merge:** period logs union by date, shopping union by key with merge, preferences from the account.
3. **Sign-out:** sync the outbox, then **wipe the local database** and secure storage (privacy default), and return to onboarding or sign-in.

### 11.4 What syncs
| Syncs | Doesn't sync |
|---|---|
| Cycle profile, period logs, preferences, avoidances, shopping items and sources | Derived cycle state, app state, session state (viewing phase, filters, preview), the reminder schedule (each device schedules its own from synced preferences) |

---

## 12. Privacy and security

**Row Level Security:**
- RLS is enabled and forced on **every** table in `public`.
- **User tables:** `select / insert / update / delete` allowed only where `user_id = auth.uid()`, plus a `with check` on the same condition.
- **Content tables:** `select` for `anon` and `authenticated`; no write policies (only migrations write).
- **`entitlements`:** users can `select` their own rows; no write policy (only the service role writes, via Edge Functions or webhooks).
- **pgTAP tests** prove that:
  - user A can't read or write user B's rows;
  - anon can't read user tables;
  - nobody can write `entitlements` from the client.

**Sessions:**
- Supabase Flutter session storage is switched to `flutter_secure_storage`.
- PKCE for OAuth; native Apple and Google sign-in with a nonce; short access tokens with refresh.
- Signing out revokes the refresh token on the server.

**Minimum data:**
- No name, birth date, location, contacts or advertising ID.
- Email only when the user creates an account.
- Cycle data stays on the device unless the user creates an account, which requires an **explicit consent step** for processing health data (GDPR Art. 9).
- Crash reports: `sendDefaultPii = false`; breadcrumbs scrubbed of food, phase and date values.

**Deletion:**
- **Account deletion is in-app** (an App Store requirement once accounts exist). A `delete-account` Edge Function, using the service role on the server, deletes the auth user, and FK cascades remove every row. Later it also deletes the RevenueCat customer and reminds the user to cancel any store subscription.
- **Local deletion** (available even without an account): delete the database file, secure-storage entries and preferences, and cancel scheduled notifications.

**Export:**
- Generated **on the device** from Drift as JSON (plus a readable CSV of period logs), shared through the share sheet.
- Works offline. It covers synced data too, because local is a full copy.

**Secrets:**
- The Supabase URL and anon key are public by design; RLS is the protection. They are passed per environment with `--dart-define-from-file`, using git-ignored `env/*.json` files and `*.example` templates.
- **Never in the binary or the repo:**
  - the Supabase `service_role` key;
  - the database password;
  - the RevenueCat secret API key and webhook secret;
  - the Apple `.p8` keys;
  - the Android upload keystore and its passwords;
  - the Sentry auth token.
- These live in CI secrets and Supabase function secrets.

**Store declarations:**
- App Store privacy labels.
- Google Play Data safety form **and** the Play Console Health apps declaration (menstrual tracking is a health feature).
- Privacy policy URL; medical disclaimer in-app and in the store listing.
- Export-compliance answers (SQLCipher uses standard encryption).

**Other protections:**
- Release builds are obfuscated (`--obfuscate --split-debug-info`), with symbols uploaded to Sentry.
- Debug-only tools (design overlay, component gallery) are compiled out of release builds.

---

## 13. State management

| Option | For | Against for this app |
|---|---|---|
| **Riverpod 3** | Dependency injection and state in one place; repositories are easy to override in tests (`ProviderScope.overrides`); `StreamProvider` maps straight onto Drift watch queries; `AsyncValue` models loading and error; little boilerplate | Provider scoping takes a day to learn |
| Bloc / Cubit | Very explicit events and states, great tooling | 3–4 files per screen; more ceremony than an app this size needs |
| Provider + ChangeNotifier | Simple | Weaker testability; no built-in async state; easy to create rebuild bugs |
| signals / GetX | Small | GetX hides too much; signals' ecosystem is thinner for DI and testing |

**Recommendation: Riverpod 3 with providers written by hand.**
- Every provider is a readable line of Dart you can step into. Code generation can be adopted later, once the patterns feel familiar.
- **Patterns used:**
  - `Provider` for repositories and services;
  - `StreamProvider` for watched data;
  - `Notifier` / `AsyncNotifier` for screen controllers (onboarding, recipe filters, shopping actions, Home preview).
- **The only code generation in the project:** Drift (required) and `json_serializable` for the content file.

**Shared session state:** `viewingPhaseProvider` (resets to the actual phase on cold start and on resume), `recipeFilterProvider` (meal type plus one ingredient; cleared when the phase changes and the ingredient isn't in the new phase), `homePreviewProvider`.

---

## 14. Routing (go_router)

```
/onboarding                     (redirect target until onboarding is complete)
  /onboarding/welcome, /last-period, /cycle-length, /food-preferences, /your-phase
StatefulShellRoute.indexedStack (custom MoonTabBar; each tab keeps its own stack)
  /home
  /foods
  /recipes
    /recipes/:recipeId          (recipe detail inside the Recipes stack)
  /shop
  /settings
    /settings/my-cycle, /food-preferences, /allergies, /notifications,
    /account, /subscription, /privacy, /help, /delete-account
/auth/sign-in, /auth/verify     (later; presented over the shell)
```
- **Bottom sheets** (ingredient sheet, Cook with…) are **not** routes. They open with `showModalBottomSheet` from Home, Foods and Recipes, as the PRD specifies.
- **"See N recipes with X":**
  - set `viewingPhase` and `recipeFilter` in Riverpod, then `navigationShell.goBranch(recipes)`;
  - the filter is state, not URL;
  - deep links resolve into the same state-plus-branch call.
- **Tapping the active tab again** returns that tab to its root and scrolls to the top (a `PrimaryScrollController` per branch).
- **Deep links (later):** universal links / App Links for `/recipes/:id` and `/foods?phase=`, plus the auth callback. The router's redirect still applies the onboarding gate first.

---

## 15. Project tree

```
moon_cycle/
├─ pubspec.yaml · analysis_options.yaml (very_good_analysis or flutter_lints + strict) · README.md
├─ docs/
│  ├─ architecture.md · design-deviations.md · release-checklist.md
│  └─ adr/ 001-flutter.md 002-supabase-auth.md 003-drift.md 004-riverpod.md 005-local-first.md
├─ design/                      # read-only copy of the approved handoff (v3): spec, PNGs, tokens
├─ content/                     # single content source (section 8.1)
│  phases.json foods.json phase_foods.json recipes.json aisles.json allergens.json …
├─ tool/  validate_content.dart · build_content.dart · check_layers.dart
├─ assets/  fonts/ · icons/ · logo/ · images/recipes/ · content/content.json
├─ env/  development.json.example · staging.json.example · production.json.example
├─ supabase/
│  ├─ config.toml · migrations/ · seed/content.sql
│  ├─ functions/ delete-account/ · revenuecat-webhook/ (later)
│  └─ tests/ rls_*.test.sql (pgTAP)
├─ lib/
│  ├─ main_development.dart · main_staging.dart · main_production.dart · bootstrap.dart
│  ├─ app/
│  │  ├─ app.dart                      # MaterialApp.router, themes, text scaling clamp
│  │  ├─ config/ app_config.dart · flavor.dart
│  │  ├─ router/ app_router.dart · routes.dart · onboarding_redirect.dart
│  │  └─ shell/ main_shell.dart · moon_tab_bar.dart
│  ├─ core/
│  │  ├─ domain/ phase.dart · local_date.dart · result.dart
│  │  ├─ design/
│  │  │  ├─ tokens/ colors.dart · phase_palette.dart · hero_palette.dart · typography.dart · spacing.dart · radii.dart · sizes.dart
│  │  │  ├─ moon_theme.dart            # ThemeData + ThemeExtension<MoonColors>
│  │  │  ├─ widgets/ moon_button.dart · text_link.dart · phase_selector.dart · pill_chip.dart · round_checkbox.dart
│  │  │  │          list_row.dart · section_head.dart · overline.dart · editorial_heading.dart · number_stepper.dart
│  │  │  │          month_calendar.dart · moon_bottom_sheet.dart · undo_toast.dart · recipe_photo.dart
│  │  │  │          wordmark.dart · moon_icon.dart
│  │  │  └─ debug/ design_overlay.dart · component_gallery.dart   (debug builds only)
│  │  ├─ database/ app_database.dart · tables/*.dart · migrations/ · encryption_key_store.dart
│  │  ├─ sync/ (milestone 18) sync_engine.dart · outbox.dart · conflict_rules.dart
│  │  ├─ supabase/ supabase_providers.dart · secure_session_storage.dart
│  │  ├─ time/ clock_provider.dart · today_provider.dart   # ticks at local midnight and on resume
│  │  └─ observability/ crash_reporter.dart
│  └─ features/
│     ├─ cycle/
│     │  ├─ domain/ cycle_profile.dart · period_log.dart · phase_range.dart · cycle_calculator.dart
│     │  │          cycle_state.dart · cycle_averages.dart · cycle_config.dart · cycle_validation.dart
│     │  ├─ data/ cycle_repository.dart · drift_cycle_repository.dart
│     │  └─ application/ cycle_providers.dart (cycleStateProvider) · viewing_phase_provider.dart
│     ├─ content/              # read-only catalogue
│     │  ├─ domain/ food.dart · food_category.dart · phase_content.dart · recipe.dart · recipe_ingredient.dart
│     │  │          recipe_category.dart · aisle.dart · allergen.dart · diet.dart · catalogue_filter.dart
│     │  ├─ data/ content_repository.dart · bundled_content_source.dart · content_dto.dart
│     │  └─ application/ content_providers.dart · filtered_catalogue_provider.dart
│     ├─ onboarding/
│     │  ├─ application/ onboarding_draft.dart · onboarding_controller.dart
│     │  └─ presentation/ onboarding_flow.dart · welcome_page.dart · last_period_page.dart
│     │                   cycle_length_page.dart · food_preferences_page.dart · phase_reveal_page.dart
│     │                   widgets/ onboarding_progress.dart · organic_shapes.dart
│     ├─ home/
│     │  ├─ application/ home_preview_controller.dart · home_sections_provider.dart
│     │  └─ presentation/ home_page.dart · widgets/ moon_orbit.dart · moon_orbit_painter.dart · orbit_spec.dart
│     │                   hero_background.dart · home_hero.dart · focus_section.dart · foods_today.dart
│     │                   recipes_today.dart · shopping_block.dart
│     ├─ foods/presentation/ foods_page.dart · ingredient_sheet.dart · widgets/ food_row.dart · recipe_count_badge.dart · on_list_mark.dart
│     ├─ recipes/
│     │  ├─ application/ recipe_filter_controller.dart · recipe_list_provider.dart
│     │  └─ presentation/ recipes_page.dart · recipe_detail_page.dart · cook_with_sheet.dart
│     │                   widgets/ meal_tabs.dart · cook_with_field.dart · recipe_feature_card.dart · recipe_grid_card.dart
│     ├─ shopping/
│     │  ├─ domain/ shopping_item.dart · shopping_source.dart · quantity.dart · item_key.dart · shopping_merger.dart
│     │  ├─ data/ shopping_repository.dart · drift_shopping_repository.dart
│     │  ├─ application/ shopping_controller.dart · shopping_summary_provider.dart
│     │  └─ presentation/ shop_page.dart · widgets/ shop_summary.dart · add_item_field.dart · shop_row.dart · done_section.dart
│     ├─ preferences/
│     │  ├─ domain/ user_preference.dart · food_avoidance.dart
│     │  ├─ data/ preferences_repository.dart · drift_preferences_repository.dart
│     │  └─ presentation/ food_preferences_page.dart · allergies_page.dart · widgets/ diet_pills.dart · avoidance_chips.dart
│     ├─ settings/presentation/ settings_page.dart · my_cycle_page.dart · notifications_page.dart · privacy_data_page.dart
│     │                         help_page.dart · account_page.dart · subscription_page.dart · delete_account_page.dart
│     ├─ reminders/ domain/ reminder_planner.dart · data/ local_notification_scheduler.dart · application/ reminder_sync.dart
│     ├─ privacy/ data_export_service.dart · local_data_wiper.dart
│     ├─ entitlements/ domain/ tier.dart · feature.dart · feature_gate.dart · entitlement_state.dart
│     │                data/ entitlement_source.dart · launch_promo_source.dart · (later) revenuecat_source.dart
│     │                application/ entitlement_providers.dart
│     └─ auth/ (milestone 17) domain/ app_user.dart · data/ auth_repository.dart
│              application/ auth_controller.dart · presentation/ sign_in_page.dart · verify_code_page.dart · account_merge_sheet.dart
├─ test/                        # mirrors lib/; plus goldens/ and fixtures/
└─ integration_test/ onboarding_flow_test.dart · foods_to_shop_flow_test.dart · recipe_to_shop_flow_test.dart · settings_edit_cycle_test.dart
```

---

## 16. Testing strategy

| Layer | What | Tooling |
|---|---|---|
| Domain unit | Cycle calculator and averages (section 6.4), shopping merger (9.3), catalogue filters (diet, allergens), feature gates, onboarding validation, angle↔day conversion | `test` + a fixed `Clock` |
| Data | Drift repositories on an in-memory database; **migration tests** for every schema version; content validator | `drift_dev` schema tests |
| Widget | Every design component; each screen with fake repositories; Dynamic Type at 1.0× and the maximum; dark mode; semantics labels | `flutter_test`, `mocktail` |
| Golden | Components + every screen, light and dark, 390 × 844 and 320 × 568; the moon in all phase and late states | Built-in goldens, run on **one fixed CI OS** (goldens are OS-sensitive) |
| Integration | Onboarding → Home shows the correct phase; Foods → ingredient sheet → add → Shop shows the item with its source; recipe → add ingredients → merged quantities; Settings → change cycle → Home updates; Clear all → Undo | `integration_test` on a simulator and an emulator |
| Backend | RLS isolation, anon access, entitlement write-protection, the delete-account cascade | `supabase test db` (pgTAP) against local Supabase in CI |
| Sync (later) | Two-client simulations: offline edits on both sides, tombstones, duplicate shopping keys, clock skew | Dart tests against local Supabase |

**Essential before App Store submission:**
- every cycle edge case in section 6.4;
- every shopping merge case in section 9.3;
- onboarding validation;
- the four integration journeys;
- the RLS suite (if accounts ship);
- the delete-account cascade (if accounts ship);
- local data wipe and export;
- Drift migration tests;
- golden tests of every shipped screen;
- a manual VoiceOver and TalkBack pass;
- a manual pass on the smallest and largest supported phones.

---

## 17. Environments, release and CI/CD

| Item | Plan |
|---|---|
| Identifiers | iOS bundle ID and Android `applicationId`: `com.<yourcompany>.mooncycle`, with `.dev` / `.stg` suffixes for the other flavours, so all three install side by side. Choose the reverse-domain now; **it can never change after release** |
| Flavours | Flutter flavours plus Xcode schemes and Android product flavours: development, staging, production. Each has its own app name, icon badge, `env/*.json` and Supabase project |
| Supabase | Development = local Supabase (CLI + Docker). Separate **staging** and **production** projects. Schema changes only through migrations in `supabase/migrations`. CI applies them to staging on merge to `main`, and to production on a release tag with manual approval |
| Signing (iOS) | Apple Developer Program (an organisation account needs a D-U-N-S number, which takes days). App Store Connect API key for uploads. Certificates via Fastlane match or Codemagic-managed signing |
| Signing (Android) | Upload keystore stored in CI secrets and a password manager; **Play App Signing** on |
| CI (every PR) | GitHub Actions: format check, `flutter analyze`, `check_layers`, content validation, unit, widget and golden tests, `supabase test db` |
| CD (builds) | **Codemagic** (simplest signing for a solo Flutter developer), or GitHub Actions on macOS runners with Fastlane. A tag on `main` → TestFlight + Play internal testing |
| Beta | TestFlight internal, then external testers. **Google Play: new personal developer accounts must run a closed test with at least 12 testers for 14 consecutive days before production access.** Start this early (milestone 15), or use an organisation account |
| Store submission | Screenshots from the production flavour; privacy labels; Data safety; Health apps declaration; review notes explaining that no account is needed; a medical disclaimer |

---

## 18. Build plan (sequential milestones)

Changes from your order, and why:
- **Cycle domain moves to 2.** It is pure Dart, the riskiest logic, and everything depends on it.
- **Local persistence moves to 5, before onboarding.** Building screens on in-memory state and then retrofitting persistence doubles the work.
- **A content-pipeline milestone is added (6).** Foods, Recipes and Shop all depend on it.
- **The shopping domain (9) comes before Foods.** Foods needs "add to list" and the on-list mark.
- **Local reminders (14) come before the backend.** They're on-device only.
- **A local-only internal beta comes at 15.** It gets real feedback before any backend work and starts the 14-day Play closed test.
- **Release decision:** milestone 20 can follow 15 directly (**v1.0 local-only**, recommended), with 16–18 shipping as v1.1.

Every milestone ends with green CI and a tag `m<NN>-<name>`. Commits use Conventional Commits.

---

**M0: Pre-flight (no app code)**
1. **Goal:** remove the blockers.
2. **Deliverables:**
   - Emergent repository added locally.
   - Recipe details and quantities extracted.
   - Aisle, diet and allergen metadata authored and reviewed.
   - Handoff v3 regenerated (canvas version 80).
   - The undrawn screens of section 5.7 designed.
   - Answers to section 20.
   - Developer accounts started (Apple; Google Play organisation or personal).
3. **Dependencies:** none.
4. **Tests:** none.
5. **Done when:** every section 20 question is answered and `content/` sources are approved.
6. **Commit:** none; the docs are committed in M1.

**M1: Repository and Flutter foundation**
1. **Goal:** an empty app that builds three flavours on both platforms, with CI.
2. **Files and features:**
   - `flutter create` with organisation ID; flavours and `main_*.dart`; `bootstrap.dart`; `app/config`.
   - `analysis_options.yaml` (strict); `docs/` and ADRs; `env/*.example`.
   - GitHub Actions CI; `tool/check_layers.dart`.
3. **Dependencies:** `flutter_riverpod`, `very_good_analysis` (dev).
4. **Tests:** a smoke widget test; the layer check.
5. **Done when:** three flavours run on the iOS Simulator and Android emulator, and CI is green on a PR.
6. **Commit:** `chore: scaffold flutter app with flavors and CI` → `m01-foundation`.

**M2: Cycle domain**
1. **Goal:** a complete, tested cycle engine with no UI.
2. **Files and features:** `core/domain/phase.dart`, `local_date.dart`; `features/cycle/domain/*`.
3. **Dependencies:** `clock`, `collection`, `meta`.
4. **Tests:** every case in section 6.4; aim for 100% line coverage on this folder.
5. **Done when:** the outputs match the handoff `cycle.ts` for a 200-case table generated from it, and the late, averaging and validation rules are tested.
6. **Commit:** `feat(cycle): phase calculator, averages and validation` → `m02-cycle-domain`.

**M3: Design system (tokens, fonts, assets, components)**
1. **Goal:** every visual building block, exact to the handoff.
2. **Files and features:**
   - `core/design/tokens/*`, `moon_theme.dart`, all `widgets/`.
   - Fonts and SVG assets; `debug/component_gallery.dart` and `design_overlay.dart`.
   - `MoonOrbit` painter (with static inputs).
3. **Dependencies:** `flutter_svg`, `vector_graphics_compiler` (dev).
4. **Tests:** goldens of every component in light and dark; a contrast test for every token pair; orbit geometry unit tests.
5. **Done when:** the gallery side by side with the System board passes your visual sign-off, and deviations are logged.
6. **Commit:** `feat(design): tokens, typography and core components` → `m03-design-system`.

**M4: App shell and navigation**
1. **Goal:** the five tabs with preserved stacks and a stubbed onboarding gate.
2. **Files and features:** `app/router/*`, `app/shell/*`, placeholder pages, re-tap-to-root and scroll-to-top.
3. **Dependencies:** `go_router`.
4. **Tests:** widget tests for tab switching, stack preservation, re-tap, and the redirect when onboarding isn't complete.
5. **Done when:** navigation matches the PRD's tab mechanics, and the tab bar matches its golden test.
6. **Commit:** `feat(app): shell, tab bar and router` → `m04-shell`.

**M5: Local persistence**
1. **Goal:** an encrypted Drift database and the user repositories.
2. **Files and features:**
   - `core/database/*` (tables of section 8.3 plus the outbox, unused until M18);
   - repositories for cycle, preferences and app state; `encryption_key_store.dart`;
   - the first-run Keychain cleanup.
3. **Dependencies:** `drift`, `drift_flutter`, `sqlcipher_flutter_libs`, `flutter_secure_storage`, `path_provider`, `uuid`, `drift_dev` and `build_runner` (dev).
4. **Tests:** in-memory repository tests; schema version 1 snapshot for migration testing; the encryption key round-trip.
5. **Done when:** data survives an app restart, and the database file can't be read without the key.
6. **Commit:** `feat(data): encrypted drift database and repositories` → `m05-persistence`.

**M6: Content pipeline and catalogue**
1. **Goal:** approved content bundled and queryable.
2. **Files and features:**
   - `content/*.json`; `tool/validate_content.dart` and `build_content.dart`;
   - `features/content/*`, including catalogue filters.
3. **Dependencies:** `json_annotation`, `json_serializable` (dev).
4. **Tests:** the validator in CI; filter tests (diet, allergens); a placement-preservation test (each phase's foods match the Emergent export exactly).
5. **Done when:** 157 foods, 4 phases and 12 recipes load offline, and the `shipReady: false` items are absent.
6. **Commit:** `feat(content): content pipeline and catalogue repository` → `m06-content`.

**M7: Onboarding**
1. **Goal:** the five-step flow, persisted, with the gate live.
2. **Files and features:** `features/onboarding/*`; the calendar, stepper, diet and avoidance widgets; the reveal using `MoonOrbit`.
3. **Dependencies:** `intl`.
4. **Tests:** step validation; the draft controller; widget tests for each step; integration test: onboarding → Home with the correct phase for a fixed clock.
5. **Done when:** every step matches its PNG in light and dark, and a killed app resumes correctly (onboarded or not).
6. **Commit:** `feat(onboarding): five-step onboarding with persistence` → `m07-onboarding`.

**M8: Home**
1. **Goal:** the hero (moon, orbit, wash, drag preview) and every Home section.
2. **Files and features:** `features/home/*`; `today_provider` (midnight tick and resume); `viewing_phase_provider`.
3. **Dependencies:** none new.
4. **Tests:** moon goldens (section 5.5); preview controller; Home in all four phases and the late state; semantics/adjustable test.
5. **Done when:** it matches `light-06-home` and `dark-06-home` plus the hero-phases board, and drag preview never changes the other tabs.
6. **Commit:** `feat(home): moon orbit hero and home sections` → `m08-home`.

**M9: Shopping domain and repository**
1. **Goal:** the merge algorithm and storage, before any UI needs them.
2. **Files and features:** `features/shopping/domain/*`, `data/*`, `application/shopping_controller.dart`.
3. **Dependencies:** none new.
4. **Tests:** every case in section 9.3; repository transaction tests; the undo timer with a fake clock.
5. **Done when:** an API exists for every PRD shopping behaviour, all of it tested.
6. **Commit:** `feat(shopping): item keys, merge rules and repository` → `m09-shopping-domain`.

**M10: Foods and ingredient sheet**
1. **Goal:** the Foods screen and the ingredient sheet (Home and Foods entry points).
2. **Files and features:** `features/foods/*`; the shared phase selector wiring.
3. **Dependencies:** none new.
4. **Tests:** food rows (count, chevron, on-list mark, pressed state); the sheet (hides the recipe button at 0 recipes; "On your list" state); integration: Foods → add → Shop data.
5. **Done when:** it matches `light/dark-07-foods` and the newly drawn sheet design.
6. **Commit:** `feat(foods): foods screen and ingredient sheet` → `m10-foods`.

**M11: Recipes, Cook with… and recipe detail**
1. **Goal:** filters, list, detail, and adding a recipe to Shop.
2. **Files and features:** `features/recipes/*`.
3. **Dependencies:** none new.
4. **Tests:** filter controller (phase change clears an invalid ingredient); empty states; detail "Added to shopping list" state; integration: recipe → Shop with merged quantities and skipped avoided items.
5. **Done when:** it matches `08-recipes` and the drawn detail screen, and back from detail restores filters and scroll position.
6. **Commit:** `feat(recipes): recipe list, filters and detail` → `m11-recipes`.

**M12: Shop**
1. **Goal:** the full Shop UI.
2. **Files and features:** `features/shopping/presentation/*`, the Undo toast.
3. **Dependencies:** none new.
4. **Tests:** widget tests for aisle grouping, collapsed Done, Clear all → Undo, × remove, the add field; goldens.
5. **Done when:** it matches `09-shop`, and the counts on Home update live.
6. **Commit:** `feat(shop): shopping list screen` → `m12-shop`.

**M13: Settings, preferences and privacy (local)**
1. **Goal:** every Settings screen that works without an account.
2. **Files and features:**
   - `features/settings/*`, `preferences/*`, `privacy/*`;
   - My Cycle (history, log a period);
   - entitlement scaffold with the launch promo; a Subscription row showing the promo status.
3. **Dependencies:** `share_plus`, `url_launcher`, `package_info_plus`.
4. **Tests:** editing the cycle updates Home; diet and avoidance changes filter Foods and Recipes; export JSON schema test; the wipe test (database file gone, notifications cancelled); feature-gate tests.
5. **Done when:** it matches `10-settings` and the drawn sub-screens.
6. **Commit:** `feat(settings): settings, preferences, export and wipe` → `m13-settings`.

**M14: Local reminders**
1. **Goal:** phase-change and period reminders, entirely on the device.
2. **Files and features:** `features/reminders/*`; a permission priming screen; rescheduling whenever cycle data or preferences change.
3. **Dependencies:** `flutter_local_notifications`, `timezone`, `flutter_timezone`.
4. **Tests:** the reminder planner (pure: dates from cycle state); scheduler with a fake plugin; the schedule recomputes after a period log.
5. **Done when:** reminders fire correctly on both platforms across a simulated cycle, and turning them off cancels everything.
6. **Commit:** `feat(reminders): local phase and period reminders` → `m14-reminders`.

**M15: Hardening and internal beta (local-only)**
1. **Goal:** production-quality v1 candidate in testers' hands.
2. **Work:**
   - Accessibility pass; small and large device pass; dark-mode audit; performance (frame timing on the Home hero).
   - Sentry with obfuscation symbols; app icons and splash.
   - TestFlight internal + Play closed testing (**starts the 14-day clock**).
3. **Dependencies:** `sentry_flutter`.
4. **Tests:** the full essential set (section 16); manual VoiceOver and TalkBack.
5. **Done when:** no P1 bugs, crash-free sessions above 99.5% in beta, and the design-deviation log is signed off.
6. **Commit:** `chore(release): beta hardening` → `m15-beta`.

**M16: Supabase backend**
1. **Goal:** schema, RLS and functions in staging and production; no app integration yet.
2. **Files and features:** `supabase/migrations/*` (user and content tables, triggers for `server_updated_at` and last-write-wins), RLS policies, `seed/content.sql`, the `delete-account` function, pgTAP tests, CI for migrations.
3. **Dependencies:** Supabase CLI (dev tooling).
4. **Tests:** the RLS isolation suite; the cascade delete; the last-write-wins trigger.
5. **Done when:** CI applies migrations to staging; the pgTAP suite is green; production is provisioned in the chosen region.
6. **Commit:** `feat(backend): supabase schema, RLS and delete-account` → `m16-backend`.

**M17: Authentication and account**
1. **Goal:** optional account creation, sign-in, sign-out (with wipe), deletion.
2. **Files and features:** `features/auth/*`; secure session storage; the consent step; Account and Delete Account screens.
3. **Dependencies:** `supabase_flutter`, `sign_in_with_apple`, `google_sign_in`, `crypto` (nonce).
4. **Tests:** the auth controller with a fake client; integration test on staging (email code sign-in, delete account → rows gone).
5. **Done when:** Apple, Google and email sign-in work on both platforms in staging, and deletion is verified.
6. **Commit:** `feat(auth): supabase auth with apple, google and email code` → `m17-auth`.

**M18: Sync**
1. **Goal:** the outbox push, the cursor pull, the first-sign-in upload or merge, and the shopping dedupe.
2. **Files and features:** `core/sync/*`; the account merge prompt; a sync status in Settings › Account.
3. **Dependencies:** `connectivity_plus` (optional).
4. **Tests:** the two-client simulation suite (section 16); offline → online; tombstones; skewed clocks.
5. **Done when:** two devices converge in every scenario in the suite, and no data is lost in airplane-mode tests.
6. **Commit:** `feat(sync): local-first sync with supabase` → `m18-sync`.

**M19: Analytics (optional)**
1. **Goal:** a minimal, privacy-reviewed set of product events.
2. **Files and features:** an `analytics/` facade with an allow-listed event catalogue; opt-in or opt-out per your policy.
3. **Dependencies:** `posthog_flutter` (EU) or a TelemetryDeck SDK.
4. **Tests:** the event catalogue contains no forbidden properties.
5. **Done when:** the privacy labels are updated.
6. **Commit:** `feat(analytics): privacy-safe product analytics` → `m19-analytics`.

**M20: Release 1.x**
1. **Goal:** App Store and Play production release.
2. **Work:** store listings, screenshots, privacy labels, Data safety, the Health declaration, the privacy policy, review notes, a phased rollout.
3. **Dependencies:** none.
4. **Tests:** the release checklist (`docs/release-checklist.md`); a smoke test on the production flavour against the production backend.
5. **Done when:** approved and live, with monitoring in place.
6. **Commit:** `chore(release): v1.0.0` → tag `v1.0.0`.

**M21: Subscriptions (later)**
1. **Goal:** Plus via RevenueCat.
2. **Files and features:** `revenuecat_source.dart`; the paywall (designed first); Restore Purchases; the `revenuecat-webhook` Edge Function; App Store and Play products.
3. **Dependencies:** `purchases_flutter`.
4. **Tests:** entitlement merging (promo + RevenueCat + grant); webhook signature verification; sandbox purchase, restore and expiry.
5. **Done when:** sandbox and production purchase flows work, and gates flip correctly when a subscription expires.
6. **Commit:** `feat(entitlements): revenuecat subscriptions` → `m21-subscriptions`.

---

## 19. Major risks and unknowns

| Risk | Impact | Mitigation |
|---|---|---|
| **Allergy filtering errors** | A user who avoids an allergen is shown or sent a food that contains it. This is a safety issue | Authored, reviewed allergen data including non-catalogue recipe lines; conservative matching (unknown = not safe for avoidance); in-app wording "Always check labels"; a dedicated test suite |
| Recipe data unavailable | Recipe detail and quantity merging can't be built | Get the Emergent repository in M0; otherwise recipes ship as ingredient-tag-only cards until content is written and reviewed (a content decision, not an engineering one) |
| Undrawn screens | Implementation stalls or improvises design | Design them in M0, before each milestone |
| Health-claim and regulatory exposure | App Store or Play rejection, user harm | Content stays as approved; claims follow the audit's evidence notes; medical disclaimer; no diagnosis or fertility claims (the ovulatory phase must never read as contraception guidance) |
| Privacy perception of cycle data | Trust, store review | Local-first default, no ad SDKs, explicit consent before upload, EU region, export and deletion |
| Google Play 14-day closed-test rule | A release delay of 2+ weeks | Start the closed test at M15, or register as an organisation |
| Late or irregular cycles | Wrong phase shown for weeks | Late-state design plus a "period started?" prompt; averaging with outliers excluded; easy logging |
| Font rendering differences | "Not exact" perception | The overlay tool, `TextLeadingDistribution.even`, and agreed tolerances in the deviation log |
| Recipe photography licensing | Unlicensed images in the store | Ship tinted placeholders until licensed photos exist |
| Solo maintenance bus factor | Knowledge lives in one head | ADRs, the architecture doc, the layer check, tests as documentation, small milestones |

---

## 20. Questions to answer before coding

Each question comes with my recommended default, so you can simply confirm.

**Product and release**
1. Should v1.0 be **local-only** (no account), with accounts and sync in 1.1? *Recommended: yes.*
2. **Store identity:** the developer/company name, the reverse-domain for bundle IDs (for example `com.yourcompany.mooncycle`), and whether the Google Play account is personal or an organisation. *Recommended: organisation, if you have a company.*
3. Which **markets and languages** at launch? *Recommended: English only, EU + UK + US, Supabase in the EU. This affects GDPR and the region.*
4. Supported devices: phones only, portrait, iOS 15+ / Android 8+? *Recommended: yes.*
5. **Free vs Plus:** which features will be Plus, and is the launch promo a fixed date for everyone, or 90 days per user from install?

**Cycle behaviour**
6. Late period: from which day late does Home prompt "Has your period started?" *Recommended: 3 days late.* After how many days late do we stop showing phase guidance and ask for an update? *Recommended: cycle length + 30.*
7. Should cycle and period averages **override** the values the user typed once 3 cycles exist, or should the user opt in? *Recommended: automatic, with a visible "based on your last N cycles" and a switch.*
8. Should the onboarding last-period date be limited, for example to the last 60 days? *Recommended: allow up to 90 days back and show the late state if needed.*
9. The hero line "Day 7 of 28 in cycle" when late: "Day 32 of 28"? Or "Day 32 · period 4 days late"? (Needs design.)

**Content and food data**
10. Where do recipe quantities, steps, intros, servings and times come from: the Emergent repository, or new writing (which needs review)?
11. Who authors and reviews **allergen and diet metadata**, and must allergy exclusion be strict, hiding everything uncertain? *Recommended: strict.*
12. Foods screen: should avoided foods be **hidden** or **shown marked**? (Needs design.)
13. Adding a recipe to Shop: include non-catalogue staples (oil, salt), or only key ingredients? *Recommended: all lines, grouped under Pantry.*
14. Should the 26 open content flags (Lychee category, Eggs under Meat, the four not-ship-ready items) be resolved **before** M6?

**Design**
15. May I draw the undrawn screens in section 5.7 on the canvas now, in the Editorial system?
16. Are any tolerances acceptable for "exact"? For example, font antialiasing differences and ±1 pt text metrics.

**Services**
17. Is dropping Firebase entirely (Sentry for crashes, no FCM in v1) acceptable, or do you want Crashlytics or Firebase Analytics for another reason?
18. Do you want product analytics at launch at all? *Recommended: no, until there's a question it answers.*
