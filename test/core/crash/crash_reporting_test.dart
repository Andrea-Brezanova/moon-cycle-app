import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/app/config/app_config.dart';
import 'package:moon_cycle/core/crash/crash_reporting.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

void main() {
  test('without a DSN the app runs without crash reporting', () async {
    var ran = false;
    await runWithCrashReporting(
      const AppConfig(flavor: Flavor.dev),
      () => ran = true,
    );
    expect(ran, isTrue);
    expect(Sentry.isEnabled, isFalse);
  });

  test('breadcrumbs are never sent', () {
    expect(dropBreadcrumb(Breadcrumb(message: '/recipes/x'), Hint()), isNull);
  });

  test('events lose the user, breadcrumbs and dates', () async {
    final event = SentryEvent(
      user: SentryUser(id: 'device-1', email: 'a@b.c'),
      breadcrumbs: [Breadcrumb(message: 'opened My Cycle')],
      message: SentryMessage('Logged 2026-10-05'),
      exceptions: [
        SentryException(
          type: 'ArgumentError',
          value: 'lastPeriodStart is after today (2026-10-12)',
        ),
      ],
    );
    final scrubbed = (await scrubEvent(event, Hint()))!;
    expect(scrubbed.user, isNull);
    expect(scrubbed.breadcrumbs, isEmpty);
    expect(scrubbed.message?.formatted, 'Logged [date]');
    expect(
      scrubbed.exceptions!.single.value,
      'lastPeriodStart is after today ([date])',
    );
  });
}
