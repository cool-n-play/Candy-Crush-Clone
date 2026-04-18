import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:candy_crush_clone/main.dart';

void main() {
  testWidgets('App loads', (WidgetTester tester) async {
    await tester.pumpWidget(const CandyApp());
    await tester.pump();
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
