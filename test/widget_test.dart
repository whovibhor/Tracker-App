// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:finly/main.dart';

void main() {
  setUpAll(() async {
    Hive.init('test');
  });

  tearDownAll(() async {
    await Hive.close();
  });

  testWidgets('App loads without error', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const FinlyApp());

    // Verify that our app loads
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
