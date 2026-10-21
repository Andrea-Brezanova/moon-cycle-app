import 'package:flutter/material.dart';

import '../../../core/design/moon_theme.dart';
import '../../../core/design/tokens/moon_typography.dart';
import '../../../core/design/widgets/pressable.dart';

/// A short confirmation at the top of the screen ("Added to your diary · View"),
/// gone after a few seconds. Used where a form closes back onto another page.
void showDiaryToast(
  BuildContext context,
  String message, {
  String? actionLabel,
  VoidCallback? onAction,
}) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;
  late final OverlayEntry entry;
  var gone = false;
  void remove() {
    if (gone) return;
    gone = true;
    entry.remove();
  }

  entry = OverlayEntry(
    builder: (ctx) {
      final c = ctx.moon;
      return Positioned(
        left: 16,
        right: 16,
        // At the top, so it never covers the entry that was just saved.
        top: MediaQuery.paddingOf(ctx).top + 8,
        child: Semantics(
          liveRegion: true,
          container: true,
          child: Material(
            color: const Color(0x00000000),
            child: Container(
              constraints: const BoxConstraints(minHeight: 52),
              padding: const EdgeInsets.only(left: 18, right: 6),
              decoration: BoxDecoration(
                color: c.inverseBg,
                borderRadius: BorderRadius.circular(26),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x3D1B152E),
                    blurRadius: 24,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      message,
                      style: dmSans(
                        15,
                        weight: FontWeight.w600,
                        height: 1.3,
                        color: c.inverseText,
                      ),
                    ),
                  ),
                  if (actionLabel != null)
                    Pressable(
                      onTap: () {
                        remove();
                        onAction?.call();
                      },
                      semanticLabel: actionLabel,
                      child: Container(
                        constraints: const BoxConstraints(
                          minHeight: 44,
                          minWidth: 56,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        alignment: Alignment.center,
                        child: Text(
                          actionLabel,
                          style: dmSans(
                            15,
                            weight: FontWeight.w700,
                            height: 1,
                            color: c.ochre,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
  overlay.insert(entry);
  Future<void>.delayed(const Duration(seconds: 3), remove);
}
