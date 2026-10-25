import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_config.dart';

/// What this installed build is, shown under Me › Settings › About so it is
/// always clear which source is on the phone.
///
/// The commit and the build date are never typed in: `tool/build_ios.sh` passes
/// them to the compiler (`--dart-define=GIT_SHA=…`, `BUILD_DATE=…`) from the
/// checkout it builds, with "-dirty" added to the commit if the working tree had
/// uncommitted changes. A build made without them says "unknown".
final class BuildInfo {
  const BuildInfo({
    required this.version,
    required this.buildNumber,
    required this.commit,
    required this.builtAt,
    required this.flavor,
  });

  /// Reads the values compiled into this build, plus the platform's version.
  factory BuildInfo.fromBuild({
    required String version,
    required String buildNumber,
    required Flavor flavor,
  }) => BuildInfo(
    version: version,
    buildNumber: buildNumber,
    commit: const String.fromEnvironment('GIT_SHA', defaultValue: 'unknown'),
    builtAt: DateTime.tryParse(const String.fromEnvironment('BUILD_DATE')),
    flavor: flavor,
  );

  /// "0.1.0".
  final String version;

  /// "1".
  final String buildNumber;

  /// The short Git commit the app was built from ("a3dd5e3", or
  /// "a3dd5e3-dirty", or "unknown").
  final String commit;

  /// When it was built (UTC), or null if not recorded.
  final DateTime? builtAt;
  final Flavor flavor;

  String get versionLine =>
      buildNumber.isEmpty ? version : '$version ($buildNumber)';

  String get flavorLabel => switch (flavor) {
    Flavor.dev => 'Development',
    Flavor.prod => 'Production',
  };

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  /// "25 Oct 2026, 20:15 UTC", or "Unknown".
  String get builtLine {
    final t = builtAt?.toUtc();
    if (t == null) return 'Unknown';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${t.day} ${_months[t.month - 1]} ${t.year}, '
        '${two(t.hour)}:${two(t.minute)} UTC';
  }
}

/// Set in `main()`; tests override it.
final buildInfoProvider = Provider<BuildInfo>(
  (ref) => BuildInfo(
    version: '',
    buildNumber: '',
    commit: 'unknown',
    builtAt: null,
    flavor: ref.watch(appConfigProvider).flavor,
  ),
);
