import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;

import '../core/design/tokens/moon_colors.dart';
import 'app.dart';

/// Opens the user's data (the database and what depends on it) and returns
/// the provider overrides for it.
typedef OpenSession = Future<List<Override>> Function();

/// Restarts the app on fresh data: stops every provider, runs [whileStopped]
/// (e.g. deleting the database), then opens the data again and starts from
/// the first screen. Used by "Delete my data".
typedef RestartApp = Future<void> Function(
  Future<void> Function() whileStopped,
);

final appRestartProvider = Provider<RestartApp>(
  (ref) => throw UnimplementedError('appRestartProvider is set by AppRoot'),
);

/// Holds the [ProviderScope]. Restarting replaces it with a new one, so no
/// state from before the restart (or the old database) survives.
class AppRoot extends StatefulWidget {
  const AppRoot({
    super.key,
    required this.overrides,
    required this.session,
    required this.openSession,
  });

  /// Overrides that never change (config, catalogue).
  final List<Override> overrides;

  /// The overrides from the first [openSession], opened before `runApp`.
  final List<Override> session;
  final OpenSession openSession;

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  late List<Override>? _session = widget.session;
  int _generation = 0;

  Future<void> _restart(Future<void> Function() whileStopped) async {
    setState(() => _session = null);
    // Let the old scope dispose its providers (and their database streams).
    await WidgetsBinding.instance.endOfFrame;
    try {
      await whileStopped();
    } finally {
      // Even if a step failed, open whatever data is there rather than
      // leaving a blank screen.
      await _reopen();
    }
  }

  Future<void> _reopen() async {
    final session = await widget.openSession();
    if (!mounted) return;
    setState(() {
      _session = session;
      _generation++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = _session;
    if (session == null) {
      // The splash colour, for the moment the data is reopened.
      final dark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;
      return ColoredBox(color: dark ? MoonColors.dark.bg : MoonColors.light.bg);
    }
    return ProviderScope(
      key: ValueKey(_generation),
      overrides: [
        ...widget.overrides,
        ...session,
        appRestartProvider.overrideWithValue(_restart),
      ],
      child: const MoonCycleApp(),
    );
  }
}
