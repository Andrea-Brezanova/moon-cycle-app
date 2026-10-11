import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/design/moon_theme.dart';
import 'package:moon_cycle/core/design/tokens/moon_colors.dart';
import 'package:moon_cycle/core/design/widgets/editorial_text.dart';
import 'package:moon_cycle/core/design/widgets/month_calendar.dart';
import 'package:moon_cycle/core/design/widgets/moon_button.dart';
import 'package:moon_cycle/core/design/widgets/moon_chip.dart';
import 'package:moon_cycle/core/design/widgets/moon_controls.dart';
import 'package:moon_cycle/core/design/widgets/moon_icon.dart';
import 'package:moon_cycle/core/design/widgets/number_stepper.dart';
import 'package:moon_cycle/core/design/widgets/phase_selector.dart';
import 'package:moon_cycle/core/design/widgets/text_link.dart';
import 'package:moon_cycle/core/domain/local_date.dart';
import 'package:moon_cycle/core/domain/phase.dart';

Future<void> pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: moonTheme(Brightness.light),
      home: Scaffold(
        body: Center(
          child: Padding(padding: const EdgeInsets.all(24), child: child),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('buttons call back, and not when disabled', (tester) async {
    var taps = 0;
    await pump(
      tester,
      Column(
        children: [
          MoonButton('Continue', onPressed: () => taps++),
          const MoonButton('Disabled', onPressed: null),
        ],
      ),
    );
    await tester.tap(find.text('Continue'));
    await tester.tap(find.text('Disabled'));
    expect(taps, 1);
  });

  testWidgets('text link calls back', (tester) async {
    var taps = 0;
    await pump(tester, TextLink('All foods', onTap: () => taps++));
    await tester.tap(find.text('All foods'));
    expect(taps, 1);
  });

  testWidgets('phase selector reports the tapped phase', (tester) async {
    Phase? chosen;
    await pump(
      tester,
      PhaseSelector(selected: Phase.follicular, onChanged: (p) => chosen = p),
    );
    await tester.tap(find.text('Luteal'));
    expect(chosen, Phase.luteal);
  });

  testWidgets('chip states and taps', (tester) async {
    var taps = 0;
    await pump(
      tester,
      Wrap(
        children: [
          MoonChip('Barley', onTap: () => taps++),
          MoonChip(
            'Broccoli',
            onTap: () {},
            state: MoonChipState.onList,
            palette: MoonColors.light.phase(Phase.follicular),
          ),
        ],
      ),
    );
    await tester.tap(find.text('Barley'));
    expect(taps, 1);
    expect(
      tester.getSemantics(find.text('Broccoli')),
      isSemantics(isSelected: true),
    );
  });

  testWidgets('checkbox and toggle report the new value', (tester) async {
    bool? box;
    bool? toggle;
    await pump(
      tester,
      Row(
        children: [
          RoundCheckbox(
            checked: false,
            onChanged: (v) => box = v,
            semanticLabel: 'Avocado',
          ),
          MoonToggle(
            value: true,
            onChanged: (v) => toggle = v,
            semanticLabel: 'Reminders',
          ),
        ],
      ),
    );
    await tester.tap(find.bySemanticsLabel('Avocado'));
    await tester.tap(find.bySemanticsLabel('Reminders'));
    expect(box, isTrue);
    expect(toggle, isFalse);
  });

  testWidgets('stepper stops at its limits', (tester) async {
    final values = <int>[];
    await pump(
      tester,
      NumberStepper(
        label: 'Cycle length',
        value: 45,
        min: 21,
        max: 45,
        onChanged: values.add,
      ),
    );
    await tester.tap(find.bySemanticsLabel('Increase cycle length'));
    await tester.tap(find.bySemanticsLabel('Decrease cycle length'));
    expect(values, [44]);
  });

  testWidgets('calendar: past days select, future days do not', (tester) async {
    final picked = <LocalDate>[];
    final months = <LocalDate>[];
    await pump(
      tester,
      MonthCalendar(
        year: 2025,
        month: 10,
        today: LocalDate(2025, 10, 4),
        onSelect: picked.add,
        onMonthChanged: months.add,
      ),
    );
    expect(find.text('October 2025'), findsOneWidget);
    await tester.tap(find.text('2'));
    await tester.tap(find.text('20')); // in the future
    await tester.tap(find.bySemanticsLabel('Next month')); // not allowed
    await tester.tap(find.bySemanticsLabel('Previous month'));
    expect(picked, [LocalDate(2025, 10, 2)]);
    expect(months, [LocalDate(2025, 9, 1)]);
  });

  testWidgets('calendar starts weeks on Monday', (tester) async {
    await pump(
      tester,
      MonthCalendar(
        year: 2025,
        month: 9, // 1 September 2025 is a Monday
        today: LocalDate(2025, 10, 4),
        onSelect: (_) {},
        onMonthChanged: (_) {},
      ),
    );
    final mondayHeader = tester.getCenter(find.text('M'));
    final firstDay = tester.getCenter(find.text('1'));
    expect(firstDay.dx, closeTo(mondayHeader.dx, 0.5));
  });

  testWidgets('editorial heading sets *words* in italic', (tester) async {
    await pump(
      tester,
      const EditorialHeading(
        'Fresh, light and *energising*',
        style: TextStyle(fontSize: 30),
      ),
    );
    final rich = tester.widget<Text>(find.byType(Text)).textSpan! as TextSpan;
    final parts = rich.children!.cast<TextSpan>();
    expect(parts.map((p) => p.text), ['Fresh, light and ', 'energising']);
    expect(parts.last.style!.fontStyle, FontStyle.italic);
  });

  group('long labels at large text sizes', () {
    // The largest text size the app allows (1.5×) on the narrowest
    // supported screen (320 pt).
    Future<void> pumpNarrow(WidgetTester tester, Widget child) async {
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: moonTheme(Brightness.light),
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 900),
              textScaler: TextScaler.linear(1.5),
            ),
            child: Scaffold(
              body: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Center(child: child),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    RenderParagraph paragraph(WidgetTester tester, String text) =>
        tester.renderObject<RenderParagraph>(find.text(text));

    const label = 'Add ingredients to shopping list';

    testWidgets('a button wraps its label and grows; nothing is cut', (
      tester,
    ) async {
      await pumpNarrow(
        tester,
        MoonButton(label, onPressed: () {}, trailingIcon: MoonIconName.arrow),
      );
      expect(tester.takeException(), isNull);
      expect(paragraph(tester, label).didExceedMaxLines, isFalse);
      const oneLine = 16 * 1.5 * 1.25;
      expect(tester.getSize(find.text(label)).height, greaterThan(oneLine));
      expect(tester.getSize(find.byType(MoonButton)).height, greaterThan(56));
    });

    testWidgets('a hugging button wraps too', (tester) async {
      await pumpNarrow(
        tester,
        Wrap(
          children: [
            MoonButton(
              'I’m not sure about the date of my last period',
              onPressed: () {},
              variant: MoonButtonVariant.ghost,
              expand: false,
            ),
          ],
        ),
      );
      expect(tester.takeException(), isNull);
      expect(
        paragraph(
          tester,
          'I’m not sure about the date of my last period',
        ).didExceedMaxLines,
        isFalse,
      );
    });

    testWidgets('the confirmed button wraps too', (tester) async {
      await pumpNarrow(
        tester,
        const MoonDoneButton(
          'Added to shopping list',
          checkColor: Color(0xFF3D6E5B),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(
        paragraph(tester, 'Added to shopping list').didExceedMaxLines,
        isFalse,
      );
    });

    testWidgets('chips may still truncate: they are compact controls', (
      tester,
    ) async {
      const long = 'Lettuce (Bibb, Boston, romaine) and other leafy greens';
      await pumpNarrow(tester, Wrap(children: [MoonChip(long, onTap: () {})]));
      expect(tester.takeException(), isNull);
      expect(paragraph(tester, long).didExceedMaxLines, isTrue);
    });
  });

  testWidgets('a one-line button keeps the designed 56 pt height', (
    tester,
  ) async {
    await pump(tester, MoonButton('Continue', onPressed: () {}));
    expect(tester.getSize(find.byType(MoonButton)).height, 56);
  });

  testWidgets('link underlines: ochre 2 pt; onboarding thin, text colour', (
    tester,
  ) async {
    await pump(
      tester,
      Column(
        children: [
          TextLink('All foods', onTap: () {}),
          TextLink.onboarding('I’m not sure', onTap: () {}),
        ],
      ),
    );
    UnderlinePainter painterFor(String text) =>
        tester
                .widget<CustomPaint>(
                  find
                      .ancestor(
                        of: find.text(text),
                        matching: find.byType(CustomPaint),
                      )
                      .first,
                )
                .foregroundPainter!
            as UnderlinePainter;

    final editorial = painterFor('All foods');
    expect(editorial.thickness, 2);
    expect(editorial.color, MoonColors.light.ochre);
    expect(editorial.style.fontWeight, FontWeight.w600);

    final onboarding = painterFor('I’m not sure');
    expect(onboarding.thickness, 1);
    expect(onboarding.color, MoonColors.light.text);
    expect(onboarding.style.fontWeight, FontWeight.w500);
  });
}
