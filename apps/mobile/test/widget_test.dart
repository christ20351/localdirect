import 'package:flutter_test/flutter_test.dart';
import 'package:locadirect_mobile/main.dart';

void main() {
  testWidgets('LocaDirectApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const LocaDirectApp());
    expect(find.text('LocaDirect CM'), findsNothing); // smoke test placeholder
  });
}
