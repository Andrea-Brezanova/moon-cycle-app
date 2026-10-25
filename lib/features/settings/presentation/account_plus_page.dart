import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../core/design/widgets/moon_icon.dart';
import '../../../core/design/widgets/moon_list.dart';
import 'widgets/settings_widgets.dart';

/// Me › Account & Plus: the subscription and Privacy & Data. (Delete my data
/// stays at the bottom of Me.)
class AccountPlusPage extends ConsumerWidget {
  const AccountPlusPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SettingsSubScaffold(
      title: 'Account & Plus',
      backLabel: 'Me',
      children: [
        MoonListGroup(
          children: [
            MoonListRow(
              label: SettingsPage.subscription.title,
              icon: MoonIconName.card,
              subtitle: 'Free at launch',
              onTap: () =>
                  context.push(Routes.settings(SettingsPage.subscription)),
            ),
            MoonListRow(
              label: SettingsPage.privacy.title,
              icon: MoonIconName.lock,
              onTap: () => context.push(Routes.settings(SettingsPage.privacy)),
            ),
          ],
        ),
      ],
    );
  }
}
