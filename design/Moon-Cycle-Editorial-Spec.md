# Moon Cycle: Editorial design spec (Cream, Plum & Ochre)

**For:** the Moon Cycle Flutter app (iOS and Android), repository `moon-cycle-app`  
**Design source:** Moon Cycle Redesign canvas, page "Editorial direction · Cream & Plum" (light and dark)  
**Base frame:** iPhone 390 × 844 pt  
**Version:** 3 (11 October 2026). Adds the phase-wash Home hero, the moon in the onboarding reveal, and every screen and state that was previously undrawn. Scope: **v1.0, local-only** (section 12).

The Editorial design is the **only** UI source of truth. Earlier directions on the canvas (Sorbet and the explorations) are superseded and must not be used. Behaviour follows section 8 (taken from the functional Emergent app). The architecture and milestones are in `flutter-plan/Moon-Cycle-Flutter-Technical-Plan.md`.

## Package contents

| Path | What it is |
|---|---|
| `Moon-Cycle-Editorial-Screens.pdf` | Every screen in light and dark, with notes |
| `Moon-Cycle-Editorial-Spec.md` / `.pdf` | This document |
| `README.md` | What is in this package and how to use it |
| `screens/` | PNG of every screen at @2x, numbered 01–37: `light-*.png` and `dark-*.png`, plus the system, summary and Home-hero-per-phase boards |
| `code/theme.ts` | All tokens for light and dark, Home hero colours per phase, moon and orbit geometry, typography and sizes |
| `code/cycle.ts` | Reference phase calculation (cycle day, phase ranges, orbit and ring geometry) |
| `assets/logo/` | Script wordmark (outlined SVG), Home header wordmark, lockups (SVG plus PNG) |
| `assets/mark/` | Phase ring mark in the new phase colours, including small-size versions and one-colour versions |
| `assets/app-icon/` | iOS light and dark icons, Android adaptive and monochrome, splash, favicon |
| `assets/icons/` | 23 line icons, 24 × 24, `stroke="currentColor"` |
| `assets/shapes/` | 3 organic shapes, `fill="currentColor"`. Onboarding and recipe placeholders only |
| `assets/ui/moon-hero-light-*.svg`, `moon-hero-dark-*.svg` | The Home moon and orbit for each phase, light and dark |
| `assets/fonts/` | Static TTFs: Fraunces (7 files), DM Sans (4 files) and Gwendolyn Bold (wordmark only), with their OFL licences |
| `assets/sample-images/` | The two placeholder recipe photos used in the mock-ups (not licensed for release) |
| `content/` | Ingredient-sheet copy (`ingredients.json`), recipe audit, sample content, all from the approved content audit |

---

## 1. Direction in one paragraph

A calm, editorial wellness app. Warm cream pages (deep night plum in dark mode), deep plum type, **one ochre action per screen**, and phase colours used like a highlighter: an orbit segment, a dot, a label. The Home hero is a soft ochre moon inside a four-phase orbit, on a faint wash of the phase colour in light mode and one night plum in dark mode. Large Fraunces headings and generous spacing replace boxes and borders. Lists use thin dividers rather than cards; a card appears only when it holds a photo or the one main action. Each screen has a single focal point.

**What changes:** palette; headings in Fraunces; fewer boxes; Foods as two-column rows with recipe counts; round checkboxes; a cream tab bar with an ochre dot; the moon hero on Home; a script wordmark (Gwendolyn Bold); a new five-step onboarding; dark mode built on the onboarding purple.
**What stays:** five tabs and the whole information architecture; Home shows the real phase only; Foods, Recipes and Shop share one phase; the ingredient → recipes flow and "Cook with…"; To buy / Done; the Settings structure; all approved content.

---

## 2. Themes

- Support **light and dark**, following the device setting (`ThemeMode.system`). No in-app theme switch in v1.
- Both themes use identical layouts; only the tokens change (`code/theme.ts` › `light` / `dark`).
- **Role swap in dark:** light-mode "plum" is the text colour *and* the colour of filled elements. In dark mode those roles map to `text` (cream) and `inverseBg` (cream) with `inverseText` (deep plum). Always use the semantic token names, never raw hex values.
- **Onboarding welcome** uses `welcomeBg`: plum `#37255C` in light, hero purple `#2A1F47` in dark.
- **Dark mode is built on the onboarding purple:** the page is the deepest plum, surfaces are hero purple, cards and selected states a lighter plum. Use ochre sparingly in dark: the single CTA, the active-tab dot and progress only.

---

## 3. Colour

### 3.1 Core tokens

| Token | Light | Dark | Use |
|---|---|---|---|
| `bg` | `#FCFAF5` | `#1B152E` | Page background |
| `raised` | `#FFFFFF` | `#2A1F47` | Inputs, tab bar, calendar card, info notes |
| `sand` | `#ECE3D2` | `#332650` | Chips, round icon buttons, pressed food row, count pill |
| `line` | `#E3D9C8` | `#4A3C63` | Hairline dividers, progress track |
| `text` | `#37255C` | `#FFFDF8` | Headings, body, icons |
| `textMuted` | `#5F527A` | `#C8C1D3` | Secondary text, overlines, inactive tabs |
| `inverseBg` / `inverseText` | `#37255C` / `#FCFAF5` | `#FFFDF8` / `#1B152E` | Secondary button, pressed chip, selected date |
| `shopBlockBg` / `shopBlockText` | `#37255C` / `#FCFAF5` | `#2A1F47` / `#FFFDF8` | "Your shopping list" block on Home |
| `ochre` / `onOchre` | `#E4AC24` / `#37255C` | `#F1B821` / `#1B152E` | Primary button, active-tab dot, progress fill, link underline |
| `checkboxBorder` | `#B9AEC9` | `#7A6D96` | Unchecked round checkbox |
| `chevron` | `#C9C0D3` | `#6B5E87` | Food rows with 0 recipes |
| `removeIcon` | `#9A8FAD` | `#9A8FAD` | × on shopping rows, Settings chevrons |
| `shopBlockSub` | `#D9D0E6` | `#C8C1D3` | Subtitle on the shopping block |
| `welcomeBg` | `#37255C` | `#2A1F47` | Onboarding welcome |

Contrast: `text` on `bg` is 11.7:1 (light) and 17.3:1 (dark). `textMuted` is 5.2:1 and 10.1:1. `onOchre` on ochre is at least 6.5:1 (9.7:1 in dark).

### 3.2 Phase colours

| Phase | Season | Accent, light | Text, light | Tint, light | Accent, dark | Text, dark | Tint, dark |
|---|---|---|---|---|---|---|---|
| Menstrual | Inner winter | `#E58E73` | `#A0513D` | `#F3DCCD` | `#EE9A80` | `#F4B19C` | `#523843` |
| Follicular | Inner spring | `#4F8A72` | `#3D6E5B` | `#DCE4D5` | `#6FAA8F` | `#A3D3BC` | `#313C47` |
| Ovulatory | Inner summer | `#E4AC24` | `#86621A` | `#F2E2BE` | `#F1B821` | `#F6CC5E` | `#533F2B` |
| Luteal | Inner autumn | `#7A63B8` | `#6550A6` | `#E6DEEE` | `#9A86DA` | `#C3B6F1` | `#3C325B` |

Dark accents are slightly brighter so they hold up on the night plum. Every dark text shade is at least 9.5:1 on `bg`.

- **accent:** the active orbit segment on Home, the active arc on the onboarding ring, phase dots, the brand ring.
- **text:** small coloured labels such as the season name and the check icon. It passes 4.5:1 on the page in its theme.
- **tint:** the inactive orbit segments, the active phase-selector pill, the on-list mark, recipe photo placeholders, the "Merged" tag background.
- Never fill a whole screen with a phase colour. The current phase drives every accent on Foods, Recipes and Shop (shared viewing phase) and on Home (real phase).

### 3.3 Home hero colours

**Light mode:** the same off-white hero in every phase, with only a faint wash of the current phase colour so the screen stays predominantly white. **Dark mode:** one night-plum background for all four phases. Phase colour is information, not decoration.

| Phase | Light-mode hero (wash on `#FCFAF5`) | Season text, light | Dark-mode hero |
|---|---|---|---|
| Menstrual | `#FAF2EC` (7% coral) | `#A0513D` | night plum, coral glow |
| Follicular | `#F0F2EC` (7% sage) | `#3D6E5B` | night plum, sage glow |
| Ovulatory | `#FAF4E4` (8% ochre) | `#86621A` | night plum, ochre glow |
| Luteal | `#F3EFF1` (7% lavender) | `#6550A6` | night plum, lavender glow |

- **Light:** title, summary and day text are plum in every phase; the muted line is `#5F527A`. The orbit uses the light palette (`orbitLight`).
- **Dark:** `#37255C` → `#2E2150`, fading into `#1B152E`, for every phase. Text `#FFFDF8`, summary `#EDE7F2`, muted `#C8C1D3`, season in the phase's dark `text` colour. The phase shows only through the active orbit segment, the marker ring, the season label and a faint glow around the moon (`theme.ts › heroDark`).
- The background is solid down to 64 pt above the hero's bottom edge, then fades into the page (`bg`) over 64 pt.
- **Moon:** a radial gradient (centre 40% / 36%, radius 70%) between two tints of the theme ochre: light `#F7EACB` → `#F2D99D`, dark `#FAEDCB` → `#F7DE9C`.
- `screens/00-home-hero-phases.png` shows all four phases in both themes.

---

## 4. Typography

| Role | Font file (`assets/fonts`) | Size / line-height | Notes |
|---|---|---|---|
| Wordmark | Gwendolyn-Bold | 34.8 / 1.0, tracking +1% (x-height 12) | Home header only. Prefer the outlined SVGs in `assets/logo` |
| Moon day number | Fraunces_72pt-Light | 100 / 1.0, tracking −3.5% | Always plum `#37255C`, because it sits on the moon. Same size on the onboarding reveal |
| Big counts and steppers | Fraunces_72pt-Light | 72 / 0.9, −4% | Shop "8", cycle length "28" |
| H1 screen title | Fraunces_72pt-Regular | 44 / 1.0, −2% | Foods, Recipes, Shopping list, Settings; Home phase name 48; reveal 54 |
| Welcome headline | Fraunces_72pt-Regular | 44 / 1.04 | Italic accent word in ochre |
| H2 | Fraunces_24pt-Regular | 30–36 / 1.08–1.12 | Onboarding questions (36), Foods intro (32), Home focus (30) |
| H3 section head | Fraunces_24pt-Medium | 26 / 1.08 | "Foods for today", "Recipes for today" |
| Category head | Fraunces_24pt-Medium | 22 / 1.08 | With a count in DM Sans 13 muted |
| Card title | Fraunces_24pt-Medium | 18–21 / 1.2 | Feature recipe 26 Regular |
| Season | Fraunces_24pt-Italic | 18–20 | In phase `text` colour |
| Italic accent words | matching Fraunces italic cut | same as heading | One word or phrase per heading at most |
| Body large | DMSans_14pt-Regular | 17 / 1.5 | Summaries, welcome body |
| Body | DMSans_14pt-Regular | 16 / 1.55 | |
| Row label | DMSans_14pt-Medium | 17 / 1.25 (food rows 16) | SemiBold when on the list or pressed |
| Button | DMSans_14pt-SemiBold | 16 | |
| Small / micro | DMSans_14pt-Medium | 13 / 12 | Meta lines, sources, counts |
| Tab label | DMSans_14pt-Medium | 11 | SemiBold when active |
| Overline | DMSans_14pt-SemiBold | 12, tracking +14%, uppercase | `textMuted` |

Fraunces is cut at SOFT 50 and WONK 0. Use the 72pt files at 40 pt and above and the 24pt files below that.

---

## 5. Layout, spacing and shape

- **Gutters:** 24 (onboarding 26–28). Content starts at `safeTop + 10`; scroll content gets bottom padding of 130 to clear the tab bar.
- **Vertical rhythm:** 48 between Home sections, 34 between Foods categories, 18 inside headers.
- **Radii:** pills 999; recipe feature and shopping block 30; calendar card 28; recipe cards 26; grid recipe photos 24; info note 20; pressed food row 14.
- **No drop shadows** except the subtle 1-px hairline at the top of the tab bar. Depth comes from `raised` against `bg`.
- **Organic shapes** (`assets/shapes`): **the onboarding welcome screen only** (coral, sage and violet at 85–90% opacity plus a small ochre shape), plus one faint shape inside the recipe photo placeholder. No shapes anywhere else, in either theme. On the welcome screen, the violet shape sits at left −56, top 236 (130 × 120) so it never touches the letters.

---

## 6. Components

**Buttons (56 high, pill, label DM Sans 16 SemiBold, optional 20-pt trailing icon)**

| Variant | Fill | Label | When |
|---|---|---|---|
| Primary | `ochre` | `onOchre` | The single main action ("Get started", "See my foods") |
| Secondary | `inverseBg` | `inverseText` | Step actions ("Continue") |
| Ghost | transparent with a 1.5-pt `text` outline | `text` | Rare |
| Text link | none | `text`, underline 2 pt `ochre`, offset 4 | "All foods", "Clear all", "I'm not sure", "Skip for now" |

**Phase selector:** 4 equal columns, gap 4. Each segment is 40 high and a pill, with a 7-pt accent dot and the label in DM Sans 13. Active: phase `tint` fill, `text` colour, SemiBold. Inactive: transparent, `textMuted`, Medium. Below it: a dot plus "Your current phase · day 7" (13, muted).

**Chips** (Home "Foods for today", onboarding choices): 42 high, pill, padding 18, DM Sans 15.
- Default: `sand` fill.
- On your list: phase `tint` fill with a 15-pt check in phase `text`.
- Pressed or selected: `inverseBg` fill with `inverseText`.

**Food rows** (Foods screen):
- Layout: a two-column grid with 14 between columns. Each row is at least 52 high with padding 6 × 10 and a 1-pt `line` bottom divider.
- Left side: the name in DM Sans 16 Medium (SemiBold when on the list). A parenthetical becomes a second line in 12 muted, e.g. "Lettuce" over "Bibb, Boston, romaine".
- Right side:
  - **Recipe count** when > 0: a 14-pt bowl icon plus the number, DM Sans 12 SemiBold muted.
  - Otherwise a 14-pt `chevron`.
  - Then the **on-list mark** if the food is on the list: a 22-pt circle in phase `tint` with a check in phase `text`.
- Pressed or opened: `sand` fill, radius 14, no divider.
- Accessibility label: "Lemon, 2 recipes, on your list".

**Round checkbox:** 26 pt with a 44-pt hit area. Unchecked: 1.8-pt `checkboxBorder` ring. Checked: `inverseBg` fill with a check in `inverseText`.

**List rows** (Shop, Settings): at least 60–64 high, 1-pt `line` dividers between rows (none above the first), no card around the list. Settings rows: a 22-pt line icon in `text`, the label 17 Medium, an optional subtitle 14 muted, and an 18-pt chevron in `removeIcon`.

**Section head:** Fraunces 26 Medium title, with an optional text link on the right.

**Overline group labels:** DM Sans 12 SemiBold, uppercase, +14% tracking, muted.

**Tab bar:** solid `raised` background, 88 high including the home-indicator area, a 1-pt `line` at the top, and 5 equal tabs. Each tab is a 23-pt icon above an 11-pt label, with a 5-pt `ochre` dot below the active tab. Active tab: `text` colour with a 1.9 icon stroke. Inactive: `textMuted` with a 1.6 stroke.

**Moon hero** (Home and onboarding reveal, 300 × 300 pt; see `assets/ui/moon-hero-*.svg` and `theme.ts › orbit`):
- `viewBox 0 0 300 300`, centre 150.
- **Moon:** a circle of radius 108 with the ochre moon gradient (section 3.3).
- **Orbit:** radius 136, stroke 12, **flat (butt) ends**, starting at 12 o'clock and running clockwise. Each phase is one segment from `(start − 1) / cycleLength` to `end / cycleLength` of the circle, using the user's phase ranges from `cycle.ts`. Trim 0.0035 of the circle from each end of every segment so the segments almost touch, like the logo.
- **Segment colours:** the current phase uses the phase `acc`; the other three use their `tint`. Light mode uses `orbitLight`; dark mode uses `orbitNight`.
- **Today dot:** at `(day − 0.5) / cycleLength`. A halo of radius 11.4 (0.95 × stroke) filled with the hero background colour, then a dot of radius 8.64 (0.72 × stroke). Light: plum. Dark: `#FFFDF8` with a 2.6 pt ring in the phase accent.
- **Dark-mode glow:** a radial gradient circle of radius 150 in the phase accent, opacity 0.30 at 68% fading to 0 at the edge, behind the moon.
- **Centre:** "DAY" overline (11 pt, `#5F527A`) above the day number in Fraunces Light 100, `#37255C`. Both stay plum in every theme because they sit on the pale moon.
- **Late period:** the dot stays at the end of the luteal segment (day = cycle length) while the centre shows the real cycle day, e.g. 32.
- No ticks, stars or extra decoration.

**Bottom sheet:** `bg` fill, top radius 32, a 40 × 5 handle in `line`, padding 12 / 24 / 40, over a scrim (light `rgba(27, 21, 46, 0.42)`, dark `rgba(8, 5, 18, 0.62)`). Sheets cover the tab bar. Tall sheets (Cook with…) start 96 pt from the top and scroll inside.

**Sub-screen header** (Settings sub-screens): a 44-pt back link "‹ Settings" (DM Sans 15 Medium), then the H1 in Fraunces 40 (36 for long titles).

**Value row** (Settings sub-screens): the list row with a value on the right in DM Sans 16 muted before the chevron, e.g. "Cycle length · 28 days", and an optional subtitle in 14 muted.

**Toggle:** 51 × 31 pill. On: `inverseBg` track with a `bg` knob. Off: `line` track with a white knob (`#C8C1D3` in dark). Always paired with a row label; `role="switch"`.

**Info note:** `raised` fill, a 1-pt `line` outline, radius 20, padding 14 × 18, an 18-pt muted line icon and 14 muted text. Used for privacy and allergy notes.

**Destructive button:** 56 high, pill, Menstrual `text` fill (`#A0513D` light, `#F4B19C` dark) with `bg`-contrast label. Only on the Delete my data confirmation.

**Empty state:** centred; a 72-pt circle in phase `tint` with a 32-pt line icon in phase `text`, a Fraunces 26 title with one italic word, 15 muted body (max 290 wide), then one or two text links. Each one names the way out (for example "Show all meal types", "Clear ingredient").

**Recipe cards:**
- Home: a horizontal scroller of cards 268 wide, each with a 300-high photo (radius 26), a Fraunces 21 title and a meta line ("Meals · 25 min", 13 muted).
- Recipes: a feature card (250-high photo, radius 30, a cream time badge, Fraunces 26 title, key ingredients in the meta line) above a two-across grid (170-high photos, radius 24, Fraunces 18 titles).
- No photo: a phase `tint` placeholder with a 40-pt bowl icon and a faint phase-accent organic shape (22% opacity) at the bottom right.

**Inputs:** 52 high, pill, `raised` fill with a 1-pt `line` outline, DM Sans 16. The add button beside it is a 52-pt `ochre` circle with a `+` in `onOchre`.

---

## 7. Screens

### 7.1 Onboarding (new design; five steps)

Progress header on steps 2–4: a 44-pt back button, three 4-pt bars (`ochre` when done, `line` otherwise), and "n of 3" (13 muted). Each step asks one question, with the H2 in Fraunces 36 and its last words in italic.

1. **Welcome** (`welcomeBg`): coral, sage and violet organic shapes plus a small ochre shape; the brand ring at 150 pt, centred near the top. Bottom block:
   - The script wordmark in `welcomeText` (x-height 15; `assets/logo/wordmark-cream.svg`).
   - Headline "Eat in rhythm with your *cycle.*" (*cycle* in ochre italic).
   - Body: "Foods, recipes and a shopping list that follow your four phases, so you always know what to eat right now."
   - Primary button "Get started →".
   - Text link "I already have an account".
2. **Last period:** overline "Your cycle", heading "When did your last period *start?*", and the helper "This sets your cycle day. You can change it anytime in Settings." Below that:
   - **Month calendar:** a `raised` card with radius 28. The header has round `sand` 40-pt previous/next buttons and the month in Fraunces 20. Weekday initials are in 12 muted, and day cells are 42-pt pills.
   - **Date states:** the selected start date uses `inverseBg`, and the predicted period days after it use the Menstrual `tint`. Future dates are disabled.
   - **Confirmation line:** "● Day 1 · Sunday 28 September" in muted text.
   - **Actions:** "Continue" (secondary) and the text link "I'm not sure", which uses today minus 7 and flags the date for confirmation later.
3. **Cycle length:** overline "Your rhythm", heading "How long is your cycle, *usually?*". Two steppers separated by hairlines:
   - **Cycle length:** range 21–45, default 28, hint "From the first day of one period to the next."
   - **Period length:** range 2–10, default 5, hint "How many days you usually bleed."
   - Each stepper shows the value in Fraunces Light 72 with "days" in 16 muted, between round 52-pt `sand` − and + buttons. Each button's accessibility label is "Increase/Decrease cycle length".
   - An info note follows: "Not sure? 28 and 5 are good starting points. We'll adjust as you log your periods." Then "Continue".
4. **Food preferences:** overline "Your table", heading "Anything you'd rather *not eat?*", helper "We'll leave these out of your foods and recipes."
   - **How you eat:** single choice from Omnivore, Pescatarian, Vegetarian, Vegan. The selected pill uses `inverseBg`.
   - **Allergies & foods to avoid:** multi-select chips. Selected chips use the Menstrual tint and a check, plus there's an "+ Add another" outline chip.
   - Actions: "Continue" and "Skip for now". Saves to Settings › Food Preferences and Allergies.
5. **Your phase (reveal):** the same background as the Home hero (light wash or dark night plum, solid to 520 pt, fading to the page by 660 pt). No organic shapes. Content, top to bottom:
   - Overline "You're in your" in phase text, then the phase name in Fraunces 54 and the season in italic phase text.
   - The moon hero at 300 pt (section 6).
   - "Estrogen is rising and energy returns. Your foods and recipes now follow this phase." Use the first sentence of the phase's Emergent focus copy, then the fixed second sentence.
   - "Ovulatory in 5 days · Next period 26 October" (14 muted).
   - Primary button "See my foods →", which opens the Foods tab.
   - All four phases: `screens/*-37-onboarding-reveal-all-phases.png`.

### 7.2 Home (your real phase only; no phase selector)

1. **Hero (full-bleed):** one edge-to-edge block with **no rounded corners**, starting under the status bar. Its background follows section 3.3 and fades into the page over its last 64 pt; bottom padding 56. No organic shapes. Contents:
   - **Header:** the **wordmark alone** on the left (no ring logo): `assets/logo/wordmark-header-plum.svg` on light heroes, `wordmark-header-cream.svg` in dark mode, x-height 12. The short date "Sat 4 Oct" (13, hero muted colour) on the right.
   - **Moon hero** (300 pt, 22 below the header) as specified in section 6.
   - Below it, centred, 10 below the moon:
     - The season in Fraunces italic 18, hero season colour.
     - The phase name in Fraunces 48, hero text colour.
     - The first sentence of the Emergent focus copy (17), max width 290.
     - Two lines in 13 hero muted: "Day 2 of 6 in phase · Day 7 of 28 in cycle", then "Ovulatory in 5 days" (or "Period in 8 days" in luteal).
   - **Orbit drag preview** (`23-home-preview-day`): dragging around the orbit previews another day. The moon, phase name, season and summary show the previewed day; the meta line reads "Previewing day 14 · in 7 days"; a `sand` pill "‹ Back to today · Day 7" appears below. The hero background and everything below the hero stay on today's real phase.
2. The content below starts 44 pt under the hero.
3. **Your focus:** an overline, then the phase tagline as an H2 with its last word in italic, the rest of the Emergent focus copy as body text, and the cooking line with the pan icon (14 muted). No card.
4. **Foods for today:** a section head with an "All foods" link, then up to 6 chips (one per category). Tapping a chip opens the ingredient sheet.
5. **Recipes for today:** a section head with an "All recipes" link, then a horizontal scroller of recipe cards.
6. **Shopping block:** `shopBlockBg`, radius 30. It shows "Your shopping list" (Fraunces 22) above "8 to buy · 6 from recipes" (`shopBlockSub`), with a 48-pt ochre circle arrow on the right. It opens the Shop tab.
7. Tab bar.

**Home states**
- **Period late** (`21-home-period-late`): from 3 days late. The hero stays in luteal; the moon shows the real cycle day (32) with the dot pinned at the end of the orbit; the meta line reads "Period 4 days late · Day 32 in cycle". Directly under the hero, one `raised` card (radius 28): overline "Your period", "Has your period *started?*" (Fraunces 26), "Log it and your cycle restarts at day 1. Until then, we'll keep you in your luteal phase." and the primary button "Log my period", which opens the Log a period sheet.
- **Log a period sheet** (`22-log-period-sheet`): overline "Log a period", "When did it *start?*", the onboarding month calendar (future dates disabled), the "● Day 1 · Saturday 4 October" line and "Save" (secondary). The same sheet opens from Settings › My Cycle › "Log a period".
- **No recipes fit** (`24-home-no-recipes`): if food preferences or avoidances exclude every recipe of the real phase, "Recipes for today" shows "No recipes for this phase fit your food preferences." and the text link "Review food preferences".

### 7.3 Foods

1. **Header:** H1 "Foods", the phase selector, and the current-phase line.
2. **Intro (no box, no shape):** the season in italic phase text, the tagline as an H2 (32, italic last word) and the body copy (max width 320).
3. **Hint line:** after a hairline, "Tap a food to cook with it", then "[bowl] 2 recipes" and "[✓] on your list". Each piece stays on one line and the line wraps between pieces.
4. **Categories:** in stored Emergent order. Each has a Fraunces 22 heading with its count, then food rows in two columns.
5. **Tapping a row** opens the ingredient sheet (section 9).
6. **Browsing another phase** (`34-foods-browsing-other-phase`): the line under the selector becomes "● Browsing luteal · Back to follicular" (the link resets to the real phase), and every accent follows the viewed phase.
7. Foods the user avoids are hidden. If a whole category is hidden, its heading is hidden too.

### 7.4 Recipes

1. **Header:**
   - H1 "Recipes" and the phase selector.
   - **Meal tabs** (All · Breakfast · Meals · Snacks) as text tabs: DM Sans 16, the active tab in `text` SemiBold with a 2.5-pt ochre underline, inactive in muted, and a hairline under the row.
   - **"Cook with…" field:** a `raised` pill with a 1-pt `line` outline. It contains a 34-pt tint circle with a search icon, "**Cook with…** choose an ingredient" and a chevron.
2. **Count line:** "3 follicular recipes" (13 muted).
3. **Recipe list:**
   - The first recipe is the feature card; the rest form a two-across grid.
   - Stored `lunch` and `dinner` both show as "Meals".
   - **With an ingredient filter active** (`15-recipes-cook-with-filter`), the Cook with field becomes the removable chip "Cook with: Chicken ×" (phase `tint`, 44 high) with a "Change" link, and the count reads "1 follicular recipe with chicken".
4. **Empty states:**
   - No recipes for the meal type (`16-recipes-empty-meal-type`): "No follicular snacks *yet*", "None of this phase's recipes is a snack. Try another meal type." and "Show all meal types".
   - No recipes for the ingredient and meal type (`17-recipes-empty-ingredient`): "No breakfasts with *chicken*" with "Show all meal types" and "Clear ingredient".
   - Nothing fits the user's food preferences (`18-recipes-empty-preferences`): "Nothing fits your *preferences*" with "Review food preferences".

### 7.5 Shop

1. **Header:** H1 "Shopping list" and the phase selector.
2. **Summary:** "8" in Fraunces Light 72 with "to buy" in Fraunces italic 20, and "3 done" on the right (14 muted). Below it, a 4-pt progress line (`line` track, `text` fill).
3. **Add field:** the input with the ochre "+" button.
4. **To buy:** grouped by aisle under overlines. Each row:
   - Round checkbox and the name (17 Medium).
   - Source line (12 muted) with a 6-pt dot: phase accent for staples, ochre for recipes and merged items.
   - A "Merged" tag (Ovulatory text on Ovulatory tint, 11 Bold) where items were combined.
   - A × button with the label "Remove {name}".
5. **Done:** after a hairline, "Done" (Fraunces 24) with a `sand` count pill and a chevron (collapsed by default), and the text link "Clear all". Hidden when nothing is done.
6. **Undo toast** (`36-shop-undo`): after Clear all, a toast 16 from the sides and 104 from the bottom, 60 high, radius 20, `inverseBg`: "3 done items cleared" and an ochre "Undo" pill. It stays for 8 seconds.
7. **Empty list** (`35-shop-empty`): "0 to buy", an empty progress track, the add field, then the empty state "Your list is *empty*", "Add foods from Foods or a recipe's ingredients, or type an item above." and "Browse foods".

### 7.6 Settings

**v1 (local-only), `25-settings-v1-local`:**
1. **Title:** H1 "Settings".
2. **Groups** under overlines, rows per the list-row spec, no coloured icon tiles:
   - Personalisation: My Cycle, Food Preferences, Allergies / Foods to Avoid.
   - App: Notifications.
   - Account: Subscription ("Free at launch"), Privacy & Data. There is **no Account row in v1**.
   - Support: Help.
3. **Delete my data:** a text button in Menstrual text colour (16 SemiBold), with "Permanently removes your cycle history, preferences and list from this phone." centred below (13 muted). It opens the confirmation.
4. **Footer:** a small lockup and "Version [x.y]".

The approved `10-settings` screen (with the Account row and "Delete Account") is the **v1.1** target, once accounts exist.

**Sub-screens** (all use the sub-screen header, value rows and the tab bar):
- **My Cycle** (`26-settings-my-cycle`): overline "Next period", the date in Fraunces 34 and "In 22 days · Ovulatory in 5 days". Group "Your cycle": Last period started; Cycle length (subtitle "Average of your last 3 cycles" once history exists); Period length (same). Group "History": one row per logged period ("28 Sep – 2 Oct", "5 days · 28-day cycle"). Then "Log a period" (secondary) and the note "Phases are estimates based on your dates. Moon Cycle isn't a contraceptive or a fertility tool."
- **Food Preferences** (`27-settings-food-preferences`): the onboarding diet pills (saved on tap), then a hairline list explaining each choice: Omnivore · Everything; Pescatarian · No meat; Vegetarian · No meat or fish; Vegan · No animal foods.
- **Allergies & foods to avoid** (`28-settings-allergies`): "We hide foods and recipes that contain these."; "Common allergens" as the onboarding chips; "Specific foods" with a search field over the food catalogue and the chosen foods as removable chips; the info note "Always check labels. We filter with our ingredient data, but we can't guarantee a food or recipe is free from an allergen."
- **Notifications** (`29-settings-notifications`): toggles for Reminders (master), "When a new phase starts" (on the morning of each new phase) and "Before your period" (two days before it's due), then "Reminders are worked out on this phone. Your dates aren't sent anywhere to deliver them."
- **Subscription** (`30-settings-subscription`): overline "Your plan", "Moon Cycle *Plus*", the `sand` pill "Free at launch · until [launch-free end date]" and "Everything in Moon Cycle is free until [launch-free end date]. You don't need to do anything, and nothing will be charged." No purchase controls in v1.
- **Privacy & Data** (`31-settings-privacy-data`): the info note "Your data lives on this phone…", group "Your data" with "Export my data", group "Policies" with Privacy policy, Terms of use and How Moon Cycle uses data.
- **Help** (`32-settings-help`): FAQ rows that expand in place (chevron rotates); "Contact support" (secondary); the disclaimer "Moon Cycle offers general food guidance, not medical advice. Talk to a doctor about symptoms or changes in your cycle." FAQ answers need content review before release.
- **Delete my data** (`33-settings-delete-my-data`): overline, "Delete your data *for good?*", the explanation, the link "Export my data first", then the destructive button "Delete my data" and "Cancel". No tab bar.

---

## 8. Behaviour (unchanged; keep the existing logic)

- **Tabs:** Home · Foods · Recipes · Shop · Settings. Each tab keeps its own stack; tapping the active tab returns it to its top level.
- **Home** uses the user's actual phase from their cycle data and has no selector. **Foods, Recipes and Shop** share one viewing phase, which resets to the actual phase each time the app opens.
- **Phase ranges come from each user's data**, not fixed days. Reference implementation: `code/cycle.ts`. The 28-day / 5-day example gives Menstrual 1–5, Follicular 6–11, Ovulatory 12–15, Luteal 16–28.
- **Ingredient sheet** (from Foods, or from a Home food chip): label **"Recommended for your {phase} phase"**, copy from `content/ingredients.json` › `phaseWhy[phase].short`. Actions:
  - **"See N recipes with X"** switches to Recipes with the phase kept and the ingredient filter applied. Hide this button when N is 0.
  - **"Add to shopping list"** adds the food to To buy, merging with any existing item.
- **Recipes filters:** phase, plus meal type, plus one optional ingredient. Recipe detail has "Add ingredients to shopping list", which merges duplicates.
- **Shop:** two states only, To buy and Done. Checking an item moves it to Done; unchecking moves it back. Duplicates merge. Clear all has an 8-second Undo. There is one list, not one per phase.
- **Content:** foods, categories and phase copy come from the Emergent export (`content-model/source-emergent-export.md`), unchanged. Don't show ingredients flagged `shipReady: false` in `content/ingredients.json` (Hijiki, Salt, Alcohol, Ketchup) until the content flags are approved.

## 9. Sheets and recipe detail

- **Ingredient sheet** (`11-ingredient-sheet`): over the screen it was opened from. The category overline, the food name in Fraunces 42, the label pill (phase `tint`, "Recommended for your follicular phase"), the short copy (body 16), then the primary "See N recipes with chicken →" and the secondary "Add to shopping list".
  - **On your list, no recipes** (`12-ingredient-sheet-on-list`): the recipe button is hidden, "No recipes with rye yet." (14 muted) is shown, and the secondary button becomes a disabled `sand` "✓ On your list".
- **Cook with… sheet** (`13-cook-with-sheet`): "Cook with…" (Fraunces 30), "Foods for your follicular phase", the search field, then **every food recommended for the viewing phase**, grouped under category overlines, each row with its recipe count or a chevron. Tapping a row applies the filter and closes the sheet.
  - **No matches** (`14-cook-with-no-results`): the field shows the query with an ochre focus ring and a clear button; below, "No follicular foods match "quinoa"", "Try another name, or browse the list." and "Clear search".
- **Recipe detail** (`19-recipe-detail`): a full-bleed 330-pt photo (or the tint placeholder) with a round `raised` back button at top 54, left 20. The content panel overlaps the photo by 30, with top radius 30:
  - Phase pill (tint with accent dot) and meal pill (`sand`); the title in Fraunces 30; "⏱ 25 min · Serves 2" (14 muted); the intro (16).
  - **Ingredients** (Fraunces 24, "7 items" on the right): hairline rows with the name (16 Medium), the quantity on the right (14 muted), and, when on the list, "On your list" (12, phase text) under the name plus the on-list mark.
  - The primary "Add ingredients to shopping list" with the merge note "Broccoli, lemon and sauerkraut are already on your list. We'll merge them, not add them twice."
  - **Method** (Fraunces 24): numbered steps, each number in a 32-pt phase-tint circle.
  - **Added** (`20-recipe-detail-added`): every row shows "On your list"; the button becomes the disabled `sand` "✓ Added to shopping list" with "All 7 ingredients are on your list." and the link "Open shopping list".
  - The mock-up shows real recovered data (Zesty Lentil & Broccoli Bowl: 25 min, serves 2, 8 ingredient lines, 4 steps). Quantities show amount + unit, or "to serve"; a unit of "piece" shows the number alone. The recipe data and its open flags are in `content/recovered/emergent-recipes.json` and `content/RECIPE-DATA-NEEDED.md`.

## 10. Implementation notes (Flutter)

The full plan is `flutter-plan/Moon-Cycle-Flutter-Technical-Plan.md` (Flutter, Riverpod 3, go_router, Drift with SQLCipher, Sentry). Notes specific to this spec:
- **Fonts:** bundle the static TTFs from `assets/fonts` (no runtime download). Families: `Fraunces72` for 40 pt and up, `Fraunces24` below, `DMSans`, and `Gwendolyn` only as a fallback for the wordmark. Set `TextLeadingDistribution.even` so line heights match the CSS-rendered mock-ups. Italic accent words are `TextSpan`s in the matching italic.
- **SVGs:** `flutter_svg` (precompiled with `vector_graphics_compiler`). Icons and shapes use `currentColor`; set it through `SvgTheme`. The wordmark and lockups are outlined paths, so no font is needed.
- **Moon hero:** a `CustomPainter` in the 300-unit space (plan §5.5); the centre text is real `Text` widgets. Hero backgrounds: a solid fill plus a 64-pt gradient strip.
- **Text links:** Flutter can't offset or thicken an underline, so draw the 2-pt ochre underline with a custom widget, 4 pt below the baseline.
- **App icon and splash:** `assets/app-icon/png` (iOS light/dark 1024, Android adaptive foreground and monochrome on `#FCFAF5`). Splash background `#FCFAF5`, dark `#1B152E`.
- **Status bar:** dark content in light mode, light content in dark mode.
- **Accessibility:** 44-pt targets; every icon-only button labelled; food rows announce recipe count and on-list state; checkboxes and toggles expose their state; text scales up to 1.3× for headings and 1.5× for body.
- **Organic shapes:** decorative only; exclude them from semantics.

## 11. Open questions

1. **Recipe data:** recovered from the Emergent repository for all 12 recipes (times, servings, intros, 79 ingredient lines with quantities, 47 steps, Unsplash photos). It was generated as sample content, so it needs an editorial review and a test-cook; 23 flags need a decision (health claims in 2 intros, 4 allergen risks, unlisted salt/oil, can sizes). Aisles, diet and allergen data per food are still missing. See `content/RECIPE-DATA-NEEDED.md`.
2. **Snacks:** none of the 12 recipes is a snack, so the Snacks tab always shows its empty state until snack recipes exist.
3. **Content flags:** 26 data-quality and editorial flags are still open; see `content/ingredients.json` › `dataQualityFlags`.
4. **Launch-free end date:** shown as `[launch-free end date]` in Settings › Subscription; it is one fixed date for everyone.
5. **Help answers** and the policy pages need content review before release.

## 12. v1.0 scope (decided 11 October 2026)

- **Local-only:** no account, no sign-in, no server. Every screen in this spec works offline. Supabase Auth and sync arrive in v1.1.
- **Not in v1:** sign-in screens, the Account row in Settings, server account deletion, purchases or RevenueCat, push notifications from a server, analytics.
- **Onboarding welcome:** the link "I already have an account" is **hidden in v1** (there are no accounts yet). Everything else on the welcome screen is unchanged.
- **Settings:** use the v1 variant (`25-settings-v1-local`); "Delete my data" deletes everything stored on the phone.
- **Subscription:** feature gates exist in code, but every feature is free until the fixed launch-free end date.
- **Crash reporting:** Sentry, with no personal or cycle data in reports.
- **App identity:** bundle ID and Android application ID `app.mooncycle.mobile` (domain `mooncycle.app`, owned). Test builds use `app.mooncycle.mobile.dev` and `app.mooncycle.mobile.stg`. Display name "Moon Cycle".
