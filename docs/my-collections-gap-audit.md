# My Collections: gap audit against the approved canvas

Compared on `main` at 3bf9e44 (after PRs #19 and #23) with the canvas boards (Me, My
Collections landing, My Workouts, My Spa, Saved links, Add to My Collections, Saved
link detail, Recipes toast). Names, counts and creators on the boards are
placeholders; the app shows only real data and shows no fake player.

| Screen | Approved design | State | Gap / plan |
|---|---|---|---|
| **Me** | Title + "Your own space in Moon Cycle.", a tinted My Collections card (live count, "Open My Collections", photos), then four rows: My Diary, Shopping list, Settings, Account & Plus | Card and subtitle **done in PR A**. The page still lists the existing Personalisation / App / Account / Support groups instead of one Settings row and one Account & Plus row | Folding the groups into Settings and Account & Plus sub-pages is a navigation change: **needs your OK**, then its own PR (A2) |
| **My Collections landing** | Large My Recipes photo tile, My Workouts and My Spa tiles, search, Recently saved with thumbnails and source badges, + button | **Done in PR A** (real counts, working search, + opens Add). The older "Saved links & inspiration" row is not built (links live inside categories) | none |
| **My Recipes** | Existing screen | Reuses saved + written recipes, heart, Links filter (PR #23) | Visual restyle to the board (PR C) |
| **My Workouts** | Filters (All / Saved / Created by me), rows with thumbnail, source badge, meta, note, external-link icon | List of links exists; **no filters yet**, rows are plain cards | PR C (restyle + filters); Moon Cycle workouts and activity-type filters wait for reviewed content (PR D) |
| **My Spa** | Filters (Meditation / Breathing / Links), rows, play buttons for Moon Cycle sessions | **Renamed in PR A**; links listed; no filters | PR C; **no play buttons**: there are no approved recordings |
| **Add to My Collections** | Form: link, title, creator, save-to, note | Works (PR #23): category chips, address, name, creator, note, validation | PR C: match the board's layout (segmented header, platform note) and add Spotify |
| **Saved link detail** | Video-style header, title, creator, Open in <platform>, My note, Collection / Saved / Address, Edit, Remove | **Missing**: a row opens the original; the edit form is the only detail | PR C |
| **Recently saved** | Rows with thumbnails | Done in PR A (real data) | none |
| **Data** | v9 table | Migration **already merged** in #23 (additive, tested from v8, export and delete covered) | Nothing more to migrate; no new schema for A to C |

Not built on purpose: fake playable recordings, fictional creators, a Saved links
category, scraping or downloading anything.
