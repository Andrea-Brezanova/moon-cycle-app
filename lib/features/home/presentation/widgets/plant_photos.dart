import 'package:flutter/painting.dart';

/// A curated photo for a plant, and where in the picture the subject is.
class PlantPhoto {
  const PlantPhoto(this.asset, this.focus, this.photographer);

  final String asset;

  /// Credited on the Credits & Sources page (all photos are from Unsplash).
  final String photographer;

  /// The subject's position as a share of the picture (0 to 1, from the top
  /// left); the tile crops around it.
  final Offset focus;

  Alignment get alignment => Alignment(focus.dx * 2 - 1, focus.dy * 2 - 1);
}

/// The only foods with a photo so far. A plant not listed here shows the
/// existing emoji placeholder; add a photo by adding a line (and its credit in
/// `docs/photo-credits.md`).
const plantPhotos = <String, PlantPhoto>{
  'broccoli': PlantPhoto(
    'assets/images/foods/broccoli.jpg',
    Offset(0.28, 0.72),
    'Marco Palumbo',
  ),
  'avocado': PlantPhoto(
    'assets/images/foods/avocado.jpg',
    Offset(0.58, 0.62),
    'Анна Ширяева',
  ),
  'blueberry': PlantPhoto(
    'assets/images/foods/blueberry.jpg',
    Offset(0.62, 0.42),
    'Spoorthi J',
  ),
};
