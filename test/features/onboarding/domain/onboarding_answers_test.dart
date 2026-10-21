import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/domain/local_date.dart';
import 'package:moon_cycle/features/onboarding/domain/onboarding_answers.dart';

void main() {
  final today = LocalDate(2025, 10, 4);

  test('defaults: no date yet, 28 and 5', () {
    const a = OnboardingAnswers();
    expect(a.lastPeriodStart, isNull);
    expect(a.cycleLength, 28);
    expect(a.periodLength, 5);
    expect(a.lastPeriodValid(today), isFalse);
  });

  test('a start today or earlier is valid; a future one is not', () {
    const a = OnboardingAnswers();
    expect(a.copyWith(lastPeriodStart: today).lastPeriodValid(today), isTrue);
    expect(
      a.copyWith(lastPeriodStart: today.addDays(-120)).lastPeriodValid(today),
      isTrue,
    );
    expect(
      a.copyWith(lastPeriodStart: today.addDays(1)).lastPeriodValid(today),
      isFalse,
    );
  });

  test('lengths stay within the limits', () {
    const a = OnboardingAnswers();
    expect(a.copyWith(cycleLength: 50).cycleLength, 45);
    expect(a.copyWith(cycleLength: 10).cycleLength, 21);
    expect(a.copyWith(periodLength: 1).periodLength, 2);
    expect(a.copyWith(periodLength: 12).periodLength, 10);
  });

  test('the predicted period days follow the start', () {
    final a = OnboardingAnswers(lastPeriodStart: LocalDate(2025, 9, 28));
    expect(a.predictedPeriodDays(), {
      LocalDate(2025, 9, 29),
      LocalDate(2025, 9, 30),
      LocalDate(2025, 10, 1),
      LocalDate(2025, 10, 2),
    });
  });
}
