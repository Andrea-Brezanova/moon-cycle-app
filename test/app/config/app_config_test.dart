import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/app/config/app_config.dart';

void main() {
  group('AppConfig.resolve', () {
    test('dev flavour with the dev env file', () {
      final config = AppConfig.resolve(flavorName: 'dev', envName: 'dev');
      expect(config.flavor, Flavor.dev);
      expect(config.appName, 'Moon Cycle Dev');
      expect(config.isProduction, isFalse);
    });

    test('prod flavour with the prod env file', () {
      final config = AppConfig.resolve(flavorName: 'prod', envName: 'prod');
      expect(config.flavor, Flavor.prod);
      expect(config.appName, 'Moon Cycle');
      expect(config.isProduction, isTrue);
    });

    test('passes the Sentry DSN through', () {
      final config = AppConfig.resolve(
        flavorName: 'dev',
        envName: 'dev',
        sentryDsn: 'https://example.invalid/1',
      );
      expect(config.sentryDsn, 'https://example.invalid/1');
    });

    test('fails without a flavour', () {
      expect(
        () => AppConfig.resolve(flavorName: null, envName: 'dev'),
        throwsStateError,
      );
      expect(
        () => AppConfig.resolve(flavorName: '', envName: 'dev'),
        throwsStateError,
      );
    });

    test('fails for a flavour v1 does not have', () {
      expect(
        () => AppConfig.resolve(flavorName: 'stg', envName: 'stg'),
        throwsStateError,
      );
    });

    test('fails when the env file belongs to another flavour', () {
      expect(
        () => AppConfig.resolve(flavorName: 'prod', envName: 'dev'),
        throwsStateError,
      );
      expect(
        () => AppConfig.resolve(flavorName: 'dev', envName: ''),
        throwsStateError,
      );
    });
  });
}
