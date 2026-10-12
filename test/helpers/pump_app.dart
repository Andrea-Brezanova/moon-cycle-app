import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/app/app.dart';
import 'package:moon_cycle/app/config/app_config.dart';
import 'package:moon_cycle/features/onboarding/application/onboarding_status.dart';

class _OnboardingStatus extends OnboardingStatus {
  _OnboardingStatus(this.initial);

  final bool initial;

  @override
  bool build() => initial;
}

/// Pumps the whole app (dev flavour) and returns its provider container.
Future<ProviderContainer> pumpApp(
  WidgetTester tester, {
  bool onboarded = true,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(
          const AppConfig(flavor: Flavor.dev),
        ),
        onboardingCompletedProvider.overrideWith(
          () => _OnboardingStatus(onboarded),
        ),
      ],
      child: const MoonCycleApp(),
    ),
  );
  await tester.pumpAndSettle();
  return ProviderScope.containerOf(tester.element(find.byType(MoonCycleApp)));
}
