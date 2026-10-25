import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/design/moon_theme.dart';
import '../../../../core/design/tokens/moon_typography.dart';
import '../../../../core/design/widgets/moon_icon.dart';
import '../../../../core/design/widgets/pressable.dart';
import '../../../../core/design/widgets/tap_target.dart';
import '../../domain/collection_link.dart';
import '../open_link.dart';

/// A saved link: its name, where it is from and who made it. Tapping opens the
/// original in the browser or app; the pencil edits it (and can delete it).
class CollectionLinkCard extends ConsumerWidget {
  const CollectionLinkCard({super.key, required this.link});

  final CollectionLink link;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.moon;
    final by = link.creator == null ? '' : ' · ${link.creator}';
    return Container(
      decoration: BoxDecoration(
        color: c.raised,
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Expanded(
            child: Pressable(
              key: ValueKey('open-${link.id}'),
              onTap: () => openLink(context, ref, link.url),
              semanticLabel:
                  'Open ${link.title} on ${link.source}${link.creator == null ? '' : ', by ${link.creator}'}',
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 4, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      link.title,
                      style: fraunces(18, height: 1.2, color: c.text),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${link.source}$by',
                      style: dmSans(12.5, height: 1.4, color: c.textMuted),
                    ),
                    if (link.note != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        link.note!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: dmSans(14, height: 1.4, color: c.text),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          Pressable(
            key: ValueKey('edit-${link.id}'),
            onTap: () => context.push(Routes.collectionLink(link.id)),
            semanticLabel: 'Edit ${link.title}',
            child: SizedBox(
              width: minTapTarget + 4,
              height: minTapTarget + 4,
              child: Center(
                child: MoonIcon(
                  MoonIconName.pencil,
                  size: 19,
                  color: c.textMuted,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
