import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../core/design/moon_theme.dart';
import '../../../core/design/tokens/hero_tokens.dart';
import '../../../core/design/tokens/moon_typography.dart';
import '../../../core/design/widgets/pressable.dart';
import '../../../core/domain/phase.dart';
import '../application/collections_providers.dart';
import 'collection_photos.dart';

/// The first thing on the Me page: the way into My Collections. A tinted card
/// with a live count and a few of its photographs.
class CollectionsCard extends ConsumerWidget {
  const CollectionsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.moon;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final total = ref.watch(collectionSummaryProvider).total;
    final headline = total == 0
        ? 'Start your collection'
        : '$total ${total == 1 ? 'thing' : 'things'} you love';
    return Pressable(
      key: const ValueKey('my-collections-card'),
      onTap: () => context.push(Routes.collections),
      semanticLabel:
          'My Collections. $headline. Recipes, workouts, spa and links. '
          'Open My Collections',
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 14, 14),
        decoration: BoxDecoration(
          color: dark
              ? HeroTokens.darkSolid
              : HeroTokens.lightWash[Phase.follicular],
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MY COLLECTIONS',
                    style: dmSans(
                      11.5,
                      weight: FontWeight.w700,
                      height: 1.2,
                      tracking: 0.2,
                      color: c.textMuted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    headline,
                    style: fraunces(24, height: 1.15, color: c.text),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Recipes, workouts, spa and links',
                    style: dmSans(13, height: 1.4, color: c.textMuted),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Open My Collections →',
                    style:
                        dmSans(
                          14,
                          weight: FontWeight.w600,
                          height: 1.2,
                          color: c.text,
                        ).copyWith(
                          decoration: TextDecoration.underline,
                          decorationColor: c.ochre,
                          decorationThickness: 2,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 84,
              height: 56,
              child: Stack(
                children: [
                  for (final (i, cat) in CollectionCategory.values.indexed)
                    Positioned(
                      left: i * 22.0,
                      top: i == 1 ? 0 : 8,
                      child: Container(
                        width: 38,
                        height: 44,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: c.bg, width: 2),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: CollectionPhoto(cat),
                      ),
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
