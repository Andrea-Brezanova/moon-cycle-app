import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../core/design/moon_theme.dart';
import '../../../core/design/tokens/moon_layout.dart';
import '../../../core/design/tokens/moon_typography.dart';
import '../../../core/design/widgets/centered_header.dart';
import '../../../core/design/widgets/moon_button.dart';
import '../../collections/application/collections_providers.dart';
import '../../collections/data/collection_link_repository.dart';
import '../../collections/domain/collection_link.dart';
import '../application/hub_providers.dart';
import 'hub_library_page.dart';

/// One approved library item: what it is, what you need, the steps, the
/// safety note, and where it comes from. An item with a verified link can be
/// opened and saved to My Workouts or My Spa.
class HubItemPage extends ConsumerWidget {
  const HubItemPage({super.key, required this.itemId});

  final String itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.moon;
    final item = ref.watch(hubItemProvider(itemId));
    final tab = item == null ? AppTab.move : hubTabOf(item.kind);
    Widget body;
    if (item == null) {
      body = Text(
        'This item is no longer available.',
        style: MoonType.body.copyWith(color: c.text),
      );
    } else {
      final saved = [
        for (final l
            in ref.watch(collectionLinksProvider).value ??
                const <CollectionLink>[])
          l.url.toString(),
      ].contains(item.sourceUrl?.toString());
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              item.title,
              style: fraunces(30, height: 1.12, color: c.text),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            [
              if (item.durationMinutes != null) '${item.durationMinutes} min',
              if (item.intensity != null) item.intensity!,
              if (item.category != null) item.category!,
            ].join(' · '),
            style: dmSans(14, height: 1.4, color: c.textMuted),
          ),
          const SizedBox(height: 14),
          Text(item.summary, style: MoonType.body.copyWith(color: c.text)),
          if (item.equipment.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text(
              'You will need: ${item.equipment.join(', ')}',
              style: dmSans(15, height: 1.45, color: c.text),
            ),
          ],
          if (item.steps.isNotEmpty) ...[
            const SizedBox(height: 18),
            for (final (i, s) in item.steps.indexed)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  '${i + 1}. $s',
                  style: MoonType.body.copyWith(color: c.text),
                ),
              ),
          ],
          if (item.safetyNote != null) ...[
            const SizedBox(height: 10),
            Container(
              key: const ValueKey('hub-safety-note'),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: c.sand,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                item.safetyNote!,
                style: dmSans(14, height: 1.45, color: c.text),
              ),
            ),
          ],
          if (item.sourceName != null || item.creator != null) ...[
            const SizedBox(height: 14),
            Text(
              [
                if (item.sourceName != null) 'Source: ${item.sourceName}',
                if (item.creator != null) 'By ${item.creator}',
              ].join(' · '),
              style: dmSans(13, height: 1.4, color: c.textMuted),
            ),
          ],
          if (item.sourceUrl != null) ...[
            const SizedBox(height: 20),
            MoonButton(
              'Open the original',
              onPressed: () => ref.read(linkLauncherProvider)(item.sourceUrl!),
            ),
            const SizedBox(height: 10),
            MoonButton(
              key: const ValueKey('hub-save'),
              saved
                  ? 'Saved'
                  : (item.kind.isMovement
                        ? 'Save to My Workouts'
                        : 'Save to My Spa'),
              variant: MoonButtonVariant.ghost,
              onPressed: saved
                  ? null
                  : () => ref
                        .read(collectionLinkRepositoryProvider)
                        .add(
                          category: hubLinkCategory(item.kind),
                          address: item.sourceUrl.toString(),
                          title: item.title,
                          creator: item.creator ?? item.sourceName,
                        ),
            ),
          ],
        ],
      );
    }
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            CenteredHeader(
              title: '',
              onBack: () =>
                  context.canPop() ? context.pop() : context.go(tab.path),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  MoonSpace.gutter,
                  8,
                  MoonSpace.gutter,
                  40,
                ),
                children: [body],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
