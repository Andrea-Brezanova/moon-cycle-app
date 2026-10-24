import 'package:flutter/painting.dart';

/// A photograph on Home: the asset and where its subject is (0 to 1 from the
/// top left), so the crop keeps it. Credits are in `docs/photo-credits.md` and
/// on the Credits & Sources page.
class HomePhoto {
  const HomePhoto(this.asset, this.focus, this.photographer);

  final String asset;
  final Offset focus;
  final String photographer;
}

/// The three "Today's picks" photographs (Unsplash).
const homePhotos = (
  eat: HomePhoto(
    'assets/images/home/home_eat_broccoli.jpg',
    Offset(0.40, 0.50),
    'Louis Hansel',
  ),
  move: HomePhoto(
    'assets/images/home/home_move_yoga_mat.jpg',
    Offset(0.64, 0.62),
    'Louise Vildmark',
  ),
  relax: HomePhoto(
    'assets/images/home/home_relax_tea.jpg',
    Offset(0.48, 0.60),
    'Olena Bohovyk',
  ),
);
