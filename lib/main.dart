import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

import 'app/app_root.dart';
import 'app/config/app_config.dart';
import 'app/config/app_version.dart';
import 'app/config/build_info.dart';
import 'core/crash/crash_reporting.dart';
import 'core/database/app_database.dart';
import 'core/database/database_opener.dart';
import 'core/database/encryption_key_store.dart';
import 'features/content/application/content_providers.dart';
import 'features/content/data/bundled_catalogue.dart';
import 'features/entitlements/application/entitlement_providers.dart';
import 'features/onboarding/application/onboarding_status.dart';
import 'features/onboarding/data/app_state_repository.dart';
import 'features/preferences/application/preference_providers.dart';
import 'features/preferences/data/preferences_repository.dart';
import 'features/privacy/data/local_data_wiper.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Fails fast if the flavour and env file don't match (see AppConfig).
  final config = AppConfig.fromBuild();

  // SQLite can't find a temporary directory on its own on Android.
  sqlite3.tempDirectory = (await getTemporaryDirectory()).path;
  final directory = await getApplicationSupportDirectory();
  final keys = EncryptionKeyStore();
  final catalogue = await loadBundledCatalogue();
  final package = await PackageInfo.fromPlatform();
  final version = package.version;

  // Opened again after "Delete my data", on a new database and key.
  Future<List<Override>> openSession() async {
    final database = await openAppDatabase(directory: directory, keys: keys);
    final onboarded = await AppStateRepository(database).isOnboardingComplete();
    final appearance = await PreferencesRepository(database).appearance();
    return [
      appDatabaseProvider.overrideWithValue(database),
      initialOnboardingCompletedProvider.overrideWithValue(onboarded),
      initialAppearanceProvider.overrideWithValue(appearance),
    ];
  }

  final session = await openSession();
  await runWithCrashReporting(
    config,
    () => runApp(
      AppRoot(
        overrides: [
          appConfigProvider.overrideWithValue(config),
          // Development: every feature open for testing (debug builds of the
          // dev flavour only; see docs/feature-status.md).
          debugUnlockAtStartProvider.overrideWithValue(
            developmentUnlockEnabled(
                  isDebugBuild: kDebugMode,
                  isDevFlavour: config.flavor == Flavor.dev,
                ) ||
                // The owner's test-phone build (DEV_PREMIUM=true, dev flavour).
                devPremiumBuildAllowed(
                  flavor: config.flavor,
                  define: devPremiumDefine,
                ),
          ),
          catalogueProvider.overrideWithValue(catalogue),
          appVersionProvider.overrideWithValue(version),
          buildInfoProvider.overrideWithValue(
            BuildInfo.fromBuild(
              version: version,
              buildNumber: package.buildNumber,
              flavor: config.flavor,
            ),
          ),
          databaseDirectoryProvider.overrideWithValue(directory),
          encryptionKeyStoreProvider.overrideWithValue(keys),
        ],
        session: session,
        openSession: openSession,
      ),
    ),
  );
}
