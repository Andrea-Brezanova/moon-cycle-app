import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/config/app_links.dart';
import '../../../core/design/moon_theme.dart';
import '../../../core/design/widgets/moon_controls.dart';
import '../../../core/design/widgets/moon_icon.dart';
import '../../../core/design/widgets/moon_list.dart';
import '../../../core/design/widgets/moon_surfaces.dart';
import '../../../core/storage/ui_prefs.dart';
import 'widgets/export_action.dart';
import 'widgets/settings_widgets.dart';

/// Me › Privacy & Data (`31-settings-privacy-data`).
class PrivacyDataPage extends ConsumerWidget {
  const PrivacyDataPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.moon;
    final links = ref.watch(appLinksProvider);
    final prefs = ref.watch(uiPrefsProvider);
    void setShield(bool v) => ref
        .read(uiPrefsProvider.notifier)
        .update(prefs.copyWith(privacyShield: v));

    // TODO(open-question): the policy pages. A row without an address
    // can't be tapped yet.
    MoonListRow link(String label, Uri? uri) => MoonListRow(
      label: label,
      onTap: uri == null
          ? null
          : () => launchUrl(uri, mode: LaunchMode.inAppBrowserView),
    );

    return SettingsSubScaffold(
      backLabel: 'My App',
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
          title: 'On your screen',
          children: [
            GestureDetector(
              // The whole row toggles; the switch carries the screen-reader state.
              behavior: HitTestBehavior.opaque,
              excludeFromSemantics: true,
              onTap: () => setShield(!prefs.privacyShield),
              child: MoonListRow(
                label: 'Hide app in app switcher',
                subtitle: prefs.privacyShield
                    ? 'Moon Cycle shows a blank screen when you switch apps'
                    : 'Moon Cycle’s screens show in the app switcher '
                          '(on Android this also blocks screenshots)',
                trailing: MoonToggle(
                  value: prefs.privacyShield,
                  semanticLabel: 'Hide app in app switcher',
                  onChanged: setShield,
                ),
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
