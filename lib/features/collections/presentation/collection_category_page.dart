import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../core/design/moon_theme.dart';
import '../../../core/design/tokens/moon_layout.dart';
import '../../../core/design/widgets/centered_header.dart';
import '../../../core/design/widgets/moon_icon.dart';
import '../../../core/design/widgets/moon_surfaces.dart';
import '../../../core/domain/phase.dart';
import '../application/collections_providers.dart';

/// My Workouts or My Sounds. Nothing can be saved here until Moon Cycle's
/// workouts and sounds exist, so it says so plainly: no buttons that do
/// nothing.
class CollectionCategoryPage extends ConsumerWidget {
  const CollectionCategoryPage({super.key, required this.category});

  final CollectionCategory category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.moon;
    final workouts = category == CollectionCategory.workouts;
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            CenteredHeader(
              title: workouts ? 'My Workouts' : 'My Sounds',
              onBack: () => context.canPop()
                  ? context.pop()
                  : context.go(Routes.collections),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                MoonSpace.gutter,
                24,
                MoonSpace.gutter,
                0,
              ),
              child: EmptyState(
                icon: workouts ? MoonIconName.move : MoonIconName.relax,
                title: workouts
                    ? 'No workouts saved yet'
                    : 'No sounds saved yet',
                body: workouts
                    ? 'Workouts you save or add will be kept here, privately '
                          'on this phone.'
                    : 'Meditations, breathing sessions and sounds you save or '
                          'add will be kept here, privately on this phone.',
                palette: c.phase(workouts ? Phase.luteal : Phase.ovulatory),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
