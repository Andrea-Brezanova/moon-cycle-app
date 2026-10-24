import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../core/design/moon_theme.dart';
import '../../../core/design/tokens/moon_layout.dart';
import '../../../core/design/tokens/moon_typography.dart';
import '../../../core/design/widgets/editorial_text.dart';
import '../../../core/design/widgets/moon_list.dart';
import '../../home/presentation/widgets/home_photos.dart';
import '../../home/presentation/widgets/plant_photos.dart';

/// More › Credits & Sources: who made the photographs and where recipes from
/// other providers come from. Photo credits are read from the same table that
/// shows the photos, so a photo can't be added without its credit.
class CreditsPage extends StatelessWidget {
  const CreditsPage({super.key});

  static const _providers = [
    (
      'TheMealDB',
      'Recipes found through TheMealDB (themealdb.com) are credited on the '
          'recipe, with a link to the original source. Development builds only '
          'for now.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    final photos = plantPhotos.entries.toList();
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 42),
          children: [
            SubScreenHeader(
              backLabel: 'More',
              title: 'Credits & Sources',
              titleSize: 36,
              onBack: () => context.canPop()
                  ? context.pop()
                  : context.go(AppTab.more.path),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                MoonSpace.gutter,
                12,
                MoonSpace.gutter,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Overline('Food photography'),
                  const SizedBox(height: 8),
                  Text(
                    'Photographs from Unsplash, used under the Unsplash '
                    'licence.',
                    style: dmSans(15, height: 1.5, color: c.textMuted),
                  ),
                  const SizedBox(height: 12),
                  for (final e in photos)
                    _Line(
                      title: e.key.replaceAll('-', ' '),
                      detail: '${e.value.photographer} / Unsplash',
                    ),
                  const SizedBox(height: 12),
                  for (final e in [
                    ('Home · eat', homePhotos.eat),
                    ('Home · move', homePhotos.move),
                    ('Home · relax', homePhotos.relax),
                  ])
                    _Line(
                      title: e.$1,
                      detail: '${e.$2.photographer} / Unsplash',
                    ),
                  const SizedBox(height: 30),
                  const Overline('Recipe providers'),
                  const SizedBox(height: 8),
                  for (final (name, text) in _providers)
                    _Line(title: name, detail: text),
                  const SizedBox(height: 30),
                  const Overline('Moon Cycle'),
                  const SizedBox(height: 8),
                  Text(
                    'Moon Cycle recipes and food guidance are written by the '
                    'Moon Cycle team.',
                    style: dmSans(15, height: 1.5, color: c.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.title, required this.detail});

  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title[0].toUpperCase() + title.substring(1),
            style: dmSans(
              16,
              weight: FontWeight.w600,
              height: 1.3,
              color: c.text,
            ),
          ),
          Text(detail, style: dmSans(14, height: 1.45, color: c.textMuted)),
        ],
      ),
    );
  }
}
