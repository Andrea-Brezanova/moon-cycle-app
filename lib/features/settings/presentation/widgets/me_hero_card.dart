import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/design/moon_theme.dart';
import '../../../../core/design/tokens/moon_typography.dart';
import '../../../../core/design/widgets/hub_hero.dart';
import '../../../../core/design/widgets/moon_icon.dart';
import '../../../../core/design/widgets/moon_surfaces.dart';
import '../../../../core/design/widgets/pressable.dart';
import '../../application/me_hero.dart';

/// The picture at the top of Me, in the same card as the Eat, Move and Relax
/// heroes (same width, 1.86 aspect, 24 pt radius). A small button changes it:
/// a MoonCycle picture, a photo from the library, a new photo with the camera,
/// or back to the default. The image is only cropped to fit, never stretched.
class MeHeroCard extends ConsumerWidget {
  const MeHeroCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.moon;
    final image = ref.watch(meHeroImageProvider);
    return Container(
      key: const ValueKey('me-hero'),
      decoration: BoxDecoration(
        color: c.raised,
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(24),
      ),
      clipBehavior: Clip.antiAlias,
      child: AspectRatio(
        aspectRatio: HubHero.aspectRatio,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Decorative: the page title says what the page is.
            ExcludeSemantics(
              child: Image(
                key: const ValueKey('me-hero-image'),
                image: image,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.medium,
                errorBuilder: (_, _, _) => ColoredBox(color: c.sand),
              ),
            ),
            Positioned(
              right: 8,
              bottom: 8,
              child: Pressable(
                key: const ValueKey('me-hero-edit'),
                onTap: () => showMeHeroSheet(context, ref),
                semanticLabel: 'Change your Me picture',
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: Center(
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: c.raised.withValues(alpha: 0.92),
                        shape: BoxShape.circle,
                        border: Border.all(color: c.line),
                      ),
                      child: Center(
                        child: MoonIcon(
                          MoonIconName.pencil,
                          size: 18,
                          color: c.text,
                          strokeWidth: 1.8,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The "Your picture" sheet.
Future<void> showMeHeroSheet(BuildContext context, WidgetRef ref) =>
    showMoonSheet<void>(
      context,
      builder: (sheetContext) => _HeroSheet(parent: context, ref: ref),
    );

class _HeroSheet extends StatelessWidget {
  const _HeroSheet({required this.parent, required this.ref});

  final BuildContext parent;
  final WidgetRef ref;

  Future<void> _pick(BuildContext sheetContext, HeroPickSource source) async {
    Navigator.pop(sheetContext);
    try {
      final bytes = await ref.read(heroImagePickerProvider).pick(source);
      if (bytes != null) await ref.read(meHeroActionsProvider).useBytes(bytes);
    } on HeroPermissionDenied catch (d) {
      if (parent.mounted) await _explainDenied(parent, d.source);
    } on Object {
      if (parent.mounted) await _explainFailed(parent);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    final customised = ref.watch(meHeroCustomisedProvider);
    Widget option(
      String key,
      String label,
      MoonIconName icon,
      VoidCallback f,
    ) => Pressable(
      key: ValueKey(key),
      onTap: f,
      semanticLabel: label,
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: c.line)),
        ),
        child: Row(
          children: [
            MoonIcon(icon, size: 22, color: c.text, strokeWidth: 1.6),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: dmSans(16, weight: FontWeight.w500, color: c.text),
              ),
            ),
          ],
        ),
      ),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text('Your picture', style: fraunces(26, color: c.text)),
        ),
        const SizedBox(height: 4),
        Text(
          'Shown at the top of Me. It stays on this phone.',
          style: dmSans(14, height: 1.4, color: c.textMuted),
        ),
        const SizedBox(height: 10),
        option(
          'hero-bundled',
          'Choose a MoonCycle picture',
          MoonIconName.apple,
          () {
            Navigator.pop(context);
            showMoonSheet<void>(
              parent,
              builder: (_) => _BundledPicker(ref: ref),
            );
          },
        ),
        option(
          'hero-gallery',
          'Choose from your photos',
          MoonIconName.document,
          () => _pick(context, HeroPickSource.gallery),
        ),
        option(
          'hero-camera',
          'Take a photo',
          MoonIconName.play,
          () => _pick(context, HeroPickSource.camera),
        ),
        if (customised)
          option(
            'hero-restore',
            'Restore the default picture',
            MoonIconName.back,
            () {
              Navigator.pop(context);
              ref.read(meHeroActionsProvider).restoreDefault();
            },
          ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _BundledPicker extends StatelessWidget {
  const _BundledPicker({required this.ref});

  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text('MoonCycle pictures', style: fraunces(26, color: c.text)),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final h in bundledHeroes)
              Pressable(
                key: ValueKey('bundled-${h.id}'),
                onTap: () {
                  Navigator.pop(context);
                  ref.read(meHeroActionsProvider).useBundled(h.id);
                },
                semanticLabel: h.label,
                child: SizedBox(
                  width: 100,
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: AspectRatio(
                          aspectRatio: 1.3,
                          child: ExcludeSemantics(
                            child: Image.asset(h.asset, fit: BoxFit.cover),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        h.label,
                        textAlign: TextAlign.center,
                        style: dmSans(12.5, color: c.text),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

Future<void> _explainDenied(BuildContext context, HeroPickSource source) {
  final what = source == HeroPickSource.camera ? 'the camera' : 'your photos';
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      key: const ValueKey('hero-denied'),
      title: Text('MoonCycle can’t use $what'),
      content: const Text(
        'You can allow it in Settings › MoonCycle, or choose a MoonCycle '
        'picture instead. Nothing was changed.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Not now'),
        ),
        TextButton(
          key: const ValueKey('hero-open-settings'),
          onPressed: () {
            Navigator.pop(context);
            launchUrl(Uri.parse('app-settings:'));
          },
          child: const Text('Open Settings'),
        ),
      ],
    ),
  );
}

Future<void> _explainFailed(BuildContext context) => showDialog<void>(
  context: context,
  builder: (context) => AlertDialog(
    key: const ValueKey('hero-failed'),
    title: const Text('That picture couldn’t be used'),
    content: const Text('Nothing was changed. Please try another one.'),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('OK'),
      ),
    ],
  ),
);
