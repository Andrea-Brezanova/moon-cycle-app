import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/moon_theme.dart';
import '../../../core/design/tokens/moon_typography.dart';
import '../../../core/design/widgets/moon_icon.dart';
import '../../../core/design/widgets/moon_segmented.dart';
import '../../../core/design/widgets/moon_surfaces.dart';
import '../../../core/design/widgets/pressable.dart';
import '../../content/application/content_providers.dart';
import '../../content/domain/text_match.dart';
import '../../generation/application/generation_providers.dart';
import '../domain/diary_entry.dart';

/// What the user picked to log.
typedef DiaryPick = ({DiaryItemKind kind, String id, String title});

/// A search over foods and recipes (the user's own included). Not filtered by
/// diet: the diary records what was eaten, not what is suggested.
Future<DiaryPick?> showDiaryItemPicker(BuildContext context) =>
    showMoonSheet<DiaryPick>(
      context,
      fromTop: 96,
      builder: (_) => const _Picker(),
    );

class _Picker extends ConsumerStatefulWidget {
  const _Picker();

  @override
  ConsumerState<_Picker> createState() => _PickerState();
}

class _PickerState extends ConsumerState<_Picker> {
  var _kind = DiaryItemKind.food;
  var _query = '';

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    final catalogue = ref.watch(catalogueProvider);
    final mine = ref.watch(personalRecipesProvider).value ?? const [];
    final q = normaliseName(_query);

    final List<DiaryPick> items = _kind == DiaryItemKind.food
        ? [
            for (final f in catalogue.foods)
              if (q.isEmpty || normaliseName(f.displayName).contains(q))
                (kind: DiaryItemKind.food, id: f.id, title: f.displayName),
          ]
        : [
            for (final r in catalogue.recipes)
              if (q.isEmpty || normaliseName(r.title).contains(q))
                (kind: DiaryItemKind.recipe, id: r.id, title: r.title),
            for (final p in mine)
              if (q.isEmpty || normaliseName(p.recipe.title).contains(q))
                (kind: DiaryItemKind.recipe, id: p.id, title: p.recipe.title),
          ];
    items.sort(
      (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text('Add to diary', style: fraunces(28, color: c.text)),
        ),
        const SizedBox(height: 14),
        MoonSegmented<DiaryItemKind>(
          semanticLabel: 'Kind',
          options: const [
            (DiaryItemKind.food, 'Foods'),
            (DiaryItemKind.recipe, 'Recipes'),
          ],
          selected: _kind,
          onChanged: (k) => setState(() => _kind = k),
        ),
        const SizedBox(height: 12),
        MoonTextField(
          hint: _kind == DiaryItemKind.food ? 'Search foods' : 'Search recipes',
          leadingIcon: MoonIconName.search,
          onChanged: (v) => setState(() => _query = v),
        ),
        const SizedBox(height: 8),
        Flexible(
          child: items.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    'Nothing found.',
                    style: dmSans(15, color: c.textMuted),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: items.length,
                  itemBuilder: (context, i) {
                    final item = items[i];
                    return Pressable(
                      onTap: () => Navigator.pop(context, item),
                      semanticLabel: item.title,
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 48),
                        alignment: Alignment.centerLeft,
                        decoration: BoxDecoration(
                          border: Border(top: BorderSide(color: c.line)),
                        ),
                        child: Text(
                          item.title,
                          style: dmSans(
                            16,
                            weight: FontWeight.w500,
                            color: c.text,
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
