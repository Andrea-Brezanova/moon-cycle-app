# Accessibility: automated coverage and the manual checks still needed (1 Nov 2026)

## Automated (run in CI on every PR)

`flutter test test/a11y` (89 tests, all passing on 1 Nov 2026) checks, on 40+ screens in light mode: iOS tap-target size (44 pt), every tappable control has a semantic label, text contrast against its background, and no overflow at 320 pt width with 1.5× text. Widget tests also assert 2× and 3× text on Home. These use Flutter's `meetsGuideline` matchers; they cannot judge reading order, meaning of labels, focus handling or how it *sounds*.

Not covered by any tool in the repo: dark-mode contrast per screen, Switch Control, Voice Control, Reduce Motion behaviour (the app has no looping animation), Bold Text, Increase Contrast, and Dynamic Type at the largest accessibility sizes (AX1 to AX5) beyond 3×.

## Manual VoiceOver pass (needs a person and the iPhone; about 45 minutes)

Settings › Accessibility › VoiceOver on (triple-click side button shortcut recommended). For each flow, swipe through with one finger, then with the rotor set to Headings. Pass = every item is announced with a meaningful name, role and state, in a sensible order, and every action is reachable without sight.

| # | Flow | Look for |
|---|---|---|
| 1 | Onboarding (cycle questions) | Date pickers announce the selected value; the primary button is reachable; errors are read out |
| 2 | Home | Hero/orbit description is meaningful (not "image"); Today's picks read as three separate buttons with their link text; the phase is announced |
| 3 | Eat › Foods › a Food Detail with a profile | Headings navigable by rotor; the nutrient table reads as label + amount + percentage, not a jumble; cautions read before the long text; "Explore this food" pill is not announced as an instruction |
| 4 | Build a Meal | Chosen foods are announced as chosen/unchosen; the 8-food limit message is spoken; results list reads title + match level |
| 5 | Recipe detail | Ingredients and steps are in order; "Add to shopping" announces the result |
| 6 | Log diary / symptom check-in | Sliders and chips expose value and selected state; saving is confirmed audibly |
| 7 | Shopping list | Check-off state spoken; swipe actions available via the actions rotor |
| 8 | Me › Privacy & Data | Toggles announce on/off; Export and Delete my data confirmations are readable and cancellable |
| 9 | Reminders permission prompt and a delivered reminder | Notification text is understandable (discreet by default) |

## Dynamic Type and display settings (10 minutes)

Settings › Accessibility › Display & Text Size: Larger Text at the largest accessibility size, Bold Text, Increase Contrast, Reduce Transparency, Smart Invert. Check Home, Food Detail, Build a Meal, the diary and Settings for clipped text, overlapping controls, unreachable buttons and lost contrast. Then Dark appearance on the same screens.

## Record the result

For each failure: screen, setting, what was announced or seen, screenshot or recording. Do not mark the app "accessible" in store copy until this pass is done and fixes are verified. No reviewer or date is recorded here; add the tester's own name only if they choose.
