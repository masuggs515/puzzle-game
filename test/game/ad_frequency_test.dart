// test/game/ad_frequency_test.dart
// Phase 7 — Ads & Monetization
// Spec: master-development-plan.md § Ad Strategy
//
// Tests for AdFrequencyManager — pure Dart, no platform dependencies.
// Target: all decision-path branches covered.

import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_game/data/services/ad_service.dart';

void main() {
  group('AdFrequencyManager', () {
    late AdFrequencyManager manager;

    setUp(() {
      manager = AdFrequencyManager();
      // Reset to a known threshold for deterministic tests.
      manager.reset();
    });

    // ── Paying user suppression ──────────────────────────────────────────────

    test('never shows ad to a paying user regardless of level count', () {
      // Force the counter above the max threshold by iterating many levels.
      for (var i = 0; i < 20; i++) {
        final result = manager.shouldShowAd(
          isBossLevel: false,
          isPayingUser: true,
        );
        expect(result, isFalse, reason: 'paying user must never see an ad');
      }
    });

    test('paying user — counter still increments', () {
      // Counter should advance even when the ad is suppressed for paying users.
      manager.shouldShowAd(isBossLevel: false, isPayingUser: true);
      expect(manager.levelsSinceLastAd, greaterThan(0));
    });

    // ── Boss level suppression ───────────────────────────────────────────────

    test('never shows ad on a boss level completion', () {
      for (var i = 0; i < 20; i++) {
        final result = manager.shouldShowAd(
          isBossLevel: true,
          isPayingUser: false,
        );
        expect(result, isFalse, reason: 'boss level must never trigger an ad');
      }
    });

    test('boss level — counter still increments', () {
      manager.shouldShowAd(isBossLevel: true, isPayingUser: false);
      expect(manager.levelsSinceLastAd, greaterThan(0));
    });

    // ── Threshold logic ──────────────────────────────────────────────────────

    test('shows ad at or after minimum threshold (4 standard levels)', () {
      // Repeatedly complete levels until an ad is triggered.
      // It must trigger within maxLevelsBetweenAds (5) levels.
      bool triggered = false;
      for (var i = 0; i < AdFrequencyManager.maxLevelsBetweenAds + 1; i++) {
        if (manager.shouldShowAd(isBossLevel: false, isPayingUser: false)) {
          triggered = true;
          break;
        }
      }
      expect(triggered, isTrue, reason: 'ad must trigger within max threshold');
    });

    test('counter resets to 0 after an ad is shown', () {
      // Run until ad fires.
      bool triggered = false;
      for (var i = 0; i < 20; i++) {
        triggered = manager.shouldShowAd(
          isBossLevel: false,
          isPayingUser: false,
        );
        if (triggered) break;
      }
      expect(triggered, isTrue);
      expect(manager.levelsSinceLastAd, equals(0));
    });

    test('two successive ad triggers — correct cadence each time', () {
      // First trigger
      bool first = false;
      for (var i = 0; i < 20 && !first; i++) {
        first = manager.shouldShowAd(isBossLevel: false, isPayingUser: false);
      }
      expect(first, isTrue, reason: 'first ad must trigger');
      expect(manager.levelsSinceLastAd, equals(0));

      // Second trigger
      bool second = false;
      for (var i = 0; i < 20 && !second; i++) {
        second = manager.shouldShowAd(isBossLevel: false, isPayingUser: false);
      }
      expect(second, isTrue, reason: 'second ad must trigger');
    });

    // ── reset() ─────────────────────────────────────────────────────────────

    test('reset() clears the counter', () {
      manager.shouldShowAd(isBossLevel: false, isPayingUser: false);
      expect(manager.levelsSinceLastAd, greaterThan(0));
      manager.reset();
      expect(manager.levelsSinceLastAd, equals(0));
    });

    // ── Threshold bounds ─────────────────────────────────────────────────────

    test('ad never fires before minimum threshold (4 levels)', () {
      // Complete fewer levels than the minimum and confirm no ad shows.
      // We run for exactly minLevelsBetweenAds - 1 levels. The threshold is
      // at least minLevelsBetweenAds, so no ad can have fired yet.
      bool triggered = false;
      for (var i = 0; i < AdFrequencyManager.minLevelsBetweenAds - 1; i++) {
        triggered = manager.shouldShowAd(
          isBossLevel: false,
          isPayingUser: false,
        );
        expect(triggered, isFalse,
            reason: 'ad must not fire before min threshold of '
                '${AdFrequencyManager.minLevelsBetweenAds} levels');
      }
    });
  });
}
