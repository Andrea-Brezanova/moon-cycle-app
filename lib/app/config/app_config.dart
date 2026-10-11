import 'package:flutter/services.dart' show appFlavor;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The v1 flavours. Staging is added with Supabase in v1.1.
enum Flavor { dev, prod }

/// Build-time settings that differ per flavour.
///
/// They come from two places:
/// - the flavour, chosen with `--flavor` (Flutter exposes it as [appFlavor]);
/// - `--dart-define-from-file=env/<flavour>.json` for per-environment values.
///
/// Run with, for example:
/// `flutter run --flavor dev --dart-define-from-file=env/dev.json`
class AppConfig {
  const AppConfig({required this.flavor, this.sentryDsn = ''});

  /// Reads the values compiled into this build.
  factory AppConfig.fromBuild() => AppConfig.resolve(
    flavorName: appFlavor,
    envName: const String.fromEnvironment('APP_ENV'),
    sentryDsn: const String.fromEnvironment('SENTRY_DSN'),
  );

  /// Checks that the flavour and the env file agree, so a dev env file can
  /// never end up inside a production build (or the other way round).
  factory AppConfig.resolve({
    required String? flavorName,
    required String envName,
    String sentryDsn = '',
  }) {
    if (flavorName == null || flavorName.isEmpty) {
      throw StateError(
        'No flavour set. Run with --flavor dev or --flavor prod '
        '(see README).',
      );
    }
    final flavor = Flavor.values.where((f) => f.name == flavorName).firstOrNull;
    if (flavor == null) {
      throw StateError('Unknown flavour "$flavorName". v1 has dev and prod.');
    }
    if (envName != flavor.name) {
      throw StateError(
        'Flavour "${flavor.name}" was built with the env file for '
        '"$envName". Use --dart-define-from-file=env/${flavor.name}.json.',
      );
    }
    return AppConfig(flavor: flavor, sentryDsn: sentryDsn);
  }

  final Flavor flavor;

  /// Empty until crash reporting is added (Milestone 15).
  final String sentryDsn;

  bool get isProduction => flavor == Flavor.prod;

  String get appName => switch (flavor) {
    Flavor.dev => 'Moon Cycle Dev',
    Flavor.prod => 'Moon Cycle',
  };
}

/// The build's [AppConfig]. It is resolved once in `main()` and passed in as
/// an override; tests override it with the flavour they need.
final appConfigProvider = Provider<AppConfig>(
  (ref) => throw UnimplementedError('appConfigProvider is set in main()'),
);
