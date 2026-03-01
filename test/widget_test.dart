// Smoke tests — Phase 2 Foundation
// Verifies model parsing and basic UI rendering without requiring a live Supabase connection.
// Integration tests (auth flow, real DB queries) require supabase start and are added in Phase 10.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:puzzle_game/data/models/player_profile.dart';
import 'package:puzzle_game/features/auth/screens/sign_up_screen.dart';
import 'package:puzzle_game/features/auth/screens/sign_in_screen.dart';

void main() {
  // ─────────────────────────────────────────
  // Unit tests — pure Dart, no external deps
  // ─────────────────────────────────────────

  group('PlayerProfile', () {
    test('parses from JSON with display_name', () {
      final profile = PlayerProfile.fromJson({
        'id': '11111111-1111-1111-1111-111111111111',
        'auth_id': '22222222-2222-2222-2222-222222222222',
        'display_name': 'Alice',
        'is_guest': false,
        'current_streak': 5,
        'longest_streak': 10,
        'total_words_found': 42,
        'created_at': '2026-01-01T00:00:00.000Z',
      });

      expect(profile.id, '11111111-1111-1111-1111-111111111111');
      expect(profile.authId, '22222222-2222-2222-2222-222222222222');
      expect(profile.isGuest, false);
      expect(profile.currentStreak, 5);
      expect(profile.totalWordsFound, 42);
      expect(profile.welcomeName, 'Alice');
    });

    test('uses Guest as welcomeName when display_name is null', () {
      final profile = PlayerProfile.fromJson({
        'id': '11111111-1111-1111-1111-111111111111',
        'auth_id': '22222222-2222-2222-2222-222222222222',
        'display_name': null,
        'is_guest': true,
        'current_streak': 0,
        'longest_streak': 0,
        'total_words_found': 0,
        'created_at': '2026-01-01T00:00:00.000Z',
      });

      expect(profile.isGuest, true);
      expect(profile.welcomeName, 'Guest');
    });

    test('defaults numeric fields to 0 when absent', () {
      final profile = PlayerProfile.fromJson({
        'id': 'a',
        'auth_id': 'b',
        'display_name': null,
        'created_at': '2026-01-01T00:00:00.000Z',
      });

      expect(profile.currentStreak, 0);
      expect(profile.longestStreak, 0);
      expect(profile.totalWordsFound, 0);
      expect(profile.isGuest, true);
    });
  });

  // ─────────────────────────────────────────
  // Widget smoke tests — no Supabase required
  // ─────────────────────────────────────────

  testWidgets('SignUpScreen renders email and password fields',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: SignUpScreen()),
      ),
    );
    // Form fields must be present
    expect(find.byType(TextFormField), findsNWidgets(2));
    // Submit button visible
    expect(find.widgetWithText(FilledButton, 'Create Account'), findsOneWidget);
    // Sign-in link visible
    expect(find.text('Already have an account? Sign in'), findsOneWidget);
  });

  testWidgets('SignInScreen renders email and password fields',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: SignInScreen()),
      ),
    );
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.widgetWithText(FilledButton, 'Sign In'), findsOneWidget);
    expect(find.text("Don't have an account? Create one"), findsOneWidget);
  });
}
