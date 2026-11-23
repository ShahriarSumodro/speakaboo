import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speakaboo/main.dart';

void main() {
  testWidgets('App starts and shows Speakaboo title', (WidgetTester tester) async {
    await tester.pumpWidget(const SpeakabooApp());

    // App should show the title
    expect(find.text('Speakaboo'), findsOneWidget);
    expect(find.text('Your English Speaking Companion'), findsOneWidget);
  });

  testWidgets('Shows checking status initially', (WidgetTester tester) async {
    await tester.pumpWidget(const SpeakabooApp());

    // Should show loading indicator initially
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
