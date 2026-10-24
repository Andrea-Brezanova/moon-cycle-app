# V2 refinements (visual only)

Home, Eat, Foods, Recipes and 3 Plants a Day, to the refinement boards. No
business logic, data model, content, storage or dependency change; no new colours
(existing tokens and fonts); both modes; photos dimmed ~0.94 in dark; 44 pt
targets; checked at 390/320 pt with normal and large text.

## Changes by file
- `home_ring.dart`, `home_hero.dart`: ring with "DAY" label and phase-coloured segments; phase background.
- `home_v2.dart`, `home_page.dart`: section overlines (DM Sans 13/700, 0.22em), Today's focus card with sprig, Today's picks blocks, Quick access cards with the supplied diary and shopping photos (live counts kept).
- `home_photos.dart`, `assets/images/home/*`, `pubspec.yaml`: the five photos (credits in `docs/photo-credits.md`, Credits page).
- `core/design/widgets/dimmed_photo.dart`: shared dark-mode dimming.
- `eat_page.dart`: Eat overline.
- `eat_filters.dart` (new), `foods_page.dart`, `recipes_page.dart`, `recipe_widgets.dart`, `recipe_list.dart`: phase + type controls; type sheet with live counts; "N foods" / "N recipes" counts.
- `three_plants_page.dart`: selectable plant cards and an always-available "Find a meal with 1 plant / 2 plants / all 3" bar.
- Tests updated for the new layouts; new: type sheet filters list and count (Foods, Recipes), plant cards toggle and button label, Quick access cards open the right pages.

## Open questions
1. Quick access counts stay live (My Diary entries today, items to buy).
2. Leaf sprig is drawn from the board's SVG paths; supply a final illustration if wanted.
3. Plants without a photo show a leaf tile; more plant photos needed.
