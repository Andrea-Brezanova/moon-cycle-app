import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../core/design/moon_theme.dart';
import '../../../core/design/tokens/moon_typography.dart';
import '../../../core/design/widgets/month_calendar.dart';
import '../../../core/design/widgets/moon_button.dart';
import '../../../core/design/widgets/text_link.dart';
import '../../../core/domain/local_date.dart';
import '../../../core/format/dates.dart';
import '../../../core/time/today.dart';
import '../application/onboarding_controller.dart';
import 'widgets/onboarding_step.dart';

/// Onboarding step 2 (`02-onboarding-last-period`).
class LastPeriodPage extends ConsumerStatefulWidget {
  const LastPeriodPage({super.key});

  @override
  ConsumerState<LastPeriodPage> createState() => _LastPeriodPageState();
}

class _LastPeriodPageState extends ConsumerState<LastPeriodPage> {
  /// The month shown: the chosen date's month, or this month.
  LocalDate? _month;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    final today = ref.watch(todayProvider);
    final answers = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);
    final start = answers.lastPeriodStart;
    final month = _month ?? start ?? today;

    return OnboardingStep(
      step: 1,
      overline: 'Your cycle',
      question: 'When did your last period *start?*',
      helper:
          'This sets your cycle day. You can change it anytime in Settings.',
      content: [
        MonthCalendar(
          year: month.year,
          month: month.month,
          today: today,
          selected: start,
          highlighted: answers.predictedPeriodDays(),
          onSelect: controller.selectStart,
          onMonthChanged: (first) => setState(() => _month = first),
        ),
        if (start != null)
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: c.text,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Day 1 · ${DateText.weekdayDayMonth(start)}',
                  style: dmSans(
                    14,
                    weight: FontWeight.w500,
                    height: 1.5,
                    color: c.textMuted,
                  ),
                ),
              ),
            ],
          ),
      ],
      actions: [
        MoonButton(
          'Continue',
          variant: MoonButtonVariant.secondary,
          onPressed: answers.lastPeriodValid(today)
              ? () => context.push(Routes.onboardingCycleLength)
              : null,
        ),
        const SizedBox(height: 12),
        Center(
          child: TextLink.onboarding(
            'I’m not sure',
            onTap: () {
              controller.notSure();
              context.push(Routes.onboardingCycleLength);
            },
          ),
        ),
      ],
    );
  }
}
