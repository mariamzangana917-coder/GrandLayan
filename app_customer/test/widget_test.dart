import 'package:app_customer/app/grand_layan_app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Grand Layan app starts successfully', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: GrandLayanApp()));

    await tester.pump();

    expect(find.text('الجمال يبدأ من هنا'), findsOneWidget);
  });
}
