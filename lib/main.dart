// lib/main.dart
// Application entry point.
// Initializes Supabase → Sentry → Riverpod.
// Anonymous session creation is handled by SplashScreen (Phase 2).
// Mixpanel, RevenueCat, OneSignal deferred to Phase 6/9 when credentials available.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config/env.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase — required for Phase 2+ auth and data
  // Run via scripts/run_dev.sh which loads .env.task credentials
  if (Env.supabaseUrl.isNotEmpty && Env.supabaseAnonKey.isNotEmpty) {
    await Supabase.initialize(
      url: Env.supabaseUrl,
      anonKey: Env.supabaseAnonKey,
    );
  }

  // Initialize Sentry — no-op when DSN is empty, safe for development
  if (Env.sentryDsn.isNotEmpty) {
    await SentryFlutter.init(
      (options) {
        options.dsn = Env.sentryDsn;
        options.tracesSampleRate = 0.2;
      },
      appRunner: () => runApp(const ProviderScope(child: App())),
    );
  } else {
    runApp(const ProviderScope(child: App()));
  }
}
