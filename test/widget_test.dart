// Basic smoke test for Career Matrix.
//
// This verifies the app boots without throwing and that the splash screen
// (the app's initial route) renders its branding. It intentionally avoids
// pumping past the splash screen's async auto-login check, since that talks
// to SharedPreferences and would need plugin mocking to run in a pure
// widget-test environment — see the flutter_test docs on
// `SharedPreferences.setMockInitialValues` if you extend this suite.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:career_matrix/main.dart';

void main() {
  testWidgets('Career Matrix boots and shows splash branding', (WidgetTester tester) async {
    await tester.pumpWidget(const CareerMatrixApp());

    // Let the splash screen's entrance animation start (but not finish —
    // avoid triggering its post-delay navigation/async session check).
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Career Matrix'), findsOneWidget);
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
