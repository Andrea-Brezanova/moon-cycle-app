# Move and Relax: small content libraries (proposal)

No code and no content is added by this document. Nothing here is published until
you have reviewed it. It keeps the Home cards (3 Ways to Move, 3 Minutes of Calm) and
the existing tabs; it fills the two tabs with a few things that genuinely work.

## Principles
- A small number of finished experiences beats a large unfinished library; no
  placeholder screen or inert button in a release.
- Original content only, written by us (an AI may draft, a person reviews every
  line): no copied scripts, no imitation of a living creator's voice, no third-party
  music. Narration and sound need confirmed rights before they ship.
- General wellbeing language. Movement is not a medical prescription: every session
  carries a short safety note ("Stop if anything hurts; this isn't medical advice;
  check with a professional if you have a condition or are unsure").
- No cycle-phase efficacy claims. Phase can *suggest* gentler or livelier ideas for
  the Home daily picks, framed as options.
- Saving: each item has a Save control that adds it to My Collections (My Workouts or
  My Spa/My Sounds) by reference to its id, using the same store as links.

## Move: first set (about 12 sessions, text and timer, no video)
| Group | Sessions | Notes |
|---|---|---|
| Walking | Easy 10-minute walk; Steady 20-minute walk; Walk with intervals (gentle) | A timer with cues; no pace targets |
| Mobility | Morning wake-up (5 min); Hips and back (8 min); Desk-break neck and shoulders (4 min) | Step list, one move per screen, hold times |
| Stretching | Evening unwind (8 min); Legs and calves (6 min) | |
| Yoga (beginner) | Gentle flow (12 min); Seated and floor stretches (10 min) | Descriptions only; no photos until original ones exist |
| Strength (beginner) | Bodyweight basics (12 min); Light-weights or water-bottle circuit (12 min) | Reps are ranges, rest is encouraged |

Each: title, duration, level (gentle / easy / moderate), equipment, 4-8 plain steps,
safety note, a start button that runs a step-by-step timer with pause, and Save.
"3 Ways to Move" on Home draws three of these (stable all day, like 3 a Day).

## Relax: first set (about 6 experiences)
| Experience | What it is | Rights |
|---|---|---|
| Three calm breaths (1 min) | Animated pacing circle with a quiet haptic, in/out counts | Ours; no audio |
| Paced breathing (3 and 5 min) | Same guide, longer, adjustable pace | Ours |
| Body scan (5 min) | Step text shown one line at a time with a timer | Ours (written text) |
| Short mindfulness (3 min) | Same format | Ours |
| Ambient sound (optional) | One looped ambient track | Only if a properly licensed or original recording is supplied |
| Guided audio | Not in the first set | Needs recorded narration with confirmed rights |

"3 Minutes of Calm" on Home opens the 3-minute breathing experience. Playback controls
are real (start, pause, stop, volume where audio exists). A player is never shown
unless it plays something.

## Editorial review process
1. Draft (author, optionally AI-assisted) into a content file under
   `assets/content/` (`workouts.json`, `relax.json`), each item `reviewStatus:
   draft`.
2. Reviewer checks: accuracy and safety of steps, no health claims, no copied text,
   reading level, rights for any audio or image. Sets `reviewStatus: approved`,
   `reviewedBy`, `reviewedOn`.
3. The app only shows items with `approved`; a test fails if an item ships without it.
4. Changes after release are new reviewed versions.

## Delivery
1. Workout library MVP: content file, list/detail/timer, Save to My Workouts, Home
   card link. (Own PR.)
2. Relax MVP: breathing guide and text sessions, Save to My Sounds/My Spa, Home card
   link. (Own PR.)
3. Optional audio later, once rights are confirmed.

## Decisions for you
1. Approve this first set (or trim it).
2. Who reviews the workout steps and safety wording before release?
3. Is text-and-timer acceptable for the first release, with no video or narration?
4. Confirm the rename My Sounds → My Spa in the next Collections refinement (storage
   and navigation stay as they are until that PR).
