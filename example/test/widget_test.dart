import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:text_stroke_order_example/main.dart';

void main() {
  testWidgets('renders example app', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Plugin example app'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Reset'), findsOneWidget);
  });
}
