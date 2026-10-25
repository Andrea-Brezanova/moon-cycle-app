@Tags(['golden'])
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/app/config/app_config.dart';
import 'package:moon_cycle/app/config/app_version.dart';
import 'package:moon_cycle/core/domain/local_date.dart';
import 'package:moon_cycle/features/cycle/application/cycle_providers.dart';
import 'package:moon_cycle/features/cycle/domain/cycle_profile.dart';
import 'package:moon_cycle/features/cycle/domain/period_log.dart';
import 'package:moon_cycle/features/preferences/application/preference_providers.dart';
import 'package:moon_cycle/features/preferences/domain/diet.dart';
import 'package:moon_cycle/features/preferences/domain/food_avoidance.dart';
import 'package:moon_cycle/features/preferences/domain/reminder_settings.dart';
import 'package:moon_cycle/features/settings/presentation/account_plus_page.dart';
import 'package:moon_cycle/features/settings/presentation/allergies_page.dart';
import 'package:moon_cycle/features/settings/presentation/delete_data_page.dart';
import 'package:moon_cycle/features/settings/presentation/food_preferences_page.dart';
import 'package:moon_cycle/features/settings/presentation/help_page.dart';
import 'package:moon_cycle/features/settings/presentation/my_cycle_page.dart';
import 'package:moon_cycle/features/settings/presentation/notifications_page.dart';
import 'package:moon_cycle/features/settings/presentation/privacy_data_page.dart';
import 'package:moon_cycle/features/settings/presentation/settings_home_page.dart';
import 'package:moon_cycle/features/settings/presentation/settings_hub_page.dart';
import 'package:moon_cycle/features/settings/presentation/subscription_page.dart';

import '../../helpers/golden_screen.dart';
import '../../helpers/moon_fonts.dart';
import 'home_golden_test.dart' show stateOnDay;

PeriodLog _log(String id, LocalDate start, int days) => PeriodLog(
  id: id,
  start: start,
  end: start.addDays(days - 1),
  source: PeriodLogSource.manual,
);

/// The history drawn in `26-settings-my-cycle`, newest first.
final _history = [
  _log('d', LocalDate(2025, 9, 28), 5),
  _log('c', LocalDate(2025, 8, 31), 5),
  _log('b', LocalDate(2025, 8, 3), 6),
  _log('a', LocalDate(2025, 7, 6), 5),
];

/// The values drawn across the Settings screens.
final List<Override> _sample = [
  appConfigProvider.overrideWithValue(const AppConfig(flavor: Flavor.prod)),
  appVersionProvider.overrideWithValue('1.0'),
  cycleStateProvider.overrideWithValue(stateOnDay(7)),
  cycleProfileProvider.overrideWithValue(
    const AsyncData(
      CycleProfile(typicalCycleLength: 28, typicalPeriodLength: 5),
    ),
  ),
  periodLogsProvider.overrideWithValue(AsyncData(_history)),
  dietProvider.overrideWithValue(const AsyncData(Diet.omnivore)),
  avoidancesProvider.overrideWithValue(
    const AsyncData([
      AllergenAvoidance(id: '1', allergenId: 'peanut'),
      AllergenAvoidance(id: '2', allergenId: 'shellfish'),
      FoodItemAvoidance(id: '3', foodId: 'mushrooms'),
    ]),
  ),
  reminderSettingsProvider.overrideWithValue(
    const AsyncData(ReminderSettings(enabled: true)),
  ),
];

void main() {
  setUpAll(loadMoonFonts);

  final screens = <String, (Widget, double)>{
    'settings': (const SettingsHomePage(), 1100),
    'settings-hub': (const SettingsHubPage(), 844),
    'account-plus': (const AccountPlusPage(), 600),
    'my-cycle': (const MyCyclePage(), 1100),
    'food-preferences': (const FoodPreferencesSettingsPage(), 844),
    'allergies': (const AllergiesPage(), 844),
    'notifications': (const NotificationsPage(), 844),
    'subscription': (const SubscriptionPage(), 844),
    'privacy': (const PrivacyDataPage(), 844),
    'help': (const HelpPage(), 844),
    'delete-data': (const DeleteDataPage(), 844),
  };

  for (final MapEntry(key: theme, value: dark) in themes.entries) {
    for (final MapEntry(key: name, value: (screen, height))
        in screens.entries) {
      testWidgets('$name, $theme', (tester) async {
        await pumpScreen(
          tester,
          screen,
          dark: dark,
          height: height,
          overrides: _sample,
        );
        await expectLater(
          find.byWidget(screen),
          matchesGoldenFile('goldens/$theme-settings-$name.png'),
        );
      });
    }
  }
}
