import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

import 'app/app.dart';
import 'app/config/app_config.dart';
import 'core/database/app_database.dart';
import 'core/database/database_opener.dart';
import 'core/database/encryption_key_store.dart';
import 'features/onboarding/application/onboarding_status.dart';
import 'features/onboarding/data/app_state_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Fails fast if the flavour and env file don't match (see AppConfig).
  final config = AppConfig.fromBuild();

  // SQLite can't find a temporary directory on its own on Android.
  sqlite3.tempDirectory = (await getTemporaryDirectory()).path;
  final database = await openAppDatabase(
    directory: await getApplicationSupportDirectory(),
    keys: EncryptionKeyStore(),
  );
  final onboarded = await AppStateRepository(database).isOnboardingComplete();

  runApp(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(config),
        appDatabaseProvider.overrideWithValue(database),
        initialOnboardingCompletedProvider.overrideWithValue(onboarded),
      ],
      child: const MoonCycleApp(),
    ),
  );
}
