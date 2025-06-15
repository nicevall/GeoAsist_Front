import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:geo_asist_front/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const GeoAssistApp());

    // Verify that login screen elements are present
    expect(find.text('WELCO'), findsOneWidget);
    expect(find.text('ME'), findsOneWidget);
    expect(find.text('GEO ASISTENCIA'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Register'), findsOneWidget);
  });
}
