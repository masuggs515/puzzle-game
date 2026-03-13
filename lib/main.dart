// lib/main.dart
// Application entry point.
// Initializes Supabase → Mixpanel → Sentry → Riverpod.
// Anonymous session creation is handled by SplashScreen (Phase 2).
// RevenueCat, OneSignal deferred to Phase 9 when credentials available.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mixpanel_flutter/mixpanel_flutter.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config/env.dart';
import 'features/auth/providers/auth_provider.dart';

// Top-level nullable — set before runApp so ProviderScope override is safe.
Mixpanel? _mixpanel;

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
        runApp(ProviderScope(
          overrides: [
            mixpanelProvider.overrideWith((ref) => _mixpanel),
          ],
          child: const App(),
        ));
      },
    );
  } else {
    WidgetsFlutterBinding.ensureInitialized();
    await _initSupabase();
    await _initMixpanel();
    runApp(ProviderScope(
      overrides: [
        mixpanelProvider.overrideWith((ref) => _mixpanel),
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
