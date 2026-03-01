// lib/features/home/screens/home_screen.dart
// Phase 1 hello-world screen.
// Shows app name, Supabase connection status, and auth status.
// Will be replaced with full home/world-map screen in Phase 4+.

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/env.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String get _supabaseStatus {
    if (Env.supabaseUrl.isEmpty) return 'not configured';
    try {
      // If Supabase.instance.client exists and is initialized, connection is up
      Supabase.instance.client;
      return 'connected';
    } catch (_) {
      return 'not connected';
    }
  }

  String get _authStatus {
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) return 'not authenticated';
      final user = Supabase.instance.client.auth.currentUser;
      final isAnon = user?.isAnonymous ?? false;
      return isAnon ? 'guest (anonymous)' : 'signed in';
    } catch (_) {
      return 'not authenticated';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Puzzle Game')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Hello World',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              _StatusRow(
                label: 'Supabase',
                value: _supabaseStatus,
                isOk: _supabaseStatus == 'connected',
              ),
              const SizedBox(height: 12),
              _StatusRow(
                label: 'Auth',
                value: _authStatus,
                isOk: _authStatus != 'not authenticated',
              ),
              const SizedBox(height: 32),
              const Text(
                'Phase 1 — Project Setup skeleton.\nFull game coming in Phase 4.',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isOk;

  const _StatusRow({
    required this.label,
    required this.value,
    required this.isOk,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          isOk ? Icons.check_circle : Icons.cancel,
          color: isOk ? Colors.green : Colors.red,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        Text(value),
      ],
    );
  }
}
