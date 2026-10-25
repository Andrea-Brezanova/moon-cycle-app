import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../core/design/moon_theme.dart';
import '../../../core/design/tokens/hero_tokens.dart';
import '../../../core/design/tokens/moon_layout.dart';
import '../../../core/design/tokens/moon_typography.dart';
import '../../../core/design/widgets/centered_header.dart';
import '../../../core/design/widgets/editorial_text.dart';
import '../../../core/design/widgets/moon_icon.dart';
import '../../../core/design/widgets/moon_surfaces.dart';
import '../../../core/design/widgets/pressable.dart';
import '../../../core/domain/phase.dart';
import '../data/collection_link_repository.dart';
import '../domain/collection_link.dart';
import 'open_link.dart';
import 'widgets/link_row.dart';

/// A saved link in full: where it is from, who made it, the user's own note,
/// when it was saved and where it lives, with Open, Edit and Remove. Nothing
/// is previewed or downloaded; the card at the top is only a symbol.
class CollectionLinkDetailPage extends ConsumerWidget {
  const CollectionLinkDetailPage({super.key, required this.linkId});

  final String linkId;

  static const _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  String _date(DateTime d) => '${d.day} ${_months[d.month - 1]}';

  String _kindLine(CollectionLink l) => switch (l.platform) {
    LinkPlatform.youtube => 'Video on YouTube',
    LinkPlatform.tiktok => 'Video on TikTok',
    LinkPlatform.instagram => 'Post on Instagram',
    LinkPlatform.pinterest => 'Pin on Pinterest',
    LinkPlatform.spotify => 'Audio on Spotify',
    LinkPlatform.website => 'Link on ${l.host}',
  };

  String _openLabel(CollectionLink l) => l.platform == LinkPlatform.website
      ? 'Open website'
      : 'Open in ${l.platform.label}';

  String _collection(LinkCategory c) => switch (c) {
    LinkCategory.recipes => 'My Recipes',
    LinkCategory.workouts => 'My Workouts',
    LinkCategory.sounds => 'My Spa',
  };

  Future<void> _remove(
    BuildContext context,
    WidgetRef ref,
    CollectionLink link,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove this link?'),
        content: const Text(
          'It will be removed from My Collections. The original is not '
          'affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep it'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(collectionLinkRepositoryProvider).delete(link.id);
    if (context.mounted) context.pop();
  }

  Future<void> _more(
    BuildContext context,
    WidgetRef ref,
    CollectionLink link,
  ) => showMoonSheet<void>(
    context,
    builder: (ctx) {
      final c = ctx.moon;
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              'Move to',
              style: fraunces(28, height: 1.1, color: c.text),
            ),
          ),
          const SizedBox(height: 12),
          for (final cat in LinkCategory.values)
            Pressable(
              key: ValueKey('move-${cat.name}'),
              onTap: cat == link.category
                  ? null
                  : () async {
                      await ref
                          .read(collectionLinkRepositoryProvider)
                          .setCategory(link.id, cat);
                      if (ctx.mounted) {
                        Navigator.of(ctx, rootNavigator: true).pop();
                      }
                    },
              selected: cat == link.category,
              semanticLabel: cat == link.category
                  ? '${_collection(cat)}, current'
                  : _collection(cat),
              child: Container(
                constraints: const BoxConstraints(minHeight: 48),
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: ExcludeSemantics(
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _collection(cat),
                          style: dmSans(
                            15.5,
                            weight: cat == link.category
                                ? FontWeight.w600
                                : FontWeight.w500,
                            height: 1.25,
                            color: cat == link.category ? c.textMuted : c.text,
                          ),
                        ),
                      ),
                      if (cat == link.category)
                        MoonIcon(
                          MoonIconName.check,
                          size: 16,
                          color: c.textMuted,
                          strokeWidth: 2.2,
                        ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      );
    },
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.moon;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final link = ref
        .watch(collectionLinksProvider)
        .value
        ?.where((l) => l.id == linkId)
        .firstOrNull;
    Widget gutter(Widget child, {double top = 0}) => Padding(
      padding: EdgeInsets.fromLTRB(MoonSpace.gutter, top, MoonSpace.gutter, 0),
      child: child,
    );
    Widget infoRow(String left, String right, {bool first = false}) =>
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: first ? null : Border(top: BorderSide(color: c.line)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(left, style: dmSans(14.5, height: 1.3, color: c.textMuted)),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  right,
                  textAlign: TextAlign.end,
                  style: dmSans(
                    14.5,
                    weight: FontWeight.w500,
                    height: 1.3,
                    color: c.text,
                  ),
                ),
              ),
            ],
          ),
        );

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            CenteredHeader(
              title: 'Saved link',
              onBack: () => context.canPop()
                  ? context.pop()
                  : context.go(Routes.collections),
              trailingIcon: link == null ? null : MoonIconName.more,
              trailingLabel: 'More actions',
              trailingKey: const ValueKey('link-more'),
              onTrailing: link == null ? null : () => _more(context, ref, link),
            ),
            Expanded(
              child: link == null
                  ? Center(
                      child: Text(
                        'This link is no longer here.',
                        style: dmSans(15, color: c.textMuted),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.only(bottom: 40),
                      children: [
                        gutter(
                          Semantics(
                            label: '${_kindLine(link)}, no preview stored',
                            excludeSemantics: true,
                            child: Container(
                              height: 196,
                              decoration: BoxDecoration(
                                color: dark
                                    ? HeroTokens.darkSolid
                                    : HeroTokens.lightWash[Phase.follicular],
                                borderRadius: BorderRadius.circular(26),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 64,
                                    height: 64,
                                    decoration: BoxDecoration(
                                      color: c.raised,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: MoonIcon(
                                        isMediaPlatform(link.platform)
                                            ? MoonIconName.play
                                            : MoonIconName.link,
                                        size: 26,
                                        color: c.text,
                                        strokeWidth: 1.8,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    _kindLine(link),
                                    style: dmSans(
                                      13,
                                      height: 1.3,
                                      color: c.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          top: 12,
                        ),
                        gutter(
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: c.phase(Phase.follicular).tint,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  switch (link.category) {
                                    LinkCategory.recipes => 'Recipe',
                                    LinkCategory.workouts => 'Workout',
                                    LinkCategory.sounds => 'Spa',
                                  },
                                  style: dmSans(
                                    11.5,
                                    weight: FontWeight.w600,
                                    height: 1.2,
                                    color: c.text,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Semantics(
                                header: true,
                                child: Text(
                                  link.title,
                                  style: fraunces(
                                    30,
                                    height: 1.1,
                                    color: c.text,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text.rich(
                                TextSpan(
                                  children: [
                                    if (link.creator != null) ...[
                                      const TextSpan(
                                        text: 'Original creator: ',
                                      ),
                                      TextSpan(
                                        text: link.creator,
                                        style: dmSans(
                                          14.5,
                                          weight: FontWeight.w600,
                                          color: c.text,
                                        ),
                                      ),
                                      TextSpan(text: ' on ${link.source}'),
                                    ] else
                                      TextSpan(text: 'On ${link.source}'),
                                  ],
                                ),
                                style: dmSans(
                                  14.5,
                                  height: 1.4,
                                  color: c.textMuted,
                                ),
                              ),
                            ],
                          ),
                          top: 20,
                        ),
                        gutter(
                          Pressable(
                            key: const ValueKey('link-open'),
                            onTap: () => openLink(context, ref, link.url),
                            semanticLabel: _openLabel(link),
                            child: Container(
                              width: double.infinity,
                              constraints: const BoxConstraints(minHeight: 54),
                              decoration: ShapeDecoration(
                                color: c.inverseBg,
                                shape: const StadiumBorder(),
                              ),
                              child: ExcludeSemantics(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        _openLabel(link),
                                        textAlign: TextAlign.center,
                                        style: dmSans(
                                          15.5,
                                          weight: FontWeight.w600,
                                          height: 1.2,
                                          color: c.inverseText,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    MoonIcon(
                                      MoonIconName.arrowUpRight,
                                      size: 17,
                                      color: c.inverseText,
                                      strokeWidth: 2,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          top: 18,
                        ),
                        gutter(const Overline('My note'), top: 18),
                        gutter(
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: c.raised,
                              border: Border.all(color: c.line),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    link.note ?? 'No note yet.',
                                    key: const ValueKey('link-note'),
                                    style: dmSans(
                                      15,
                                      height: 1.5,
                                      color: link.note == null
                                          ? c.textMuted
                                          : c.text,
                                    ),
                                  ),
                                ),
                                Pressable(
                                  key: const ValueKey('link-edit-note'),
                                  onTap: () => context.push(
                                    Routes.collectionLinkEdit(link.id),
                                  ),
                                  semanticLabel: 'Edit note',
                                  child: SizedBox(
                                    width: 36,
                                    height: 36,
                                    child: Center(
                                      child: MoonIcon(
                                        MoonIconName.pencil,
                                        size: 18,
                                        color: c.textMuted,
                                        strokeWidth: 1.8,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          top: 10,
                        ),
                        gutter(
                          Column(
                            children: [
                              infoRow(
                                'Collection',
                                _collection(link.category),
                                first: true,
                              ),
                              infoRow('Saved', _date(link.createdAt)),
                              infoRow('Address', link.host),
                            ],
                          ),
                          top: 18,
                        ),
                        gutter(
                          Row(
                            children: [
                              Expanded(
                                child: _OutlineButton(
                                  key: const ValueKey('link-edit'),
                                  label: 'Edit',
                                  icon: MoonIconName.pencil,
                                  onTap: () => context.push(
                                    Routes.collectionLinkEdit(link.id),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _OutlineButton(
                                  key: const ValueKey('link-remove'),
                                  label: 'Remove',
                                  icon: MoonIconName.trash,
                                  color: c.destructive,
                                  onTap: () => _remove(context, ref, link),
                                ),
                              ),
                            ],
                          ),
                          top: 18,
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

class _OutlineButton extends StatelessWidget {
  const _OutlineButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.color,
  });

  final String label;
  final MoonIconName icon;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    final fg = color ?? c.text;
    return Pressable(
      onTap: onTap,
      semanticLabel: label,
      child: Container(
        height: 48,
        decoration: ShapeDecoration(
          shape: StadiumBorder(side: BorderSide(color: c.line)),
        ),
        child: ExcludeSemantics(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              MoonIcon(icon, size: 17, color: fg, strokeWidth: 1.8),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  style: dmSans(
                    14.5,
                    weight: FontWeight.w600,
                    height: 1.2,
                    color: fg,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
