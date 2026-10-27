# Hero image requests (Move and Relax)

Move and Relax now have the same hero card as Eat (full-width card, 1.86 aspect image,
24 pt radius, heading and line below). Until dedicated photographs are approved, each
uses an image already in the app that fits the section; Eat's hero is likewise a recipe
photo standing in.

| Hub | Stand-in now | Asset to request |
|---|---|---|
| Move | `assets/images/home/home_move_yoga_mat.jpg` (a yoga mat; also used on Home) | A calm, editorial photograph of gentle movement (mat, soft daylight, ivory/warm palette), no identifiable face, 1.86:1 or larger, original or licensed with the licence recorded |
| Relax | `assets/images/home/home_relax_tea.jpg` (a cup of tea; also used on Home) | A calm, editorial photograph of rest (tea, blanket, soft daylight, ivory/warm palette), same requirements |
| Eat | `assets/images/recipes/red-cabbage-apricot-chickpea-salad.jpg` | A dedicated Eat hero (existing request) |

To change a hero: replace the asset path in `HubHomePage.move()` / `.relax()` (or
`EatPage.heroAsset`) and credit the photograph on the Credits page. Nothing else changes.
