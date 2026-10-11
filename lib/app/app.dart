import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/design/debug/component_gallery.dart';
import '../core/design/moon_theme.dart';
import '../core/design/tokens/moon_typography.dart';
import '../core/design/widgets/text_link.dart';
import 'config/app_config.dart';

/// The root widget: Editorial themes, light and dark following the system.
///
/// The home screen is still a placeholder; the five-tab shell arrives in
/// Milestone 4.
class MoonCycleApp extends ConsumerWidget {
  const MoonCycleApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider);
    return MaterialApp(
      title: config.appName,
      debugShowCheckedModeBanner: !config.isProduction,
      theme: moonTheme(Brightness.light),
      darkTheme: moonTheme(Brightness.dark),
      themeMode: ThemeMode.system,
      // Body text grows with the system setting up to 1.5× (headings 1.3×).
      builder: (context, child) =>
          MediaQuery.withClampedTextScaling(maxScaleFactor: 1.5, child: child!),
      home: _PlaceholderPage(config: config),
    );
  }
}

class _PlaceholderPage extends StatelessWidget {
  const _PlaceholderPage({required this.config});

  final AppConfig config;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Moon Cycle', style: MoonType.body.copyWith(color: c.text)),
            const SizedBox(height: 8),
            Text(
              'Flavour: ${config.flavor.name}',
              style: MoonType.body.copyWith(color: c.textMuted),
            ),
            if (kDebugMode) ...[
              const SizedBox(height: 24),
              TextLink(
                'Component gallery',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ComponentGallery(
                      initialDark:
                          Theme.of(context).brightness == Brightness.dark,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
