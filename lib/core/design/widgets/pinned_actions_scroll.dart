import 'package:flutter/widgets.dart';

/// A page whose [content] starts at the top and whose [actions] sit at the
/// bottom of the screen; when both don't fit (small phones, large text) the
/// whole page scrolls instead of overflowing.
class PinnedActionsScroll extends StatelessWidget {
  const PinnedActionsScroll({
    super.key,
    required this.padding,
    required this.content,
    required this.actions,
    this.minGap = 0,
    this.crossAxisAlignment = CrossAxisAlignment.stretch,
  });

  final EdgeInsets padding;
  final Widget content;
  final Widget actions;

  /// The least space between content and actions.
  final double minGap;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => SingleChildScrollView(
      padding: padding,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: constraints.maxHeight - padding.vertical,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: crossAxisAlignment,
          children: [
            content,
            Padding(
              padding: EdgeInsets.only(top: minGap),
              child: actions,
            ),
          ],
        ),
      ),
    ),
  );
}
