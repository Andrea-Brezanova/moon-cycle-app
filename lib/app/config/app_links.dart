import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/domain/local_date.dart';

/// Addresses and dates the business still has to provide. Each one shows its
/// designed placeholder (or a disabled control) until it is set; they are
/// tracked in docs/open-questions.md and must be filled in before release.
class AppLinks {
  const AppLinks({
    this.privacyPolicy,
    this.terms,
    this.dataUse,
    this.supportEmail,
    this.launchFreeEndDate,
  });

  /// The values for this build.
  // TODO(open-question): policy URLs, support address, launch-free end date.
  static const AppLinks current = AppLinks();

  final Uri? privacyPolicy;
  final Uri? terms;

  /// "How Moon Cycle uses data".
  final Uri? dataUse;
  final String? supportEmail;

  /// The one fixed date the launch promo ends for everyone (spec §12).
  final LocalDate? launchFreeEndDate;
}

final appLinksProvider = Provider<AppLinks>((ref) => AppLinks.current);
