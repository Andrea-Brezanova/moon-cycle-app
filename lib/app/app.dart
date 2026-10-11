import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config/app_config.dart';

/// The root widget.
///
/// Milestone 1 only: a neutral placeholder that proves the flavour and config
/// wiring. The Editorial design system arrives in Milestone 3 and the
/// five-tab shell in Milestone 4; neither is represented here.
class MoonCycleApp extends ConsumerWidget {
  const MoonCycleApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider);
    return MaterialApp(
      title: config.appName,
      debugShowCheckedModeBanner: !config.isProduction,
      home: _PlaceholderPage(config: config),
    );
  }
}

class _PlaceholderPage extends StatelessWidget {
  const _PlaceholderPage({required this.config});

  final AppConfig config;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Moon Cycle'),
            const SizedBox(height: 8),
            Text('Flavour: ${config.flavor.name}'),
          ],
        ),
      ),
    );
  }
}
