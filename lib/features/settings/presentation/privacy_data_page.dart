import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/config/app_links.dart';
import '../../../app/router/routes.dart';
import '../../../core/design/moon_theme.dart';
import '../../../core/design/widgets/moon_icon.dart';
import '../../../core/design/widgets/moon_list.dart';
import '../../../core/design/widgets/moon_surfaces.dart';
import 'widgets/export_action.dart';
import 'widgets/settings_widgets.dart';

/// Me › Privacy & Data (`31-settings-privacy-data`).
class PrivacyDataPage extends ConsumerWidget {
  const PrivacyDataPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.moon;
    final links = ref.watch(appLinksProvider);

    // TODO(open-question): the policy pages. A row without an address
    // can't be tapped yet.
    MoonListRow link(String label, Uri? uri) => MoonListRow(
      label: label,
      onTap: uri == null
          ? null
          : () => launchUrl(uri, mode: LaunchMode.inAppBrowserView),
    );

    return SettingsSubScaffold(
      backLabel: 'Me',
      title: 'Privacy & Data',
      gap: 30,
      children: [
        InfoNote(
          icon: MoonIconName.lock,
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Your data lives on this phone.',
                style: TextStyle(color: c.text, fontWeight: FontWeight.w600),
              ),
              const TextSpan(
                text:
                    ' Cycle dates, food preferences, your shopping list, '
                    'diary, activities, personal Notes and saved links are '
                    'stored only here, encrypted. Nothing is sent to a server.',
              ),
            ],
          ),
        ),
        MoonListGroup(
          title: 'Your data',
          children: [
            Builder(
              builder: (context) => MoonListRow(
                label: 'Export my data',
                subtitle:
                    'A file with your cycle history, preferences, diary, '
                    'activities, Notes and saved links',
                onTap: () => exportMyData(context, ref),
              ),
            ),
          ],
        ),
        MoonListGroup(
          title: 'Delete',
          children: [
            Builder(
              builder: (context) => MoonListRow(
                key: const ValueKey('privacy-delete-data'),
                label: 'Delete my data',
                subtitle:
                    'Permanently removes your cycle history, preferences and '
                    'list from this phone',
                labelColor: c.destructive,
                onTap: () =>
                    context.push(Routes.settings(SettingsPage.deleteData)),
              ),
            ),
          ],
        ),
        MoonListGroup(
          title: 'Policies',
          children: [
            link('Privacy policy', links.privacyPolicy),
            link('Terms of use', links.terms),
            link('How Moon Cycle uses data', links.dataUse),
          ],
        ),
      ],
    );
  }
}
