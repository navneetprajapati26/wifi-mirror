// This is a basic Flutter widget test.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wifi_mirror/main.dart';

void main() {
  testWidgets('App loads successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: WifiMirrorApp()));

    // Verify that splash screen or home screen loads
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
