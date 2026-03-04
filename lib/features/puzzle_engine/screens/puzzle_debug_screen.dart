// lib/features/puzzle_engine/screens/puzzle_debug_screen.dart
// Phase 3 — Puzzle Engine
// Spec: flutter-agent-spec.md
//
// Dev-only debug screen — lists all hand-crafted puzzles and lets
// developers inspect their structure. Never shown in release builds.
// Solution fields are hidden to keep spoilers out of logs and screenshots.

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/puzzle_asset_service.dart';

class PuzzleDebugScreen extends StatefulWidget {
  const PuzzleDebugScreen({super.key});

  @override
  State<PuzzleDebugScreen> createState() => _PuzzleDebugScreenState();
}

class _PuzzleDebugScreenState extends State<PuzzleDebugScreen> {
  late Future<List<Map<String, dynamic>>> _puzzlesFuture;

  @override
  void initState() {
    super.initState();
    _puzzlesFuture = PuzzleAssetService.instance.loadHandCraftedPuzzles();
  }

  @override
  Widget build(BuildContext context) {
    // Guard: should never be reachable in release builds because the home
    // screen button is behind kDebugMode, but add a belt-and-braces check.
    if (!kDebugMode) {
      return const Scaffold(
        body: Center(child: Text('Not available in release builds.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Puzzle Debug'),
        backgroundColor: Colors.deepPurple.shade700,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _puzzlesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Failed to load puzzles:\n${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final puzzles = snapshot.data!;
          return ListView.builder(
            itemCount: puzzles.length,
            itemBuilder: (context, index) {
              final puzzle = puzzles[index];
              return _PuzzleListTile(
                puzzle: puzzle,
                onTap: () => _showDetail(context, puzzle),
              );
            },
          );
        },
      ),
    );
  }

  void _showDetail(BuildContext context, Map<String, dynamic> puzzle) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _PuzzleDetailScreen(puzzle: puzzle),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// List tile — shows the key fields at a glance
// ---------------------------------------------------------------------------

class _PuzzleListTile extends StatelessWidget {
  final Map<String, dynamic> puzzle;
  final VoidCallback onTap;

  const _PuzzleListTile({required this.puzzle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final levelNumber = puzzle['level_number'] as int? ?? 0;
    final levelType = puzzle['level_type'] as String? ?? '';
    final isBoss = puzzle['is_boss'] as bool? ?? false;
    final intersectionCount = puzzle['intersection_count'] as int? ?? 0;
    final wordCount = puzzle['word_count'] as int? ?? 0;
    final tiers = (puzzle['constraint_tiers'] as List?)
            ?.map((t) => 'T$t')
            .join(', ') ??
        '';

    return ListTile(
      leading: CircleAvatar(
        backgroundColor:
            isBoss ? Colors.deepPurple.shade700 : Colors.blueGrey.shade700,
        foregroundColor: Colors.white,
        child: Text('$levelNumber', style: const TextStyle(fontSize: 12)),
      ),
      title: Row(
        children: [
          Text(
            _capitalise(levelType),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          if (isBoss) ...[
            const SizedBox(width: 6),
            const Icon(Icons.bolt, size: 16, color: Colors.amber),
          ],
        ],
      ),
      subtitle: Text(
        '$wordCount words · $intersectionCount intersections · $tiers',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  String _capitalise(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

// ---------------------------------------------------------------------------
// Detail screen — shows full puzzle JSON with solution field removed
// ---------------------------------------------------------------------------

class _PuzzleDetailScreen extends StatelessWidget {
  final Map<String, dynamic> puzzle;

  const _PuzzleDetailScreen({required this.puzzle});

  /// Returns a deep copy of the puzzle map with metadata.solution removed.
  Map<String, dynamic> _sanitised() {
    final copy = Map<String, dynamic>.from(puzzle);
    if (copy['metadata'] is Map) {
      final meta = Map<String, dynamic>.from(
        copy['metadata'] as Map<String, dynamic>,
      );
      meta.remove('solution');
      copy['metadata'] = meta;
    }
    return copy;
  }

  @override
  Widget build(BuildContext context) {
    final levelNumber = puzzle['level_number'] as int? ?? 0;
    final prettyJson = const JsonEncoder.withIndent('  ').convert(_sanitised());

    return Scaffold(
      appBar: AppBar(
        title: Text('Level $levelNumber'),
        backgroundColor: Colors.deepPurple.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SelectableText(
          prettyJson,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
