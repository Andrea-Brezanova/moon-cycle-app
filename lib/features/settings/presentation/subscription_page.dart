import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/moon_theme.dart';
import '../../../core/design/tokens/moon_typography.dart';
import '../../../core/design/widgets/editorial_text.dart';
import '../../entitlements/application/entitlement_providers.dart';
import '../../entitlements/domain/entitlements.dart';
import '../application/settings_copy.dart';
import 'widgets/settings_widgets.dart';

/// Settings › Subscription (`30-settings-subscription`). v1 has no purchase
/// controls: everything is free until the launch-free end date.
class SubscriptionPage extends ConsumerWidget {
  const SubscriptionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.moon;
    final state = ref.watch(entitlementStateProvider);
    final grant = state.grant;
    final promo = grant?.origin == EntitlementOrigin.launchPromo;
    // TODO(open-question): the launch-free end date. Until it's set, the
    // designed placeholder shows.
    final until = grant?.endsOn == null
        ? '[launch-free end date]'
        : longDate(grant!.endsOn!);

    return SettingsSubScaffold(
      backLabel: 'Me',
      title: 'Subscription',
      top: 22,
      gap: 26,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Overline('Your plan'),
            const SizedBox(height: 12),
            EditorialHeading(switch (state.tier) {
              Tier.free => 'Moon Cycle',
              Tier.plus => 'Moon Cycle *Plus*',
              Tier.premium => 'Moon Cycle *Premium*',
            }, style: fraunces(36, height: 1.08)),
            if (promo) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: ShapeDecoration(
                  color: c.sand,
                  shape: const StadiumBorder(),
                ),
                child: Text(
                  'Free at launch · until $until',
                  style: dmSans(
                    13,
                    weight: FontWeight.w600,
                    height: 1.2,
                    color: c.text,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Everything in Moon Cycle is free until $until. You don’t '
                'need to do anything, and nothing will be charged.',
                style: dmSans(16, height: 1.55, color: c.text),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
