import 'package:flutter/material.dart';

import '../../../core/design/moon_theme.dart';
import '../../../core/design/tokens/moon_typography.dart';
import '../../../core/design/widgets/editorial_text.dart';
import '../../../core/design/widgets/moon_icon.dart';
import '../../../core/design/widgets/moon_surfaces.dart';
import '../../../core/design/widgets/pressable.dart';
import '../../content/domain/catalogue.dart';
import '../../content/domain/food.dart';
import '../../content/domain/text_match.dart';

/// What the user picked in [showAvoidFoodSheet].
sealed class AvoidChoice {
  const AvoidChoice();
}

final class AvoidCatalogueFood extends AvoidChoice {
  const AvoidCatalogueFood(this.food);

  final Food food;
}

final class AvoidTypedFood extends AvoidChoice {
  const AvoidTypedFood(this.label);

  final String label;
}

/// "Add another" (onboarding) and the search in Allergies: find a food in the
/// catalogue to avoid, or add what was typed when nothing matches.
Future<AvoidChoice?> showAvoidFoodSheet(
  BuildContext context, {
  required Catalogue catalogue,
}) => showMoonSheet<AvoidChoice>(
  context,
  builder: (_) => _AvoidFoodSheet(catalogue: catalogue),
);

class _AvoidFoodSheet extends StatefulWidget {
  const _AvoidFoodSheet({required this.catalogue});

  final Catalogue catalogue;

  @override
  State<_AvoidFoodSheet> createState() => _AvoidFoodSheetState();
}

class _AvoidFoodSheetState extends State<_AvoidFoodSheet> {
  String _query = '';

  List<Food> get _matches {
    final q = normaliseName(_query);
    if (q.isEmpty) return const [];
    final found = [
      for (final f in widget.catalogue.foods)
        if (normaliseName(f.name).contains(q) ||
            f.synonyms.any((s) => normaliseName(s).contains(q)))
          f,
    ]..sort((a, b) => a.displayName.compareTo(b.displayName));
    return found.take(8).toList();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    final matches = _matches;
    final typed = _query.trim();
    // Typed entries are for foods the catalogue doesn't have.
    final offerTyped = typed.isNotEmpty && matches.isEmpty;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: EditorialHeading(
            'Add a food to *avoid*',
            style: fraunces(30, height: 1.08),
          ),
        ),
        const SizedBox(height: 18),
        MoonTextField(
          hint: 'Search foods to avoid',
          leadingIcon: MoonIconName.search,
          autofocus: true,
          onChanged: (v) => setState(() => _query = v),
          onSubmitted: (_) {
            if (matches.length == 1) {
              Navigator.pop(context, AvoidCatalogueFood(matches.single));
            } else if (offerTyped) {
              Navigator.pop(context, AvoidTypedFood(typed));
            }
          },
        ),
        const SizedBox(height: 8),
        Flexible(
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final food in matches)
                _Row(
                  label: food.displayName,
                  subtitle: food.qualifier,
                  onTap: () => Navigator.pop(context, AvoidCatalogueFood(food)),
                ),
              if (offerTyped)
                _Row(
                  label: 'Add “$typed”',
                  icon: MoonIconName.plus,
                  onTap: () => Navigator.pop(context, AvoidTypedFood(typed)),
                ),
              if (typed.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Text(
                    'Type a food, for example mushrooms or coriander.',
                    style: dmSans(14, height: 1.5, color: c.textMuted),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    this.subtitle,
    this.icon,
    required this.onTap,
  });

  final String label;
  final String? subtitle;
  final MoonIconName? icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    return Pressable(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 52),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: c.line)),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              MoonIcon(icon!, size: 18, color: c.text, strokeWidth: 2),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: dmSans(
                      16,
                      weight: FontWeight.w500,
                      height: 1.25,
                      color: c.text,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: dmSans(12, height: 1.3, color: c.textMuted),
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
