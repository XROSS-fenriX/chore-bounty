import 'package:flutter_test/flutter_test.dart';
import 'package:chore_bounty_application/main.dart';

void main() {
  testWidgets('ChoreBounty app launches', (WidgetTester tester) async {
    await tester.pumpWidget(const ChoreBountyApp());

    // Allow the initial session check to finish.
    await tester.pumpAndSettle();

    expect(find.text('ChoreBounty'), findsOneWidget);
    expect(find.text('Welcome back!'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
  });
}
