# Home "Log diary" shortcut vs the Premium gate (to decide)

Status: documented only. **No production entitlement was changed.**

| Place | Behaviour today |
|---|---|
| Entitlements (`defaultFeatureTiers`) | `Feature.logDiary` is **Premium** (Plus, including the launch promo, does not unlock it). `shoppingList` is free. |
| Home "Go to" cards | Shopping list and Log diary show **no lock and no label**; both look free. |
| Tapping Log diary on Home (free user) | Opens My Diary, which shows "Log Diary is part of Moon Cycle Premium." and nothing else (the page applies the gate itself). |
| More › My Diary (free user) | Same: opens the page, same Premium message. |
| Food and Recipe detail › Log meal | Free users: Food detail's button shows a lock and goes to Subscription; Recipe detail hides the button. |
| Debug builds | "All features unlocked (dev)" makes every entry point work. |

So a free user sees an unlocked card that leads to a locked page. Options to
decide (not implemented): make My Diary free (set the tier, update the tests that
pin Premium), keep it Premium and show a lock on the Home card and More row, or
split it (meals free, symptoms Premium).
