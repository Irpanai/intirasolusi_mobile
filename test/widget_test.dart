// This is a basic Flutter widget test.

import 'package:flutter_test/flutter_test.dart';

import 'package:intirasolusi_app/app.dart';

void main() {
  testWidgets('App should build', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const IntiraApp());

    // Verify that app builds without throwing
    expect(find.byType(IntiraApp), findsOneWidget);
    
    // Pump to render first frame without waiting infinitely for background animation/video
    await tester.pump(const Duration(milliseconds: 100));
  });
}
