import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/design/moon_theme.dart';
import '../features/preferences/application/preference_providers.dart';
import '../features/preferences/domain/appearance.dart';
import '../features/reminders/application/reminder_providers.dart';
import 'config/app_config.dart';
import 'router/app_router.dart';

/// The root widget: the router, and the Editorial themes (light and dark;
/// Settings › Appearance picks the system's, light or dark).
class MoonCycleApp extends ConsumerWidget {
  const MoonCycleApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider);
    // Keeps scheduled reminders up to date for as long as the app runs.
    ref.watch(reminderSyncProvider);
    return MaterialApp.router(
      title: config.appName,
      debugShowCheckedModeBanner: !config.isProduction,
      theme: moonTheme(Brightness.light),
      darkTheme: moonTheme(Brightness.dark),
      themeMode: switch (ref.watch(appearanceProvider)) {
        AppearanceMode.system => ThemeMode.system,
        AppearanceMode.light => ThemeMode.light,
        AppearanceMode.dark => ThemeMode.dark,
      },
      routerConfig: ref.watch(appRouterProvider),
      // Status bar icons follow the theme (plum screens set their own), and
      // body text grows with the system setting up to 1.5× (headings 1.3×).
      builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: moonStatusBar(Theme.of(context).brightness),
        child: MediaQuery.withClampedTextScaling(
          maxScaleFactor: 1.5,
          child: child!,
        ),
      ),
    );
  }
}
