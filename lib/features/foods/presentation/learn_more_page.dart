import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../core/design/moon_theme.dart';
import '../../../core/design/tokens/moon_layout.dart';
import '../../../core/design/widgets/editorial_text.dart';
import '../../../core/design/widgets/moon_list.dart';
import '../../content/application/content_providers.dart';
import '../../cycle/application/viewing_phase.dart';
import 'widgets/phase_intro.dart';

/// "Your focus › Learn more": the phase explanation for the phase being
/// viewed. Home links here; the text is the same approved copy Foods used to
/// show.
class LearnMorePage extends ConsumerWidget {
  const LearnMorePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.moon;
    final phase = ref.watch(viewingPhaseProvider);
    final content = ref.watch(catalogueProvider).phase(phase);
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 42 + 76),
          children: [
            SubScreenHeader(
              backLabel: 'Home',
              onBack: () =>
                  context.canPop() ? context.pop() : context.go(Routes.home),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                MoonSpace.gutter,
                8,
                MoonSpace.gutter,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Overline('Your focus · ${content.name}'),
                  const SizedBox(height: 14),
                  PhaseIntro(
                    phase: phase,
                    content: content,
                    palette: c.phase(phase),
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
