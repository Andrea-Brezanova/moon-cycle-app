# Move and Relax content: review package (nothing here is published)

`hub-content-drafts.json` holds 13 draft items, all `reviewStatus: draft`. The app shows
only items that an editor has changed to `approved` (with `reviewedBy`, `reviewedOn`) and
moved into `assets/content/hub_content.json`; the loader rejects an approved item that is
missing a reviewer, a date, steps or a verified link, a safety note (exercises, workouts)
or rights (sounds).

## What is in it
| Group | Items |
|---|---|
| Exercises (3) | Easy walk, Morning wake-up stretch, Desk break: neck and shoulders |
| Workouts (2) | Evening unwind stretches, Bodyweight basics (chair sits, wall push-ups) |
| Meditations (3) | Three calm breaths, Paced breathing, Short body scan |
| Spa (5) | Warm foot soak, Gentle facial massage, Mindful tea break, Relaxing evening routine, Simple grounding |

Every item is written as original text (no copied scripts, no creator's voice). Each has a
duration, an effort word (gentle / easy), equipment, plain steps and, for movement, the
same safety note. Nothing is tied to a cycle phase and nothing claims a treatment,
detox, lymphatic or hormone effect.

## What a reviewer should check
1. **Movement items (professional review needed):** are the steps safe and clear for a
   beginner, are "gentle / easy" labels fair, is the safety note enough, do any steps need
   a caution (balance, joints, pregnancy, recent injury)? Chair sits and wall push-ups in
   particular.
2. **Spa items:** foot soak water temperature wording ("comfortably warm; test with your
   hand"), skin-irritation note on the facial massage; confirm no health claim sneaks in.
3. **Meditations:** counts and wording for breathing (in 4, out 6); confirm nothing reads
   as treatment for anxiety, sleep or any condition.
4. Reading level, tone, spelling, and whether the list is the right starter set.

## Publishing a reviewed item
Change `reviewStatus` to `approved`, add `reviewedBy` and `reviewedOn`, move the object to
`assets/content/hub_content.json`, and run `flutter test test/features/hubs`. The Exercises,
Workouts, Meditations and Spa screens then show it; Exercises also feed Build Your Workout.

## Sounds: concepts only, audio blocked
Concepts for a calming-sounds library (soft rain, a stream, gentle waves, wind in leaves,
a low steady hum, a quiet room tone). **No audio exists and none can be bundled or
streamed until a recording with confirmed rights is supplied** (original, or licensed for
commercial use with the licence recorded in `rights`). The app also has no audio playback
plugin yet; adding one (and a player with start, pause, stop and volume) is a small
technical task to do once there is a track to play, so no inert player is shipped.
