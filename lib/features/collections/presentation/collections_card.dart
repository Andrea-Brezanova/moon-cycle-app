import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../core/design/moon_theme.dart';
import '../../../core/design/tokens/moon_typography.dart';
import '../../../core/design/widgets/moon_icon.dart';
import '../../../core/design/widgets/pressable.dart';
import '../../../core/domain/phase.dart';
import '../application/collections_providers.dart';

/// The first thing on the Me page: the way into My Collections.
class CollectionsCard extends ConsumerWidget {
  const CollectionsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.moon;
    final total = ref
        .watch(collectionCountsProvider)
        .values
        .fold<int>(0, (a, b) => a + b);
    final subtitle = total == 0
        ? 'Recipes, workouts and sounds you save or add.'
        : '$total ${total == 1 ? 'item' : 'items'} saved';
    return Pressable(
      key: const ValueKey('my-collections-card'),
      onTap: () => context.push(Routes.collections),
      semanticLabel: 'My Collections. $subtitle',
      child: Container(
        constraints: const BoxConstraints(minHeight: 88),
        padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
        decoration: BoxDecoration(
          color: c.phase(Phase.luteal).tint,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My Collections',
                    style: fraunces(24, height: 1.15, color: c.text),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: dmSans(14, height: 1.4, color: c.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            MoonIcon(
              MoonIconName.chev,
              size: 18,
              color: c.textMuted,
              strokeWidth: 2,
            ),
          ],
        ),
      ),
    );
  }
}
