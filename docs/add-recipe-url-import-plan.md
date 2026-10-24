# Add a Recipe, part 3: URL import — technical and licensing plan

**Plan only. Nothing here is built; it needs your approval, and your answers to the decisions at the end, before any code.** It follows your preferred approach: structured data only where reuse is permitted, source and attribution kept, no copied photos or instructions without permission, a link-only or user-entered option where full import isn't allowed, a review step before saving, and no paid or external service.

## 1. What an import is
The user pastes a link and taps **Import**. The phone fetches that one page itself (no server of ours, no third-party API, no AI) and reads its `schema.org/Recipe` data (JSON-LD, the structured block most recipe sites publish for search engines). The result opens in the same editor as Part 1 and Part 2 as an **editable draft with a source line**. Nothing is saved until the user reviews and taps Save.

## 2. Which sources are supported (the allow-list)
Reuse is a property of each site's terms, so support is **per site, by explicit allow-list**, not "any URL":

| Level | What the app may keep | When |
|---|---|---|
| `full` | title, ingredients, method, times, servings, plus attribution | only a site that clearly permits it (open licence such as CC BY / CC BY-SA, or written permission) |
| `ingredients` | title, ingredients, times, servings, plus attribution and a link to the method (the method text is **not** stored) | a site whose terms are unclear or restrictive about method text; ingredient lists are factual, but this is still a call for you to make |
| `link-only` | title, the link and a short note from the user | **everything else (the default for any unknown site)** |

- The list is a bundled file (`import_sources.json`: domain, level, attribution text, the terms URL, the date I checked it). **It starts empty**, so at launch every site is `link-only` until a site is added deliberately. I can't verify a site's terms from here, so each addition needs your review of its terms and `robots.txt`; candidates worth checking are openly licensed recipe collections (for example the Wikibooks Cookbook, CC BY-SA, which would also need share-alike notice).
- **Photos are never fetched, downloaded or stored**, at any level. The imported recipe has no picture (the normal placeholder tile).
- **Link-only and user-entered**: unknown or restricted sites open the manual editor pre-filled with the title (if readable from the page's own metadata) and the link in "About it", so the user can type or paste (Part 2) their own ingredients and steps. Nothing from the page body is kept.

## 3. How the limits are enforced in code
- **Level is checked on the parsed result, not just on the UI**: the importer's output type for a `ingredients` or `link-only` site has no method field to fill, so it can't be stored by mistake. Tests assert this per level.
- **Network rules**: HTTPS only; one GET; a 10 s timeout; 1 MB maximum body; `text/html` only; redirects followed only to HTTPS on the same site; `localhost`, private and link-local addresses refused; no cookies, no referrer, a plain app User-Agent; **`robots.txt` is read first and a disallow means link-only**; at most one request per tap.
- **Untrusted content**: parse JSON-LD only; never render the fetched HTML or run its scripts; strip tags and control characters; cap field and list sizes; ignore anything that isn't a plain `Recipe`.
- **Privacy**: fetching tells that site the user's IP address and that they looked at that page, so the first import shows a notice ("This contacts the site. They can see you asked for this page") with Continue / Cancel. The URL is never logged, and no analytics or crash report includes it.
- **Attribution**: every imported recipe keeps its source name and URL (stored additively inside the recipe's own JSON, so **no database migration**) and shows "Imported from <site> · View original" on its recipe screen. No claim of authorship.
- **No paid or third-party service**; no API key; nothing is sent anywhere except the one page request the user asked for. Export my data includes the source line.

## 4. Tests I would add
Fixture pages per allow-listed site; every level's output shape; redirect, size, content-type, private-address and robots cases; malformed and hostile JSON-LD; review-before-save; link-only fallback; the privacy notice; 320 pt and large text, light and dark.

## 5. Decisions I need from you
1. **Seed the allow-list now, or launch link-only?** (My recommendation: launch with link-only plus the review and attribution UI, and add sites one at a time as you approve each.)
2. For a site with unclear terms, do you accept `ingredients` level (ingredients and times only, link to the method), or should it stay `link-only`?
3. Is a one-time network notice enough, or do you want it on every import?
4. Should `robots.txt` disallow always force link-only (my recommendation: yes)?
