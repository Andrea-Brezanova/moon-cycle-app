import 'package:flutter_test/flutter_test.dart';
import 'package:moon_cycle/features/credits/presentation/credits_page.dart';

import '../../helpers/golden_screen.dart';

void main() {
  testWidgets('Credits says that some illustrations were generated using AI', (
    tester,
  ) async {
    await pumpScreen(tester, const CreditsPage(), dark: false, height: 2400);
    await tester.pumpAndSettle();
    expect(find.text('ILLUSTRATIONS'), findsOneWidget);
    expect(find.text(CreditsPage.aiDisclosure), findsOneWidget);
    expect(CreditsPage.aiDisclosure, contains('generated using AI'));
    // The photograph credits are still there.
    expect(find.textContaining('Unsplash'), findsWidgets);
  });
}
