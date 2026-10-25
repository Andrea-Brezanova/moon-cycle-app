import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/design/moon_theme.dart';
import '../../../../core/design/tokens/moon_typography.dart';
import '../../../../core/design/widgets/moon_icon.dart';
import '../../../../core/design/widgets/pressable.dart';
import '../../domain/collection_link.dart';
import '../open_link.dart';

/// Whether a platform's links are mostly video or audio, for the little play
/// symbol (the app never plays anything; it only opens the original).
bool isMediaPlatform(LinkPlatform p) => switch (p) {
  LinkPlatform.youtube ||
  LinkPlatform.tiktok ||
  LinkPlatform.instagram ||
  LinkPlatform.spotify => true,
  _ => false,
};

/// A group of saved links in one rounded card with hairlines between them, as
/// on the approved My Workouts / My Spa screens.
class CollectionLinkGroup extends StatelessWidget {
  const CollectionLinkGroup({super.key, required this.links});

  final List<CollectionLink> links;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: c.raised,
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          for (final (i, l) in links.indexed) ...[
            if (i > 0) Divider(height: 1, color: c.line),
            CollectionLinkRow(link: l),
          ],
        ],
      ),
    );
  }
}

/// One saved link: a symbol tile, the name, a source badge with the creator,
/// the user's note in italics, and a button that opens the original. Tapping
/// the row opens the details.
class CollectionLinkRow extends ConsumerWidget {
  const CollectionLinkRow({super.key, required this.link});

  final CollectionLink link;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.moon;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Pressable(
              key: ValueKey('row-${link.id}'),
              onTap: () => context.push(Routes.collectionLink(link.id)),
              semanticLabel:
                  '${link.title}, ${link.source}'
                  '${link.creator == null ? '' : ', by ${link.creator}'}. '
                  'Open details',
              child: ExcludeSemantics(
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: c.sand,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: MoonIcon(
                          isMediaPlatform(link.platform)
                              ? MoonIconName.play
                              : MoonIconName.link,
                          size: 22,
                          color: c.text,
                          strokeWidth: 1.7,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            link.title,
                            style: fraunces(17.5, height: 1.15, color: c.text),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 6,
                            runSpacing: 2,
                            children: [
                              SourceBadge(link.source),
                              if (link.creator != null)
                                Text(
                                  link.creator!,
                                  style: dmSans(
                                    12.5,
                                    height: 1.3,
                                    color: c.textMuted,
                                  ),
                                ),
                            ],
                          ),
                          if (link.note != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              '“${link.note}”',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: dmSans(
                                13,
                                height: 1.35,
                                color: c.textMuted,
                              ).copyWith(fontStyle: FontStyle.italic),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Pressable(
            key: ValueKey('open-${link.id}'),
            onTap: () => openLink(context, ref, link.url),
            semanticLabel: 'Open ${link.title} on ${link.source}',
            child: SizedBox(
              width: 44,
              height: 44,
              child: Center(
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: c.line),
                  ),
                  child: Center(
                    child: MoonIcon(
                      MoonIconName.arrowUpRight,
                      size: 16,
                      color: c.text,
                      strokeWidth: 1.9,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A small pill: "YouTube", "Moon Cycle", "Yours".
class SourceBadge extends StatelessWidget {
  const SourceBadge(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: c.sand,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: dmSans(
          11.5,
          weight: FontWeight.w600,
          height: 1.2,
          color: c.text,
        ),
      ),
    );
  }
}
