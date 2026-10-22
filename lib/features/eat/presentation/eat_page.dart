import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../app/shell/tab_scroll.dart';
import '../../../core/design/moon_theme.dart';
import '../../../core/design/tokens/moon_layout.dart';
import '../../../core/design/tokens/moon_typography.dart';
import '../../../core/design/widgets/editorial_text.dart';
import '../../../core/design/widgets/moon_icon.dart';
import '../../../core/design/widgets/pressable.dart';
import '../../../core/domain/phase.dart';
import '../../foods/application/browse_scope.dart';

/// Eat: the hub. A photograph and a short introduction, then the three ways
/// in: Foods, Recipes and the meal builder. Each opens an existing page.
class EatPage extends ConsumerWidget {
  const EatPage({super.key});

  /// The hero photograph. A recipe photo already in the app, standing in
  /// until the approved photograph is added (see docs/v2-ui-roadmap.md).
  static const heroAsset =
      'assets/images/recipes/red-cabbage-apricot-chickpea-salad.jpg';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.moon;
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        bottom: false,
        // Five blocks, all built: no need for a lazy list.
        child: SingleChildScrollView(
          controller: ref.watch(tabScrollProvider).of(AppTab.eat),
          padding: const EdgeInsets.fromLTRB(
            MoonSpace.gutter,
            10,
            MoonSpace.gutter,
            42,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        'Eat',
                        style: MoonType.h1.copyWith(color: c.text),
                      ),
                    ),
                  ),
                  Pressable(
                    key: const ValueKey('eat-search'),
                    // The foods search lives on "All foods".
                    onTap: () {
                      ref.read(foodsScopeProvider.notifier).showAll();
                      context.push(Routes.eatFoods);
                    },
                    semanticLabel: 'Search foods',
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: Center(
                        child: MoonIcon(
                          MoonIconName.search,
                          size: 22,
                          color: c.text,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const _Intro(),
              const SizedBox(height: 16),
              _HubCard(
                icon: MoonIconName.apple,
                phase: Phase.menstrual,
                title: 'Foods',
                body: 'Browse foods by phase and benefit.',
                onTap: () => context.push(Routes.eatFoods),
              ),
              const SizedBox(height: 12),
              _HubCard(
                icon: MoonIconName.utensils,
                phase: Phase.ovulatory,
                title: 'Recipes',
                body: 'Find nourishing recipes for every phase.',
                onTap: () => context.push(Routes.eatRecipes),
              ),
              const SizedBox(height: 12),
              _HubCard(
                icon: MoonIconName.recipes,
                phase: Phase.luteal,
                title: 'Meal builder',
                body: 'Create a balanced meal with foods or recipes.',
                onTap: () => context.push(Routes.mealBuilder()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The photograph with the "Nourish your cycle" card joined beneath it.
class _Intro extends StatelessWidget {
  const _Intro();

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    return Container(
      decoration: BoxDecoration(
        color: c.raised,
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(24),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Decorative: the heading below says what the page is.
          ExcludeSemantics(
            child: AspectRatio(
              aspectRatio: 1.86,
              child: Image.asset(
                EatPage.heroAsset,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.medium,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 16, 22, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                EditorialHeading(
                  italicLastWord('Nourish your cycle'),
                  style: fraunces(28, height: 1.15, color: c.text),
                ),
                const SizedBox(height: 8),
                Text(
                  'Seasonal foods, simple recipes and meal ideas to support '
                  'your current phase.',
                  style: dmSans(15, height: 1.5, color: c.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A full-width navigation card: pastel icon disc, title, a line, a chevron.
class _HubCard extends StatelessWidget {
  const _HubCard({
    required this.icon,
    required this.phase,
    required this.title,
    required this.body,
    required this.onTap,
  });

  final MoonIconName icon;

  /// The phase whose palette tints the icon disc.
  final Phase phase;
  final String title;
  final String body;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    final palette = c.phase(phase);
    return Pressable(
      onTap: onTap,
      semanticLabel: '$title. $body',
      child: Container(
        constraints: const BoxConstraints(minHeight: 88),
        padding: const EdgeInsets.fromLTRB(18, 14, 16, 14),
        decoration: BoxDecoration(
          color: c.raised,
          border: Border.all(color: c.line),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          children: [
            ExcludeSemantics(
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: palette.tint,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: MoonIcon(icon, size: 24, color: palette.text),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: fraunces(21, height: 1.15, color: c.text)),
                  const SizedBox(height: 3),
                  Text(
                    body,
                    style: dmSans(14, height: 1.4, color: c.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            MoonIcon(MoonIconName.chev, size: 18, color: c.chevron),
          ],
        ),
      ),
    );
  }
}
