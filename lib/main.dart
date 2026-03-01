// lib/main.dart
// Application entry point.
// Initializes Sentry → Supabase → Riverpod.
// Mixpanel, RevenueCat, OneSignal deferred to Phase 6/9 when credentials available.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config/env.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  // TODO MAS: SUPABASE_URL and SUPABASE_ANON_KEY must be provided via --dart-define
  // when running locally. Use scripts/run_dev.sh. Without these the app will show
  // "not connected" on the hello-world screen — expected until Phase 2 credentials exist.
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
