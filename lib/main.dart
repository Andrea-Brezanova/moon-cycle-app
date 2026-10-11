import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/config/app_config.dart';

void main() {
  // Fails fast if the flavour and env file don't match (see AppConfig).
  final config = AppConfig.fromBuild();
  runApp(
    ProviderScope(
      overrides: [appConfigProvider.overrideWithValue(config)],
      child: const MoonCycleApp(),
    ),
  );
}
