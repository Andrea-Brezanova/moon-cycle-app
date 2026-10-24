import 'package:flutter/widgets.dart';

/// Photos are dimmed a little (brightness about 0.94) in dark mode.
class DimmedPhoto extends StatelessWidget {
  const DimmedPhoto({super.key, required this.dim, required this.child});

  final bool dim;
  final Widget child;

  @override
  Widget build(BuildContext context) => dim
      ? ColorFiltered(
          colorFilter: const ColorFilter.matrix([
            0.94, 0, 0, 0, 0, //
            0, 0.94, 0, 0, 0,
            0, 0, 0.94, 0, 0,
            0, 0, 0, 1, 0,
          ]),
          child: child,
        )
      : child;
}
