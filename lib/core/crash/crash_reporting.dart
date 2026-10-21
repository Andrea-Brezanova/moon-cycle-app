import 'dart:async';

import 'package:sentry_flutter/sentry_flutter.dart';

import '../../app/config/app_config.dart';

/// Runs [app] with crash reporting when this build has a Sentry DSN
/// (`env/<flavour>.json` › `SENTRY_DSN`); without one, it just runs [app].
///
/// Reports carry no personal or cycle data (spec §12, plan §12): no user,
/// no breadcrumbs (routes name recipes and settings), no screenshots, no performance tracing, and dates in messages are masked.
Future<void> runWithCrashReporting(
  AppConfig config,
  FutureOr<void> Function() app,
) async {
  if (config.sentryDsn.isEmpty) {
    await app();
    return;
  }
  await SentryFlutter.init((options) {
    options
      ..dsn = config.sentryDsn
      ..environment = config.flavor.name
      ..sendDefaultPii = false
      ..attachScreenshot = false
      ..enableUserInteractionBreadcrumbs = false
      ..enableAutoPerformanceTracing = false
      ..tracesSampleRate = 0
      ..beforeBreadcrumb = dropBreadcrumb
      ..beforeSend = scrubEvent;
  }, appRunner: app);
}

/// Breadcrumbs are never sent.
Breadcrumb? dropBreadcrumb(Breadcrumb? breadcrumb, Hint hint) => null;

final _date = RegExp(r'\d{4}-\d{2}-\d{2}');

/// Removes anything that could identify the user or describe their cycle.
FutureOr<SentryEvent?> scrubEvent(SentryEvent event, Hint hint) {
  event
    ..user = null
    ..breadcrumbs = []
    ..request = null;
  for (final e in event.exceptions ?? const <SentryException>[]) {
    e.value = maskDates(e.value);
  }
  final message = event.message;
  if (message != null) message.formatted = maskDates(message.formatted)!;
  return event;
}

/// "is after today (2026-10-12)" → "is after today ([date])".
String? maskDates(String? text) => text?.replaceAll(_date, '[date]');
