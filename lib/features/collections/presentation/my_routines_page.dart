import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../core/design/moon_theme.dart';
import '../../../core/design/widgets/centered_header.dart';
import '../../../core/design/widgets/moon_icon.dart';
import '../../../core/design/widgets/moon_surfaces.dart';
import '../../../core/domain/phase.dart';

/// My Routines. Saving a routine needs a new table (see
/// `docs/my-routines-migration-proposal.md`), which is awaiting approval, so
/// this page says so plainly instead of offering controls that would not keep
/// anything.
class MyRoutinesPage extends StatelessWidget {
  const MyRoutinesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            CenteredHeader(
              title: 'My Routines',
              onBack: () => context.canPop()
                  ? context.pop()
                  : context.go(Routes.collections),
            ),
            Expanded(
              child: ListView(
                children: [
                  EmptyState(
                    icon: MoonIconName.clock,
                    title: 'Routines are not available yet',
                    body:
                        'A routine will let you string saved workouts, spa '
                        'moments and links into a sequence you can reuse, like '
                        'a morning stretch or an evening wind-down. Keeping '
                        'routines needs a small addition to how this phone '
                        'stores your data, so it is waiting for review. '
                        'Nothing you have saved is affected.',
                    palette: c.phase(Phase.luteal),
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
