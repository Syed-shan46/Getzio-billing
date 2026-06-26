// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:getzio_billing/main.dart';

void main() {
  testWidgets('App loads placeholder screen test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: GetzioBillingApp()));

    // Wait for router to settle
    await tester.pumpAndSettle();

    // Verify that the Phone Login placeholder screen appears.
    expect(find.text('Phone Login Screen\nComing Soon'), findsOneWidget);
  });
}
