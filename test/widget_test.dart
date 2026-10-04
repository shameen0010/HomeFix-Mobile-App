import 'package:flutter_test/flutter_test.dart';

import 'package:homefix_app/main.dart';

void main() {
  testWidgets('HomeFix starts on the splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const HomeFixApp());

    expect(find.text('HomeFix'), findsOneWidget);
  });
}
