import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../tokens/moon_colors.dart';
import 'moon_icon.dart';

/// The three organic shapes from `design/assets/shapes` (onboarding welcome
/// and the recipe placeholder only; spec §5). Stretched to fill their box.
class OrganicShape extends StatelessWidget {
  const OrganicShape({
    super.key,
    required this.variant,
    required this.color,
    this.width = 200,
    this.height = 200,
    this.opacity = 1,
  }) : assert(variant >= 0 && variant < 3);

  /// 0, 1 or 2 (organic-1, organic-2, organic-3).
  final int variant;
  final Color color;
  final double width;
  final double height;
  final double opacity;

  static const _paths = [
    'M54.6,-63.1C69.4,-51.6,79,-33.1,81.5,-13.9C84,5.3,79.4,25.3,67.7,40.2C56,55.1,37.1,64.9,17.1,70.6C-2.9,76.3,-24,77.9,-41.4,69.8C-58.8,61.7,-72.5,43.9,-77.9,24.2C-83.3,4.5,-80.4,-17.1,-69.8,-33.8C-59.2,-50.5,-40.9,-62.3,-22.4,-72.4C-3.9,-82.5,14.8,-90.9,30.9,-85.6C47,-80.3,39.8,-74.6,54.6,-63.1Z',
    'M47.1,-56.4C60.4,-44.6,70.1,-29.2,73.5,-12.1C76.9,5,74,23.8,64.1,37.6C54.2,51.4,37.3,60.2,19.4,66.4C1.5,72.6,-17.4,76.2,-34.2,70.4C-51,64.6,-65.7,49.4,-72.4,31.5C-79.1,13.6,-77.8,-7,-69.9,-23.8C-62,-40.6,-47.5,-53.6,-31.8,-64.6C-16.1,-75.6,0.8,-84.6,16.3,-81.6C31.8,-78.6,33.8,-68.2,47.1,-56.4Z',
    'M38.7,-49.2C51.5,-37.5,63.7,-25.6,68.1,-10.8C72.5,4,69.1,21.7,59.1,34.6C49.1,47.5,32.5,55.6,15.3,61.5C-1.9,67.4,-19.7,71.1,-34.6,65.1C-49.5,59.1,-61.5,43.4,-68.6,25.7C-75.7,8,-77.9,-11.7,-70.4,-26.9C-62.9,-42.1,-45.7,-52.8,-29.5,-63.4C-13.3,-74,-0.1,-84.5,11.9,-81.8C23.9,-79.1,25.9,-60.9,38.7,-49.2Z',
  ];

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Opacity(
      opacity: opacity,
      child: SvgPicture.string(
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="-100 -100 200 200" '
        'preserveAspectRatio="none"><path d="${_paths[variant]}" '
        'fill="currentColor"/></svg>',
        width: width,
        height: height,
        fit: BoxFit.fill,
        theme: SvgTheme(currentColor: color),
      ),
    ),
  );
}

/// A recipe photo with rounded corners, or the tinted placeholder when there
/// is no photo (spec §6).
class RecipePhoto extends StatelessWidget {
  const RecipePhoto({
    super.key,
    required this.height,
    required this.radius,
    required this.palette,
    this.image,
  });

  final double height;
  final double radius;

  /// The recipe's phase colours, for the placeholder.
  final PhasePalette palette;
  final ImageProvider? image;

  @override
  Widget build(BuildContext context) {
    final shape = BorderRadius.circular(radius);
    if (image != null) {
      return ClipRRect(
        borderRadius: shape,
        child: Image(
          image: image!,
          height: height,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      );
    }
    return Semantics(
      label: 'Recipe photo placeholder',
      child: ClipRRect(
        borderRadius: shape,
        child: Container(
          height: height,
          width: double.infinity,
          color: palette.tint,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                right: -30,
                bottom: -40,
                child: OrganicShape(
                  variant: 1,
                  color: palette.accent,
                  width: 160,
                  height: 150,
                  opacity: 0.22,
                ),
              ),
              MoonIcon(
                MoonIconName.recipes,
                size: 40,
                color: palette.text,
                strokeWidth: 1.2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
