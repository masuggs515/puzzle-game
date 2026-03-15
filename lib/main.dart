// lib/main.dart
// Application entry point.
// Initializes Supabase → Mixpanel → AdMob → RevenueCat → Sentry → Riverpod.
// Anonymous session creation is handled by SplashScreen (Phase 2).
// Phase 7: AdMob and RevenueCat initialization added.

import 'dart:io' show Platform;

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:mixpanel_flutter/mixpanel_flutter.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config/env.dart';
import 'data/services/revenue_cat_service.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/shop/providers/shop_provider.dart';

// Top-level nullable — set before runApp so ProviderScope overrides are safe.
Mixpanel? _mixpanel;
RevenueCatService? _revenueCatService;

Future<void> main() async {
  // Initialize Sentry — no-op when DSN is empty, safe for development.
  // When active, SentryFlutter.init wraps execution in runZonedGuarded and
  // handles WidgetsFlutterBinding internally. Calling ensureInitialized()
  // before it binds Flutter to the outer zone and causes a zone mismatch crash.
  if (Env.sentryDsn.isNotEmpty) {
    await SentryFlutter.init(
      (options) {
        options.dsn = Env.sentryDsn;
        options.tracesSampleRate = 0.2;
      },
      appRunner: () async {
        await _initSupabase();
        await _initMixpanel();
        await _initAdMob();
        await _initRevenueCat();
        runApp(ProviderScope(
          overrides: [
            mixpanelProvider.overrideWith((ref) => _mixpanel),
            revenueCatServiceProvider.overrideWith(
              (ref) => _revenueCatService ?? RevenueCatService(),
            ),
          ],
          child: const App(),
        ));
      },
    );
  } else {
    WidgetsFlutterBinding.ensureInitialized();
    await _initSupabase();
    await _initMixpanel();
    await _initAdMob();
    await _initRevenueCat();
    runApp(ProviderScope(
      overrides: [
        mixpanelProvider.overrideWith((ref) => _mixpanel),
        revenueCatServiceProvider.overrideWith(
          (ref) => _revenueCatService ?? RevenueCatService(),
        ),
      ],
      child: const App(),
    ));
  }
}

// Initialize Mixpanel — no-op when token is empty (safe for CI / bare flutter run).
Future<void> _initMixpanel() async {
  if (Env.mixpanelToken.isEmpty) {
    debugPrint('[main] Mixpanel NOT initialized — MIXPANEL_TOKEN is empty');
    return;
  }
  _mixpanel = await Mixpanel.init(
    Env.mixpanelToken,
    optOutTrackingDefault: false,
    trackAutomaticEvents: false, // manual control only; disables auto geolocation
  );
  debugPrint('[main] Mixpanel.init() complete');
}

// Initialize Supabase — required for Phase 2+ auth and data.
// Run via scripts/run_dev.sh which loads .env.task credentials.
Future<void> _initSupabase() async {
  debugPrint('[main] SUPABASE_URL="${Env.supabaseUrl}" (empty=${Env.supabaseUrl.isEmpty})');
  debugPrint('[main] SUPABASE_ANON_KEY length=${Env.supabaseAnonKey.length}');
  if (Env.supabaseUrl.isNotEmpty && Env.supabaseAnonKey.isNotEmpty) {
    await Supabase.initialize(
      url: Env.supabaseUrl,
      anonKey: Env.supabaseAnonKey,
    );
    debugPrint('[main] Supabase.initialize() complete');
  } else {
    debugPrint('[main] WARNING: Supabase NOT initialized — credentials missing. '
        'Run via scripts/run_dev_cloud.sh, not flutter run directly.');
  }
}

// Phase 7: Initialize AdMob.
// Requests ATT permission on iOS before initializing so AdMob can serve
// personalized ads. If initialization fails, we log and continue — the game
// must never crash on ad init failure.
Future<void> _initAdMob() async {
  try {
    // Request App Tracking Transparency permission on iOS 14+.
    // Must happen before MobileAds.instance.initialize().
    if (Platform.isIOS) {
      await AppTrackingTransparency.requestTrackingAuthorization();
    }
    await MobileAds.instance.initialize();
    debugPrint('[main] AdMob initialized');
  } catch (e) {
    // Silent — never crash the app if ads fail to initialize.
    debugPrint('[main] AdMob initialization error (non-fatal): $e');
  }
}

// Phase 7: Initialize RevenueCat.
// Uses anonymous ID on first launch — user ID is linked after auth via
// RevenueCatService.initialize(appUserId: ...) when the profile loads.
Future<void> _initRevenueCat() async {
  _revenueCatService = RevenueCatService();
  await _revenueCatService!.initialize();
}
