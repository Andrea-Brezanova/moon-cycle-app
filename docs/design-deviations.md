# Design deviations

Every place where the Flutter implementation differs from the Editorial v3 handoff (`design/`), or had to decide something the handoff doesn't specify. Anything marked **open** is waiting for a decision.

| # | Where | What the handoff says | What the app does | Why | Status |
|---|---|---|---|---|---|
| 1 | Buttons, round icon buttons, stepper ± at its limits | Disabled state not designed | 40% opacity, not tappable | Onboarding needs "Continue" disabled until a step is valid | approved 11 Oct 2026 (v1 default) |
| 2 | Everything tappable | No ripples; pressed states only for chips and food rows | Content dims to 70% while pressed; no Material ripples. Designed pressed states (chip, food row) are used where they exist | Touch feedback without visual clutter | approved 11 Oct 2026 |
| 3 | Onboarding links ("I'm not sure", "Skip for now", "I already have an account") | Spec §6: every text link has the 2 pt ochre underline. The approved onboarding screens show a thin underline in the text colour | **Intentional onboarding exception:** `TextLink.onboarding` is DM Sans 15 Medium with a 1 pt underline in the text colour (plum, or cream on the welcome screen). Everywhere else `TextLink` keeps the 2 pt ochre underline | The approved screens win over the generic rule | approved 11 Oct 2026 |
| 4 | Text-link underline position | CSS `text-underline-offset: 4px` | Drawn 4 pt below the alphabetic baseline | Flutter's underline can't be offset; visually equivalent | approved 11 Oct 2026 |
| 5 | DM Sans | Mock-ups use variable DM Sans with automatic optical size (9–40) | Static 14 pt optical-size cut at every size | Differences are only visible at 11–13 pt; not worth the complexity | approved 11 Oct 2026 |
| 6 | Fraunces | Mock-ups use continuous optical sizing | Two static cuts: 72 pt for 40 pt and up, 24 pt below | As specified in spec §4 | approved 11 Oct 2026 |
| 7 | Stepper value on narrow screens or at large text sizes | Not designed (390 pt, standard text size) | The value shrinks to fit only when it doesn't fit; unchanged at 390 pt | Prevents overflow at 320 pt and 1.5× text | approved 11 Oct 2026 |
| 8 | Button labels on narrow screens or at large text sizes | Not designed | The label wraps and the button grows taller (corner radius stays 28, so a one-line button is the designed 56 pt pill). At large text sizes the side padding tightens from 24 to 16 pt. Labels are **never truncated** | Important actions must stay understandable | approved 11 Oct 2026 |
| 9 | Chip labels on narrow screens or at large text sizes | Not designed | Chips are compact controls and may end with "…" when a label can't fit | A chip can't grow without breaking its row | approved 11 Oct 2026 |

How to check a screen against the design: open the Component gallery (debug builds, from the placeholder screen) and compare with `design/screens/`. Golden images of every component are in `test/goldens/goldens/`.
