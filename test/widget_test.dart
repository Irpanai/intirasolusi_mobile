// This is a basic Flutter widget test.

import 'package:flutter_test/flutter_test.dart';

import 'package:intirasolusi_mobile/app.dart';

void main() {
  testWidgets('App should build', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const IntiraApp());

    // Verify that app builds without throwing
    expect(find.byType(IntiraApp), findsOneWidget);
    
    // Pump and settle to handle pending timers (e.g., splash screen delay)
    await tester.pumpAndSettle(const Duration(seconds: 5));
  });
}
