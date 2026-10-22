## Summary
Visual-only V2 redesign of the **Home** screen (Stage 1), approved on a physical iPhone.

- Hero: Home-specific segmented ring (`HomeRing`; shared `MoonOrbit` untouched), real day number (no "DAY"), pearl marker at today's position, season label, phase name and real timing text. Wordmark asset and real date in the header.
- **Today's Focus** card (phase headline + description from existing phase content, link to the existing Learn more page, decorative sprig).
- **3 a Day** cards: EAT (→ 3 Plants a Day), MOVE and RELAX (→ their existing tabs). No completion state, streaks or scores.
- **Quick Access**: My Diary and Shopping List with existing destinations and entitlement behaviour.
- Light/dark, 320 pt (Quick Access stacks), large text.
- Re-recorded the 16 Home goldens (macOS 15, matching CI) and reviewed them: only Home goldens changed.
- Added `docs/v2-ui-roadmap.md` tracking all V2 screens, designs, status and remaining work.

Not touched: cycle calculation/history/persistence, food selection, 3 Plants a Day logic, recipes/Meal Builder, diary/symptoms, shopping, entitlements, DB, backend, other screens, navigation.

## Behaviour notes
- Home no longer has the "Create my meal" / Explore foods / Explore recipes entries (not in the new design). Meal Builder is still reachable from Eat; its free-user lock is still tested.
- The `premium` and `avoidances` Home goldens now look like `follicular`, since the sections they exercised left Home.

## Testing
- Local: `flutter analyze` clean; `test/features/home` and `test/app` pass (51 tests); Home goldens regenerated and passing.
- CI (full suite, golden job, Android build): see checks below.

## Remaining visual placeholders
- MOVE and RELAX cards: "photo to come" tiles (no assets in repo).
- EAT card: curated photo only when one of today's plants has one (broccoli/avocado/blueberry), else emoji tile.
- Botanical sprig in Today's Focus is a vector placeholder.
- Minor: at 320 pt a wrapped Focus link underlines the first line only.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
