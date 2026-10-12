import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/local_date.dart';

/// The clock. Tests override it with a fixed time.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// Today's date on this phone. Updates at local midnight and whenever the app
/// comes back to the foreground, so cycle days never go stale.
final todayProvider = NotifierProvider<Today, LocalDate>(Today.new);

class Today extends Notifier<LocalDate> {
  Timer? _midnight;
  AppLifecycleListener? _lifecycle;

  @override
  LocalDate build() {
    _lifecycle ??= AppLifecycleListener(onResume: _refresh);
    ref.onDispose(() {
      _midnight?.cancel();
      _lifecycle?.dispose();
      _lifecycle = null;
    });
    return _readAndSchedule();
  }

  void _refresh() {
    final next = _readAndSchedule();
    if (next != state) state = next;
  }

  LocalDate _readAndSchedule() {
    final now = ref.read(clockProvider)();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    _midnight?.cancel();
    // A second past midnight, so the new day has certainly begun.
    _midnight = Timer(
      tomorrow.difference(now) + const Duration(seconds: 1),
      _refresh,
    );
    return LocalDate.fromDateTime(now);
  }
}
