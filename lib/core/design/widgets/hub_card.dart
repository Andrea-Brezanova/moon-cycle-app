import 'package:flutter/material.dart';

import '../../domain/phase.dart';
import '../moon_theme.dart';
import '../tokens/moon_typography.dart';
import 'moon_icon.dart';
import 'pressable.dart';

/// A full-width navigation card used by every hub (Eat, Move, Relax, Me): a
/// tinted icon disc, a serif title, one line, and a chevron. The disc takes the
/// palette of [phase]; pass the phase being viewed so the icons follow it.
class HubCard extends StatelessWidget {
  const HubCard({
    super.key,
    required this.icon,
    required this.phase,
    required this.title,
    this.body,
    required this.onTap,
  });

  final MoonIconName icon;
  final Phase phase;
  final String title;
  final String? body;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    final palette = c.phase(phase);
    return Pressable(
      onTap: onTap,
      semanticLabel: body == null ? title : '$title. $body',
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
                  if (body != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      body!,
                      style: dmSans(14, height: 1.4, color: c.textMuted),
                    ),
                  ],
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
