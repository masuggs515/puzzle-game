// Smoke test — verifies the hello-world screen builds without throwing.
// Full test suites are added per-spec as each phase lands.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:puzzle_game/features/home/screens/home_screen.dart';

void main() {
  testWidgets('HomeScreen builds without error', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: HomeScreen()),
      ),
    );
    // Phase 1 hello-world screen must render the app name
    expect(find.text('Puzzle Game'), findsOneWidget);
    expect(find.text('Hello World'), findsOneWidget);
  });
}
