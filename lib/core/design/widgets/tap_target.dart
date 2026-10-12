import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// The smallest touch target (spec §10).
const double minTapTarget = 44;

/// Room to add on each side of a control [height] tall (and [width] wide,
/// when given) so its touch target is at least [minTapTarget].
EdgeInsets tapTargetSlop({double? width, required double height}) =>
    EdgeInsets.symmetric(
      horizontal: width == null ? 0 : math.max(0, minTapTarget - width) / 2,
      vertical: math.max(0, minTapTarget - height) / 2,
    );

/// Gives a control a larger touch target than it is drawn, without moving
/// anything around it. [child] is laid out [extra] larger on each side (put
/// the same [extra] as padding inside the child's tap area), but this widget
/// reports the drawn size to its parent.
///
/// For the designed controls under 44 pt: the 40 pt phase selector, 42 pt
/// chips and the 32 pt × on chips.
class ExpandedTapTarget extends SingleChildRenderObjectWidget {
  const ExpandedTapTarget({super.key, required this.extra, super.child});

  /// Added on each side.
  final EdgeInsets extra;

  @override
  RenderExpandedTapTarget createRenderObject(BuildContext context) =>
      RenderExpandedTapTarget(extra);

  @override
  void updateRenderObject(
    BuildContext context,
    RenderExpandedTapTarget renderObject,
  ) => renderObject.extra = extra;
}

/// The render object behind [ExpandedTapTarget].
class RenderExpandedTapTarget extends RenderProxyBox {
  RenderExpandedTapTarget(this._extra);

  EdgeInsets _extra;
  set extra(EdgeInsets value) {
    if (value == _extra) return;
    _extra = value;
    markNeedsLayout();
  }

  Offset get _childOffset => Offset(-_extra.left, -_extra.top);

  @override
  void performLayout() {
    final c = constraints;
    child!.layout(
      BoxConstraints(
        minWidth: c.minWidth + _extra.horizontal,
        maxWidth: c.maxWidth + _extra.horizontal,
        minHeight: c.minHeight + _extra.vertical,
        maxHeight: c.maxHeight + _extra.vertical,
      ),
      parentUsesSize: true,
    );
    size = c.constrain(
      Size(
        child!.size.width - _extra.horizontal,
        child!.size.height - _extra.vertical,
      ),
    );
  }

  @override
  double computeMinIntrinsicWidth(double height) =>
      super.computeMinIntrinsicWidth(height) - _extra.horizontal;

  @override
  double computeMaxIntrinsicWidth(double height) =>
      super.computeMaxIntrinsicWidth(height) - _extra.horizontal;

  @override
  double computeMinIntrinsicHeight(double width) =>
      super.computeMinIntrinsicHeight(width) - _extra.vertical;

  @override
  double computeMaxIntrinsicHeight(double width) =>
      super.computeMaxIntrinsicHeight(width) - _extra.vertical;

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) {
    final d = super.computeDistanceToActualBaseline(baseline);
    return d == null ? null : d - _extra.top;
  }

  @override
  void paint(PaintingContext context, Offset offset) =>
      context.paintChild(child!, offset + _childOffset);

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) =>
      transform.translateByDouble(_childOffset.dx, _childOffset.dy, 0, 1);

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    final area =
        _childOffset &
        Size(size.width + _extra.horizontal, size.height + _extra.vertical);
    if (!area.contains(position)) return false;
    return result.addWithPaintOffset(
      offset: _childOffset,
      position: position,
      hitTest: (result, position) => child!.hitTest(result, position: position),
    );
  }
}
