import 'package:flutter_test/flutter_test.dart';
import 'package:finmate/app/app.dart';

void main() {
  testWidgets('FinMate smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const FinMateApp());
    expect(find.text('FinMate'), findsOneWidget);
  });
}
