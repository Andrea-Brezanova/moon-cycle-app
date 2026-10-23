import 'package:flutter/widgets.dart';

/// A delicate leafy sprig drawn in vectors (decorative; there is no
/// illustration asset yet). Used by Today's Focus on Home and the My Diary hub.
class SprigPainter extends CustomPainter {
  SprigPainter({required this.leaf, required this.stem});

  final Color leaf;
  final Color stem;

  @override
  void paint(Canvas canvas, Size size) {
    final stemPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round
      ..color = stem;
    final fill = Paint()..color = leaf.withValues(alpha: 0.28);
    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = stem;
    final w = size.width, h = size.height;
    final path = Path()
      ..moveTo(w * 0.35, h)
      ..quadraticBezierTo(w * 0.55, h * 0.55, w * 0.7, 0);
    canvas.drawPath(path, stemPaint);
    for (var i = 0; i < 5; i++) {
      final t = 0.18 + i * 0.17;
      final y = h * (1 - t);
      final x = w * (0.35 + 0.35 * t * 0.95);
      for (final dir in [-1.0, 1.0]) {
        final len = w * (0.36 - i * 0.03);
        final tip = Offset(x + dir * len, y - h * 0.05);
        final leafPath = Path()
          ..moveTo(x, y)
          ..quadraticBezierTo(x + dir * len * 0.5, y - h * 0.07, tip.dx, tip.dy)
          ..quadraticBezierTo(x + dir * len * 0.5, y + h * 0.015, x, y);
        canvas.drawPath(leafPath, fill);
        canvas.drawPath(leafPath, edge);
      }
    }
  }

  @override
  bool shouldRepaint(SprigPainter old) => old.leaf != leaf || old.stem != stem;
}
