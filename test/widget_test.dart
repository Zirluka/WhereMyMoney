import 'package:flutter_test/flutter_test.dart';
import 'package:where_my_money/main.dart';

void main() {
  testWidgets('App initialization check smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const WhereMyMoneyApp());
    expect(find.text('WhereMyMoney'), findsOneWidget);
  });
}
