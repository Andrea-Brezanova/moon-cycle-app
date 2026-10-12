# Decisions

One list of the decisions that shape this repository, newest first. Add a line when a decision changes, with the date and the reason.

## 12 October 2026: Milestone 13 (Settings)
- **Settings** is the v1 local-only variant: Personalisation, App, Account (Subscription, Privacy & Data; no Account row), Support, then "Delete my data" and the footer with the version. The debug Component gallery link sits under the footer in debug builds only. The placeholder pages are gone.
- **Cycle history averages** (`cycle/domain/cycle_history.dart`, plan §6.2): at least 3 completed cycles; gaps outside 21–45 days and gaps next to an estimated ("I'm not sure") start don't count; the 6 most recent valid gaps are averaged and rounded. Period length works the same way from periods with an end date in completed cycles (the current period doesn't count, matching the design's "last 3 periods" with 4 logged). `cycleStateProvider` now calculates with `effectiveLengths`; the user can switch averages off in the lengths sheet.
- **Entitlements** (`features/entitlements`, plan §10): tiers, features, grants resolved by highest valid tier, and `FeatureGate.canUse`, the only place the app asks. The launch promo grants Plus until the launch-free end date (`AppLinks.launchFreeEndDate`, unset). Every feature needs only Free until the Plus list is decided (`open-questions.md` 10), so no UI is gated yet.
- **Export** (`features/privacy`): JSON (`format: moon-cycle-export`, `version: 1`; profile, periods, diet, avoidances, reminders, shopping list; no derived values) plus a CSV of periods, written to temporary files, shared with the system share sheet, then deleted.
- **Delete my data:** `LocalDataWiper` runs extra steps (reminders in M14), closes the database, deletes the database files (and any unreadable copies) and the Keychain/Keystore key. `AppRoot` then replaces the whole `ProviderScope`, opens a fresh database with a new key and starts at onboarding, so no state from before survives.
- **Addresses not yet given** (support email, policy URLs, launch-free date) live in `lib/app/config/app_links.dart` and show placeholders or disabled controls (`open-questions.md` 7, 8).
- **List rows are 80 pt** (64 inside 8 pt padding): the canvas uses CSS content-box sizing. Measured against `25-settings-v1-local` and `26-settings-my-cycle`.
- **Tab roots clip scrolled content below the status bar** (Foods, Recipes, Shop, Settings); Home keeps its hero under the status bar.
- **Packages:** `share_plus` (share sheet for the export), `url_launcher` (policy pages, support email), `package_info_plus` (version in the footer). All are Flutter Community / Flutter team plugins, as planned in §18.

## 11 October 2026: Milestone 12 (Shop)
- **Shop** shows To buy by aisle in the fixed order (empty aisles hidden), a collapsed Done with its count and "Clear all", the add field, and the Undo toast for 8 seconds, 16 pt above the tab bar. The phase selector only sets context (PRD §4).
- **Source line:** "Phase staple", the recipe's title, "Added by you", joined with " + " (up to two lines); the dot is ochre for recipes and merged items, otherwise the staple's phase accent. "Merged" when an item has more than one source.
- **"N done"** shows once the list has anything; an empty list shows only "0 to buy" and the empty state (as on the canvas).
- **Quantities** are not shown on rows (as designed); see `open-questions.md` 6.
- **Text fields:** tapping outside puts the keyboard away; the add field keeps focus when submitting, which also fixes entries running together on iOS (found on the simulator).
- **Tests:** list changes in widget tests run in fake time and are pumped to completion; mixing real async with the database's fake-time queue deadlocks.

## 11 October 2026: Milestone 11 (Recipes)
- **Filters** (`recipeFilterProvider`): meal type and one "Cook with…" food on top of the shared viewing phase; a new phase clears the food. `recipeListProvider` also counts what the empty states need (recipes the preferences allow; recipes with the food in other meal types).
- **Empty states** follow the canvas copy, with plurals and a fourth case for an ingredient that no recipe uses (deviation 23).
- **"Cook with…"** lists the viewing phase's foods the user eats, by category, with recipe counts; search matches names and synonyms. Tall sheets (`showMoonSheet(fromTop: 96)`) scroll inside.
- **Recipe detail** is inside the Recipes stack (back keeps filters and scroll; the photo's back button scrolls with the photo, system back and swipe-back work anywhere). "On your list" per line uses the same keys as the list (`lineKey`), so non-catalogue lines such as olive oil show it too. When every line is on the list the button becomes "✓ Added to shopping list" with "Open shopping list".
- **The detail back button keeps the canvas's shadow** (the only shadow besides the tab bar's hairline), because it floats on the photo.
- **Recipe photos** are the tinted placeholders until `open-questions.md` 5 is decided.

## 11 October 2026: Milestone 10 (Foods and the ingredient sheet)
- **One header for Foods, Recipes and Shop** (`PhaseHeader`): the H1, the shared phase selector and the "Your current phase · day 7" / "Browsing luteal · Back to follicular" line.
- **Foods** shows the viewing phase's foods per category in the stored order; avoided foods are hidden and a category left empty is hidden too (spec §7.3). Rows in a pair share a height so the dividers line up. The row of an open sheet shows the pressed (sand) state.
- **Recipe counts** per food count the viewing phase's recipes the user's preferences allow, i.e. what Recipes will show.
- **Ingredient sheet** uses the real phase from Home and the viewing phase from Foods (PRD §8). "Add to shopping list" keeps the sheet open and turns into the disabled "✓ On your list"; with no recipes the recipe button is hidden and "No recipes with X yet." shows. "See N recipes with X" keeps the phase, sets the Recipes ingredient filter (`recipeFilterProvider`, which also clears the ingredient when the phase changes) and opens the Recipes tab.

## 11 October 2026: Milestone 9 (shopping domain)
- **Keys:** `food:<id>` for catalogue foods and recipe lines linked to one; typed text and other recipe lines are matched against names and synonyms, else `text:<normalised>` in the Other aisle (recipe lines keep their own aisle, e.g. olive oil → Pantry). No plural guessing.
- **Merge** (`addToList`, pure): a new key creates an item; a known key gains a source unless the same reason (type + recipe/phase) is already there; a Done item added again moves back to To buy. Quantities are never stored on the item, only on sources.
- **Quantities** (`displayQuantity`): g+kg and ml+l are summed (shown in kg/l from 1000), every other unit separately, mass and volume never converted, words ("to serve") listed after, joined with " + ".
- **"On your list"** means To buy (PRD §8): Done items don't mark foods.
- **Remove (×)** is a tombstone with no Undo (spec). **Clear all** tombstones Done items and their sources with one timestamp; Undo restores exactly those for 8 seconds (an item added again meanwhile stays as the new one).
- **Recipe add** skips lines the user avoids (they're returned for the screen to name) and runs in one transaction.
- **Not yet:** the two-device duplicate merge (plan §9.2) belongs to sync (v1.1); locally a unique index already allows one live item per key.

## 11 October 2026: Milestone 8 (Home)
- **Home shows the real phase only;** `viewingPhaseProvider` (Foods, Recipes, Shop) follows it until the user picks another phase and resets on resume. Home's links set it back to the real phase.
- **Drag preview** is Home-local state (`homePreviewProvider`), cleared by a new day or a logged period. It's adjustable for screen readers (increase/decrease = next/previous day) with a selection haptic per day. A drag that starts on the ring wins over page scrolling (custom recognizer); elsewhere the page scrolls.
- **Late:** from day `cycleLength + 1` the hero says "Period N days late"; from 3 days late the "Has your period started?" card appears (spec §7.2). "Log my period" opens the Log a period sheet; logging restarts the cycle at day 1.
- **Logging rules** (`checkPeriodStart`): no future dates; not within 10 days of another logged start (the same date updates that log).
- **Foods for today:** the first food the user eats in each category, up to six (deviation 16). **Recipes for today:** the phase's recipes the preferences allow; none → the designed empty line.
- **Shopping block** reads `shoppingSummaryProvider`, which returns zeros until the shopping list exists (Milestone 9).
- **Food chip taps** open the ingredient sheet from Milestone 10.
- **Recipe photos:** tinted placeholders until you approve bundling the recovered photos (`open-questions.md` 5).

## 11 October 2026: Milestone 7 (onboarding)
- **Measurements from the canvas source:** the Editorial artboards' HTML (`Ed*.dc.html`, read from the design canvas) gives exact sizes, gaps and colours; the PNGs are the visual check. Golden screenshots of every onboarding screen in both themes are compared side by side with the PNGs.
- **Each step is a route** (`/onboarding`, `/onboarding/last-period`, …), so Android back and iOS swipe-back go one step back with answers kept. The answers live in memory until step 4, then one transaction saves the period, profile, diet, avoidances and "onboarding complete" (plan §7.2). The reveal can't go back.
- **Killed at the reveal:** everything is already saved, so the app reopens on the tabs.
- **No `intl`:** English date wording is a 40-line helper (`core/format/dates.dart`); v1 is English only.
- **"Today"** is a provider that updates at local midnight and when the app returns to the foreground (`core/time/today.dart`); tests fix the clock.
- **Cycle state** is a provider built from the stored profile and newest period (`cycleStateProvider`); the reveal and Home read it.
- **Status bar:** set app-wide from the theme; plum screens set light icons themselves.
- **Sheets cover the tab bar** (spec §6): `showMoonSheet` now opens on the root navigator and rises above the keyboard.
- **Design-system additions:** `InfoNote.plain`, the `welcomeBody` colour, `PinnedActionsScroll` (content at the top, actions at the bottom, scrolls when it doesn't fit), search hooks on `MoonTextField`; the on-plum ring mark now uses the theme's accents (the dark ring is brighter, as on the canvas).
- **Tests:** drift query streams close synchronously in tests, and database reads from widget tests go through `tester.runAsync`, otherwise fake-async widget tests hang or end with pending timers.

## 11 October 2026: Milestone 6 (content pipeline)
- **One copy of the content:** `assets/content/*.json` is both the reviewable source and the bundled asset. The plan's `tool/build_content.dart` step and generated file aren't needed: the audit notes stay in `design/content/` and never entered these files. `test/content/content_validation_test.dart` (in CI) proves placement, copy and recipes still match the handoff verbatim.
- **No `json_serializable`:** a hand-written, strict parser (about 150 lines) rejects unknown ids, so a content mistake fails a test instead of reaching a user. No new packages in this milestone.
- **Allergens = the nine chips in the design** (Peanuts, Tree nuts, Shellfish, Fish, Dairy, Eggs, Gluten, Soy, Sesame), not the EU-14 list in the plan. Shellfish covers crustaceans and molluscs.
- **Food metadata is an authored draft** (aisle, animal source, allergens, synonyms), derived from the audit's caution notes where possible and conservative elsewhere. It must be reviewed before release (`open-questions.md`).
- **Filter rules (plan §8.4):** diet by animal source; avoided allergens, foods and typed phrases (whole words, plural-tolerant, synonyms) exclude foods and recipe lines; a recipe is hidden if any line is excluded. Unknown-safe: when in doubt, leave it out.
- **Recipe key foods** are the recipe's Emergent ingredient tags; they drive recipe counts and "Cook with…".
- **Not-ship-ready foods** (Hijiki, Salt, Alcohol, Ketchup) keep their verbatim data in the file but are dropped when loading, so approving one is a one-flag change.
- **Loaded before the first frame** with the database, so screens read the catalogue synchronously.

## 11 October 2026: Milestone 5 (local persistence)
- **Packages:** `drift`, `sqlite3`, `flutter_secure_storage`, `path_provider`, `uuid`; `drift_dev` and `build_runner` for development. All are the standard, actively maintained choices for Drift.
- **Encryption: SQLite3MultipleCiphers, not `sqlcipher_flutter_libs`.** The plan named SQLCipher through `sqlcipher_flutter_libs`, which is end-of-life: `package:sqlite3` 3.x now bundles its own SQLite builds, chosen in `pubspec.yaml`. Of its two encrypting builds, SQLite3MultipleCiphers is the one its documentation recommends; it tracks current SQLite and needs no OpenSSL on Android. Same protection (256-bit key, `PRAGMA key`). Export compliance: standard encryption either way.
- **No `drift_flutter`:** the app opens the database itself, because the key must be read from secure storage first, and the opener checks the encrypting build is present.
- **Keychain item** uses "after first unlock", so reminders can read the database in the background, and the key moves to a new iPhone inside an encrypted backup together with the database.
- **Android backup and device transfer are off** for the app's data: the Keystore key never leaves the device, so a backed-up database couldn't be opened, and cycle data stays on the phone unless exported.
- **Lost key:** an unreadable database is moved aside and a fresh one starts, instead of the app failing to open.
- **Schema v1 has every user table** of plan §8.3, including shopping, so later milestones need no migration. **Not added yet:** the sync outbox and `lastPulledAt` (with sync in v1.1, as a v2 migration) and an entitlements table (v1's launch promo is a bundled date).
- **Period logs carry `isEstimated`** (the onboarding "I'm not sure" date) instead of a profile-level flag: it's the date that is uncertain.
- **Repositories are concrete classes** over Drift, tested on an in-memory database; no interface layer until a second implementation exists.
- **Onboarding state is stored from now on** (planned for M7): the gate's first value is read from the database before the first frame. The M4 stub is gone.
- **Generated code is committed** (`*.g.dart`), so CI and a fresh checkout build without running `build_runner`.

## 11 October 2026: Milestone 4 (shell and navigation)
- **One new package:** `go_router`.
- **Android back:** inside a tab, one screen back; on the first screen of Foods, Recipes, Shop or Settings, to Home; on Home, Android may close the app.
- **Transitions:** tab switches are instant, with no animation. Pages pushed inside a tab use the platform's standard transition, including iOS swipe-back.
- **Onboarding status is a stub** that starts as completed during development, so the app opens on Home. Both paths of the redirect are tested. Milestone 7 replaces it with the saved status.
- **"Delete my data" has no tab bar** (spec), so it opens above the shell; its back link still returns to Settings.
- **Debug gallery cannot ship:** its route exists only when `kDebugMode`, a compile-time constant, so release and profile builds drop the route and the gallery code. Checked by searching the prod release APK's compiled code: the gallery's text and class names are absent.
- **Screen-reader fix found while testing:** wrapping a `Pressable` in `Semantics(excludeSemantics: true)` also removed its tap action, and the sub-screen back link merged with the page title. `Pressable` now takes a `semanticLabel` and is always its own node; the back link, tab items, round icon buttons and chip remove buttons use it.
- **Golden diff images** (`failures/`) are git-ignored; eight committed by mistake in Milestone 3 are removed.

## 11 October 2026: Milestone 3 (design system)
- **Tokens:** ported value for value from `design/code/theme.ts`. The hero orbit colours equal the phase palettes, so the orbit reads the theme's palettes rather than a second copy.
- **Fonts bundled, never downloaded:** families `Fraunces72` (40 pt and up), `Fraunces24` (below 40), `DMSans` and `Gwendolyn`. `fraunces()` asserts if a weight the static cuts don't have is requested. Every Editorial style uses even leading (CSS-like line height) and no decoration.
- **Icons in code:** the 23 line icons are embedded from `design/assets/icons`, because the design draws them with different stroke widths per use. The wordmark, lockups and phase-ring mark stay SVG assets.
- **One new package:** `flutter_svg`.
- **Text size:** body text scales with the system up to 1.5×, headings up to 1.3×.
- **Golden tests** are made on macOS and tagged `golden`; CI runs `flutter test --exclude-tags golden`. Regenerate after an intentional visual change with `flutter test --tags golden --update-goldens`.
- **Undesigned states** (disabled, pressed, long labels) and font approximations are listed in `design-deviations.md` for sign-off.
- **Component gallery:** a debug-only screen (linked from the placeholder in debug builds) for comparing components with the design.

## 11 October 2026: Milestone 2 (cycle domain)
- **Pure Dart, "today" passed in:** the domain never reads the clock; `check_layers` rejects `DateTime.now(` in `domain/`.
- **Reference parity:** phase ranges are an exact port of `design/code/cycle.ts`, checked against a committed fixture for all 1,575 valid combinations. This proves parity with the approved reference algorithm only; it does not validate the algorithm's medical assumptions.
- **Estimates:** phases, the ovulatory window and the next-period date are calculated estimates. Field names say so (`estimatedNextPeriodDate`, `estimatedNextPhaseDate`), and later UI copy must not present estimated ovulation as a confirmed biological event.
- **Limits:** cycle 21–45 (default 28), period 2–10 (default 5), luteal 10–16 (default 14). Stored values outside the limits are clamped when calculating; input outside them is rejected by `checkCycleInput`.
- **Late period:** past the cycle length with no new period, the phase stays luteal, the cycle day keeps counting, the orbit marker and phase day stay on the last day, `daysToNextPhase` is 0 and `daysLate` counts up. When Home shows the "Has your period started?" card is a UI decision (the design says from 3 days late).
- **Long gaps:** a last period start of any past date is valid. More than 90 days ago is only flagged (`CycleInputWarning.lastPeriodStartOver90DaysAgo`, `CycleState.isLongGap`) so the UI can handle it later.
- **Future start dates are invalid:** `checkCycleInput` reports `lastPeriodStartInFuture`, and `calculateCycleState` throws `ArgumentError` rather than guessing.
- **History averages later:** the calculator only takes `CycleLengths`. Averages from logged periods will be a second way of building them (`LengthsSource.historyAverage`), added with period logging.

## 11 October 2026: Milestone 1
- **Baseline:** Flutter 3.47.7 stable, Dart 3.13.5, Xcode 26.3. CI pins the same Flutter version (`.github/workflows/ci.yaml`).
- **Flavours:** `dev` (`app.mooncycle.mobile.dev`, "Moon Cycle Dev") and `prod` (`app.mooncycle.mobile`, "Moon Cycle"). No `stg` until Supabase arrives in v1.1, because a local-only app has no distinct staging configuration.
- **One entry point** (`lib/main.dart`). The flavour comes from `--flavor`; settings from `--dart-define-from-file=env/<flavour>.json`; `AppConfig` checks they match.
- **Platforms:** iOS 15+ (iPhone only) and Android 8.0+ (minSdk 26), portrait only.
- **iOS flavours:** build configurations `Debug/Profile/Release-<flavour>`, schemes `dev` and `prod`. Bundle ID and display name live only in `ios/Flutter/dev.xcconfig` and `prod.xcconfig`. iOS plugins use Swift Package Manager (no CocoaPods).
- **Android flavours:** `productFlavors` in `android/app/build.gradle.kts`; the app name comes from a manifest placeholder (`${appName}`).
- **Design reference:** Editorial handoff v3 copied verbatim into `design/` (182 files), without the PDFs and zip. Treated as immutable: never regenerated or edited during development.
- **Architecture tooling:** only `tool/check_layers.dart`. No further enforcement tooling unless it solves a real problem.
- **Dependencies so far:** `flutter_riverpod` (and `flutter_lints` for development). Others are added in the milestone that first needs them.

## 11 October 2026: product and stack (from the technical plan)
- **v1.0 is local-only:** no account or sign-in. Supabase Auth and Postgres with RLS come in v1.1.
- **Stack:** Riverpod 3, go_router, Drift with an encrypted database, Sentry for crash reporting. No Firebase in v1.
- **Subscriptions:** feature gates in code, no RevenueCat yet. Everything is free until one fixed launch-free end date.
- **UI:** the Editorial direction (cream, plum and ochre) is the only visual source of truth.
- **App ID:** `app.mooncycle.mobile` (domain `mooncycle.app` is owned). It never changes after the first store upload.
