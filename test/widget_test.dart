import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mindlink/main.dart';

void main() {
  testWidgets('App starts and shows start button', (WidgetTester tester) async {
    await tester.pumpWidget(const MindLinkApp());

    expect(find.text('시작'), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
  });
}
