import 'package:flutter_test/flutter_test.dart';
import 'package:chore_bounty_application/main.dart';

void main() {
  testWidgets('ChoreBounty app launches', (WidgetTester tester) async {
    await tester.pumpWidget(const ChoreBountyApp());

    // Allow the first frame and immediate scheduled updates to render.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(ChoreBountyApp), findsOneWidget);
  });
}
