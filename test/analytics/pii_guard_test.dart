// test/analytics/pii_guard_test.dart
// Phase 6 — Analytics (extended Phase 7)
// Spec: analytics-agent-spec.md § Privacy Rules
//
// Verifies that AnalyticsService NEVER leaks PII in any event properties.
// Source-level contract tests — catch regressions before they reach production.
//
// Privacy rules enforced:
//   1. word_submitted must send word_length only — never the word string.
//   2. No parameter named "word" or similar in trackWordSubmitted.
//   3. No event method accepts an email address parameter.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String source;

  setUpAll(() {
    final file = File('lib/data/services/analytics_service.dart');
    expect(file.existsSync(), isTrue, reason: 'analytics_service.dart must exist');
    source = file.readAsStringSync();
  });

  group('AnalyticsService PII guard — source contract', () {
    // ── word_submitted property map ──────────────────────────────────────────

    test('word_submitted event includes word_length in its properties', () {
      // The _track call for 'word_submitted' must pass 'word_length'.
      // We check the entire source — this key must appear near word_submitted.
      final idx = source.indexOf("'word_submitted'");
      expect(idx, isNot(-1), reason: "'word_submitted' event must exist");

      // Look for 'word_length' within a reasonable window after the event name.
      final window = source.substring(idx, idx + 600);
      expect(
        window,
        contains("'word_length'"),
        reason: "word_submitted event properties must include 'word_length'",
      );
    });

    test('word_submitted event does NOT include a raw word property', () {
      final idx = source.indexOf("'word_submitted'");
      expect(idx, isNot(-1));
      final window = source.substring(idx, idx + 600);

      const forbiddenKeys = [
        "'word':",
        '"word":',
        "'word_string':",
        "'word_value':",
        "'submitted_word':",
        "'raw_word':",
      ];
      for (final key in forbiddenKeys) {
        expect(
          window,
          isNot(contains(key)),
          reason: "word_submitted must not send '$key' — "
              "only word_length is permitted (PII rule)",
        );
      }
    });

    // ── trackWordSubmitted method signature ──────────────────────────────────

    test('trackWordSubmitted signature contains wordLength parameter', () {
      // Find the method declaration and verify wordLength is in the params.
      final idx = source.indexOf('trackWordSubmitted(');
      expect(idx, isNot(-1), reason: 'trackWordSubmitted must exist');
      // Named parameter list runs from ( to the closing ) — grab a large window.
      final window = source.substring(idx, idx + 800);
      expect(
        window,
        contains('wordLength'),
        reason: 'trackWordSubmitted must accept a wordLength parameter',
      );
    });

    test('trackWordSubmitted signature does NOT contain a raw word parameter', () {
      final idx = source.indexOf('trackWordSubmitted(');
      expect(idx, isNot(-1));
      final window = source.substring(idx, idx + 800);

      const forbiddenParams = [
        'String word,',
        'String word)',
        'String wordString',
        'String wordValue',
        'String submittedWord',
      ];
      for (final param in forbiddenParams) {
        expect(
          window,
          isNot(contains(param)),
          reason: 'trackWordSubmitted must not accept "$param" — '
              'only wordLength is permitted',
        );
      }
    });

    // ── No public method accepts an email parameter ──────────────────────────

    test('no public analytics method accepts an email parameter', () {
      const emailPatterns = [
        'String email,',
        'String email)',
        'String emailAddress',
        'String userEmail',
      ];
      for (final pattern in emailPatterns) {
        expect(
          source,
          isNot(contains(pattern)),
          reason: 'AnalyticsService must not accept "$pattern" — '
              'email is PII and must never be sent to analytics',
        );
      }
    });

    // ── iap_purchase event ───────────────────────────────────────────────────

    test('iap_purchase event does not include email in properties', () {
      final idx = source.indexOf("'iap_purchase'");
      if (idx == -1) return; // method not yet implemented — skip
      final window = source.substring(idx, idx + 400);
      expect(window, isNot(contains("'email'")));
      expect(window, isNot(contains('"email"')));
    });
  });
}
