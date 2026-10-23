import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/core/time/today.dart';
import 'package:moon_cycle/features/privacy/application/data_export_service.dart';
import 'package:moon_cycle/features/settings/presentation/delete_data_page.dart';

import '../../helpers/golden_screen.dart' show designNow;
import '../../helpers/pump_app.dart';
import '../../helpers/seed.dart';

class _CountingExport extends DataExportService {
  _CountingExport(super.ref);

  int shares = 0;

  @override
  Future<void> share({Rect? origin}) async => shares++;
}

void main() {
  late ProviderContainer container;

  int shares() =>
      (container.read(dataExportServiceProvider) as _CountingExport).shares;

  Future<void> pumpMore(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 1300) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final db = testDatabase();
    await seedCycle(tester, db, start: sampleStart);
    container = await pumpApp(
      tester,
      database: db,
      overrides: [
        clockProvider.overrideWithValue(designNow),
        dataExportServiceProvider.overrideWith(_CountingExport.new),
      ],
    );
    await tester.tap(find.byKey(const ValueKey('tab-more')));
    await tester.pumpAndSettle();
  }

  Future<void> open(WidgetTester tester, String row) async {
    await tester.scrollUntilVisible(
      find.text(row),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text(row));
    await tester.pumpAndSettle();
    await tester.tap(find.text(row));
    await tester.pumpAndSettle();
  }

  testWidgets('Export my data warns first: sensitive writing, not encrypted', (
    tester,
  ) async {
    await pumpMore(tester);
    await open(tester, 'Privacy & Data');
    expect(find.textContaining('diary and Notes'), findsWidgets);
    await tester.tap(find.text('Export my data'));
    await tester.pumpAndSettle();
    expect(find.text('Before you export'), findsOneWidget);
    expect(find.textContaining('sensitive writing'), findsOneWidget);
    expect(find.textContaining('the personal Notes you wrote'), findsOneWidget);
    expect(find.textContaining('not encrypted'), findsOneWidget);
    expect(shares(), 0); // nothing is shared before the choice

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Before you export'), findsNothing);
    expect(shares(), 0);

    await tester.tap(find.text('Export my data'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue to export'));
    await tester.pumpAndSettle();
    expect(shares(), 1);
  });

  testWidgets('Delete my data names the diary and personal Notes; its export '
      'link warns too', (tester) async {
    await pumpMore(tester);
    await open(tester, 'Delete my data');
    expect(find.byType(DeleteDataPage), findsOneWidget);
    expect(
      find.textContaining('diary entries and personal Notes'),
      findsOneWidget,
    );
    await tester.tap(find.text('Export my data first'));
    await tester.pumpAndSettle();
    expect(find.text('Before you export'), findsOneWidget);
    expect(shares(), 0);
  });
}
